import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enstudy/core/theme/colors.dart';
import 'package:enstudy/features/cards/domain/entities/card.dart' as domain;
import 'package:enstudy/features/games/presentation/providers/game_provider.dart';

class WhackGame extends ConsumerStatefulWidget {
  final List<domain.Card> cards;

  const WhackGame({super.key, required this.cards});

  @override
  ConsumerState<WhackGame> createState() => _WhackGameState();
}

class _WhackGameState extends ConsumerState<WhackGame>
    with TickerProviderStateMixin {
  late List<domain.Card> _cards;
  int _currentIndex = 0;
  int _score = 0;
  int _streak = 0;
  int _timeLeft = 60;
  Timer? _gameTimer;
  Timer? _spawnTimer;
  bool _isFinished = false;
  int _correctCount = 0;
  int _wrongCount = 0;

  static const int _gridSize = 9;
  late List<_MoleState> _moles;
  int _maxActiveMoles = 2;
  double _moleStayDuration = 2.5;

  late AnimationController _hitController;
  late AnimationController _shakeController;
  int? _shakingIndex;
  int? _hitIndex;
  bool _hitCorrect = false;

  final List<Timer> _moleTimers = [];

  @override
  void initState() {
    super.initState();
    _cards = widget.cards;
    _moles = List.generate(_gridSize, (_) => _MoleState());

    _hitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startGame();
    });
  }

  void _startGame() {
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _isFinished) return;
      setState(() {
        _timeLeft--;
      });
      if (_timeLeft <= 0) {
        _finishGame();
      }
    });

    _scheduleSpawn();
  }

  void _scheduleSpawn() {
    if (_isFinished || !mounted) return;
    final delay = 800 + Random().nextInt(600);
    _spawnTimer = Timer(Duration(milliseconds: delay), () {
      if (!mounted || _isFinished) return;
      _spawnMole();
      _scheduleSpawn();
    });
  }

  void _spawnMole() {
    if (_isFinished || !mounted) return;
    if (_currentIndex >= _cards.length) {
      _finishGame();
      return;
    }

    final activeCount = _moles.where((m) => m.isActive).length;
    if (activeCount >= _maxActiveMoles) return;

    final emptyIndices = <int>[];
    for (int i = 0; i < _gridSize; i++) {
      if (!_moles[i].isActive) emptyIndices.add(i);
    }
    if (emptyIndices.isEmpty) return;

    final random = Random();
    final index = emptyIndices[random.nextInt(emptyIndices.length)];

    final isCorrectMole = random.nextDouble() < 0.4;
    domain.Card moleCard;
    bool isCorrect;

    if (isCorrectMole && _currentIndex < _cards.length) {
      moleCard = _cards[_currentIndex];
      isCorrect = true;
    } else {
      final others =
          widget.cards.where((c) => c.id != _cards[_currentIndex].id).toList();
      others.shuffle(random);
      moleCard = others.isNotEmpty ? others.first : _cards[_currentIndex];
      isCorrect = false;
    }

    setState(() {
      _moles[index] = _MoleState(
        isActive: true,
        card: moleCard,
        isCorrect: isCorrect,
        showTime: DateTime.now(),
      );
    });

    final stayMs = (_moleStayDuration * 1000).round();
    _addMoleTimer(index, moleCard.id, stayMs);
  }

  void _addMoleTimer(int index, String cardId, int stayMs) {
    final timer = Timer(Duration(milliseconds: stayMs), () {
      if (!mounted || _isFinished) return;
      if (_moles[index].isActive && _moles[index].card?.id == cardId) {
        setState(() {
          _moles[index] = _MoleState();
        });
      }
    });
    _moleTimers.add(timer);
  }

  void _onMoleTap(int index) {
    if (_isFinished || !_moles[index].isActive) return;

    final mole = _moles[index];

    if (mole.isCorrect) {
      setState(() {
        _score += 10 + (_streak >= 3 ? 5 : 0);
        _streak++;
        _correctCount++;
        _hitIndex = index;
        _hitCorrect = true;
        _moles[index] = _MoleState();
      });
      _hitController.forward(from: 0).then((_) {
        if (mounted) {
          setState(() {
            _hitIndex = null;
            _hitCorrect = false;
          });
        }
      });
      _currentIndex++;

      _moleStayDuration = (2.5 - _currentIndex * 0.08).clamp(0.8, 2.5);
      if (_currentIndex % 5 == 0 && _maxActiveMoles < 3) {
        _maxActiveMoles++;
      }

      if (_currentIndex >= _cards.length) {
        _finishGame();
      }
    } else {
      setState(() {
        _streak = 0;
        _wrongCount++;
        _shakingIndex = index;
      });
      _shakeController.forward(from: 0).then((_) {
        if (mounted && !_isFinished) {
          setState(() {
            _shakingIndex = null;
            _moles[index] = _MoleState();
          });
        }
      });
    }
  }

  void _finishGame() {
    if (_isFinished) return;
    _isFinished = true;
    _gameTimer?.cancel();
    _spawnTimer?.cancel();
    for (final t in _moleTimers) {
      t.cancel();
    }
    _moleTimers.clear();

    for (int i = 0; i < _gridSize; i++) {
      _moles[i] = _MoleState();
    }

    try {
      final gameNotifier = ref.read(gameProvider.notifier);
      for (int i = 0; i < _correctCount; i++) {
        gameNotifier.answerCorrect();
      }
      for (int i = 0; i < _wrongCount; i++) {
        gameNotifier.answerWrong();
      }
      if (!gameNotifier.state.isCompleted) {
        gameNotifier.completeGame();
      }
    } catch (e) {
      debugPrint('WhackGame: error saving game result: $e');
    }

    setState(() {});
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _spawnTimer?.cancel();
    for (final t in _moleTimers) {
      t.cancel();
    }
    _moleTimers.clear();
    _hitController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTopBar(),
        Expanded(
          child: _isFinished ? _buildFinishedView() : _buildGameArea(),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.timer_outlined,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 4),
              Text(
                '${_timeLeft}s',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _timeLeft <= 10 ? AppColors.error : AppColors.primary,
                ),
              ),
            ],
          ),
          if (_currentIndex < _cards.length)
            Flexible(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '找出: ${_cards[_currentIndex].content}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.star_rounded,
                color: AppColors.accent,
                size: 20,
              ),
              const SizedBox(width: 4),
              Text(
                '$_score',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                ),
              ),
              if (_streak >= 3) ...[
                const SizedBox(width: 8),
                Text(
                  '🔥x$_streak',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGameArea() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: _gridSize,
        itemBuilder: (context, index) {
          return _buildMoleHole(index);
        },
      ),
    );
  }

  Widget _buildMoleHole(int index) {
    final mole = _moles[index];
    final isShaking = _shakingIndex == index;
    final isHit = _hitIndex == index && _hitCorrect;

    return GestureDetector(
      onTap: () => _onMoleTap(index),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.background,
        ),
        child: Stack(
          fit: StackFit.expand,
          alignment: Alignment.center,
          children: [
            _buildHoleBase(),
            if (mole.isActive && !isShaking) _buildMoleContent(mole),
            if (mole.isActive && isShaking) _buildShakingMole(mole),
            if (isHit) _buildHitEffect(),
          ],
        ),
      ),
    );
  }

  Widget _buildHoleBase() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.brown.shade300,
          boxShadow: [
            BoxShadow(
              color: Colors.brown.shade600.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoleContent(_MoleState mole) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: mole.isCorrect
            ? AppColors.secondaryLight
            : AppColors.warning.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (mole.isCorrect ? AppColors.secondary : AppColors.warning)
                .withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            mole.isCorrect ? Icons.pets : Icons.cruelty_free,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            mole.card?.translation ?? '',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildShakingMole(_MoleState mole) {
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final offset = sin(_shakeController.value * 4 * pi) * 6;
        return Transform.translate(
          offset: Offset(offset, 0),
          child: child,
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.error.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.close,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              mole.card?.translation ?? '',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHitEffect() {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.5, end: 1.5).animate(
        CurvedAnimation(
          parent: _hitController,
          curve: Curves.elasticOut,
        ),
      ),
      child: FadeTransition(
        opacity: Tween<double>(begin: 1.0, end: 0.0).animate(
          CurvedAnimation(
            parent: _hitController,
            curve: Curves.easeOut,
          ),
        ),
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.success.withValues(alpha: 0.4),
          ),
          child: const Icon(
            Icons.check_circle,
            color: AppColors.success,
            size: 32,
          ),
        ),
      ),
    );
  }

  Widget _buildFinishedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events, size: 64, color: AppColors.accent),
          const SizedBox(height: 16),
          const Text(
            '时间到！',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '得分: $_score',
            style: const TextStyle(
              fontSize: 22,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '正确: $_correctCount  错误: $_wrongCount',
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoleState {
  final bool isActive;
  final domain.Card? card;
  final bool isCorrect;
  final DateTime? showTime;

  _MoleState({
    this.isActive = false,
    this.card,
    this.isCorrect = false,
    this.showTime,
  });
}
