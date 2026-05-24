import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enstudy/core/theme/colors.dart';
import 'package:enstudy/features/cards/domain/entities/card.dart' as domain;
import 'package:enstudy/features/games/presentation/providers/game_provider.dart';

class ShootingGame extends ConsumerStatefulWidget {
  final List<domain.Card> cards;

  const ShootingGame({super.key, required this.cards});

  @override
  ConsumerState<ShootingGame> createState() => _ShootingGameState();
}

class _ShootingGameState extends ConsumerState<ShootingGame>
    with TickerProviderStateMixin {
  late List<domain.Card> _cards;
  int _currentIndex = 0;
  int _lives = 3;
  int _score = 0;
  int _streak = 0;
  bool _isFinished = false;

  late List<_FlyingWord> _flyingWords;
  late List<_Target> _targets;
  int? _hitTargetIndex;
  bool _showHitEffect = false;
  Offset? _hitPosition;

  late AnimationController _moveController;
  late AnimationController _hitEffectController;
  late AnimationController _shakeController;
  late AnimationController _highlightController;

  double _speedMultiplier = 1.0;
  Timer? _spawnTimer;

  @override
  void initState() {
    super.initState();
    _cards = widget.cards;
    _flyingWords = [];
    _targets = [];

    _moveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_onMoveTick);

    _hitEffectController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _highlightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _moveController.repeat();
    _highlightController.repeat(reverse: true);
    _spawnCurrentWord();
  }

  void _onMoveTick() {
    if (_isFinished || !mounted) return;

    setState(() {
      for (final word in _flyingWords) {
        word.x += _speedMultiplier * 0.003;
      }

      final escaped = _flyingWords.where((w) => w.x > 1.0).toList();
      for (final word in escaped) {
        if (word.isCurrent) {
          _loseLife();
        }
        _flyingWords.remove(word);
      }
    });
  }

  void _spawnCurrentWord() {
    if (_currentIndex >= _cards.length) {
      _finishGame();
      return;
    }

    final card = _cards[_currentIndex];
    final random = Random();

    _flyingWords = _flyingWords.where((w) => !w.isCurrent).toList();

    _flyingWords.add(
      _FlyingWord(
        card: card,
        x: -0.15,
        y: 0.1 + random.nextDouble() * 0.25,
        isCurrent: true,
      ),
    );

    _generateTargets(card);
  }

  void _generateTargets(domain.Card correctCard) {
    final others = widget.cards.where((c) => c.id != correctCard.id).toList();
    others.shuffle(Random());
    final distractors = others.take(2).toList();
    final allTargets = [correctCard, ...distractors]..shuffle(Random());

    _targets = allTargets
        .map(
          (c) => _Target(
            card: c,
            isCorrect: c.id == correctCard.id,
            isWrong: false,
          ),
        )
        .toList();
  }

  void _onTargetTap(int index) {
    if (_isFinished) return;

    final target = _targets[index];
    final currentWord = _flyingWords.firstWhere((w) => w.isCurrent,
        orElse: () => _flyingWords.first);

    if (target.isCorrect) {
      setState(() {
        _score += 10 + (_streak >= 3 ? 5 : 0);
        _streak++;
        _showHitEffect = true;
        _hitTargetIndex = index;
      });
      _hitEffectController.forward(from: 0).then((_) {
        if (mounted) {
          setState(() {
            _showHitEffect = false;
            _hitTargetIndex = null;
          });
        }
      });
      ref.read(gameProvider.notifier).answerCorrect();

      _flyingWords.removeWhere((w) => w.isCurrent);
      _currentIndex++;

      _speedMultiplier = 1.0 + (_currentIndex * 0.12);

      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _spawnCurrentWord();
      });
    } else {
      setState(() {
        _streak = 0;
        _targets[index].isWrong = true;
      });
      _shakeController.forward(from: 0).then((_) {
        if (mounted) {
          setState(() {
            _targets[index].isWrong = false;
          });
        }
      });
      ref.read(gameProvider.notifier).answerWrong();
    }
  }

  void _loseLife() {
    setState(() {
      _lives--;
    });
    if (_lives <= 0) {
      _finishGame();
    } else {
      _currentIndex++;
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _spawnCurrentWord();
      });
    }
  }

  void _finishGame() {
    if (_isFinished) return;
    _isFinished = true;
    _moveController.stop();
    ref.read(gameProvider.notifier).completeGame();
  }

  @override
  void dispose() {
    _moveController.dispose();
    _hitEffectController.dispose();
    _shakeController.dispose();
    _highlightController.dispose();
    _spawnTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: Stack(
                children: [
                  _buildFlyingArea(),
                  if (_isFinished) _buildFinishedOverlay(),
                ],
              ),
            ),
            _buildTargetArea(),
          ],
        ),
        if (_showHitEffect) _buildHitEffect(),
      ],
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: List.generate(
              3,
              (i) => Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  Icons.favorite,
                  color: i < _lives ? AppColors.error : AppColors.divider,
                  size: 24,
                ),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.star_rounded,
                color: AppColors.accent,
                size: 22,
              ),
              const SizedBox(width: 4),
              Text(
                '$_score',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          if (_streak >= 3)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '🔥x$_streak',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.error,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFlyingArea() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: _flyingWords.map((word) {
            final left = word.x * constraints.maxWidth;
            final top = word.y * constraints.maxHeight;

            return Positioned(
              left: left,
              top: top,
              child: word.isCurrent
                  ? AnimatedBuilder(
                      animation: _highlightController,
                      builder: (context, child) {
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.accent,
                              width: 2 + _highlightController.value * 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accent.withValues(
                                    alpha:
                                        0.3 + _highlightController.value * 0.3),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: child,
                        );
                      },
                      child: _buildWordChip(word.card.content),
                    )
                  : _buildWordChip(word.card.content),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildWordChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, color: Colors.white70, size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              '选择正确释义',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(_targets.length, (i) {
              return _buildTargetButton(i);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetButton(int index) {
    final target = _targets[index];
    final isHit = _hitTargetIndex == index && _showHitEffect;
    final isWrong = target.isWrong;

    Widget button = GestureDetector(
      onTap: () => _onTargetTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isHit
              ? AppColors.success
              : isWrong
                  ? AppColors.error
                  : AppColors.primary,
          boxShadow: [
            BoxShadow(
              color: (isHit
                      ? AppColors.success
                      : isWrong
                          ? AppColors.error
                          : AppColors.primary)
                  .withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              target.card.translation,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );

    if (isHit) {
      button = ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: 1.3).animate(
          CurvedAnimation(
            parent: _hitEffectController,
            curve: Curves.elasticOut,
          ),
        ),
        child: FadeTransition(
          opacity: Tween<double>(begin: 1.0, end: 0.0).animate(
            CurvedAnimation(
              parent: _hitEffectController,
              curve: Curves.easeOut,
            ),
          ),
          child: button,
        ),
      );
    }

    if (isWrong) {
      button = AnimatedBuilder(
        animation: _shakeController,
        builder: (context, child) {
          final offset = sin(_shakeController.value * 4 * pi) * 6;
          return Transform.translate(
            offset: Offset(offset, 0),
            child: child,
          );
        },
        child: button,
      );
    }

    return button;
  }

  Widget _buildHitEffect() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.5, end: 2.5).animate(
              CurvedAnimation(
                parent: _hitEffectController,
                curve: Curves.easeOut,
              ),
            ),
            child: FadeTransition(
              opacity: Tween<double>(begin: 1.0, end: 0.0).animate(
                CurvedAnimation(
                  parent: _hitEffectController,
                  curve: Curves.easeOut,
                ),
              ),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.success.withValues(alpha: 0.3),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 48,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFinishedOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.military_tech,
              size: 64,
              color: AppColors.accent,
            ),
            const SizedBox(height: 16),
            Text(
              _lives <= 0 ? '生命耗尽！' : '射击完成！',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '得分: $_score',
              style: const TextStyle(
                fontSize: 22,
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlyingWord {
  final domain.Card card;
  double x;
  final double y;
  final bool isCurrent;

  _FlyingWord({
    required this.card,
    required this.x,
    required this.y,
    this.isCurrent = false,
  });
}

class _Target {
  final domain.Card card;
  final bool isCorrect;
  bool isWrong;

  _Target({
    required this.card,
    required this.isCorrect,
    this.isWrong = false,
  });
}
