import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enstudy/core/theme/colors.dart';
import 'package:enstudy/features/cards/domain/entities/card.dart' as domain;
import 'package:enstudy/features/games/presentation/providers/game_provider.dart';

class SpeedGame extends ConsumerStatefulWidget {
  final List<domain.Card> cards;

  const SpeedGame({super.key, required this.cards});

  @override
  ConsumerState<SpeedGame> createState() => _SpeedGameState();
}

class _SpeedGameState extends ConsumerState<SpeedGame>
    with TickerProviderStateMixin {
  late List<_SpeedQuestion> _questions;
  int _currentIndex = 0;
  int _score = 0;
  int _streak = 0;
  int _timeLeft = 60;
  Timer? _timer;
  bool _isFinished = false;
  Color? _flashColor;
  late AnimationController _flashController;
  late AnimationController _shakeController;
  bool _isShaking = false;

  @override
  void initState() {
    super.initState();
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _generateQuestions();
    _startTimer();
  }

  void _generateQuestions() {
    _questions = [];
    final random = Random();
    for (final card in widget.cards) {
      final showCorrect = random.nextBool();
      String displayedMeaning;
      if (showCorrect) {
        displayedMeaning = card.translation;
      } else {
        final others =
            widget.cards.where((c) => c.id != card.id).toList();
        others.shuffle(random);
        displayedMeaning =
            others.isNotEmpty ? others.first.translation : card.translation;
      }
      _questions.add(_SpeedQuestion(
        card: card,
        displayedMeaning: displayedMeaning,
        isCorrectMeaning: showCorrect,
      ));
    }
    _questions.shuffle(random);
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _timeLeft--;
      });
      if (_timeLeft <= 0) {
        _finishGame();
      }
    });
  }

  void _finishGame() {
    if (_isFinished) return;
    _isFinished = true;
    _timer?.cancel();
    ref.read(gameProvider.notifier).completeGame();
  }

  void _onAnswer(bool userSaysCorrect) {
    if (_isFinished || _currentIndex >= _questions.length) return;

    final question = _questions[_currentIndex];
    final isActuallyCorrect = question.isCorrectMeaning;
    final userGotItRight =
        (isActuallyCorrect && userSaysCorrect) ||
        (!isActuallyCorrect && !userSaysCorrect);

    if (userGotItRight) {
      setState(() {
        _score += 10 + (_streak >= 3 ? 5 : 0);
        _streak++;
        _flashColor = AppColors.success;
      });
      _flashController.forward(from: 0);
      ref.read(gameProvider.notifier).answerCorrect();
    } else {
      setState(() {
        _streak = 0;
        _flashColor = AppColors.error;
        _isShaking = true;
      });
      _flashController.forward(from: 0);
      _shakeController.forward(from: 0).then((_) {
        if (mounted) {
          setState(() {
            _isShaking = false;
          });
        }
      });
      ref.read(gameProvider.notifier).answerWrong();
    }

    setState(() {
      _currentIndex++;
    });

    if (_currentIndex >= _questions.length) {
      _finishGame();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _flashController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_flashController, _shakeController]),
      builder: (context, child) {
        return Container(
          color: _flashColor != null && _flashController.isAnimating
              ? _flashColor!.withOpacity(0.15 * (1 - _flashController.value))
              : Colors.transparent,
          child: child,
        );
      },
      child: Column(
        children: [
          _buildStatusBar(),
          Expanded(
            child: _isFinished || _currentIndex >= _questions.length
                ? _buildFinishedView()
                : _buildQuestionArea(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.timer_outlined,
            value: '${_timeLeft}s',
            color: _timeLeft <= 10 ? AppColors.error : AppColors.primary,
          ),
          _buildStatItem(
            icon: Icons.star_rounded,
            value: '$_score',
            color: AppColors.accent,
          ),
          _buildStatItem(
            icon: Icons.local_fire_department_rounded,
            value: '$_streak',
            color: _streak >= 3 ? AppColors.error : AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionArea() {
    final question = _questions[_currentIndex];
    final wordWidget = Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            question.card.content,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              question.displayedMeaning,
              style: const TextStyle(
                fontSize: 20,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_isShaking)
          AnimatedBuilder(
            animation: _shakeController,
            builder: (context, child) {
              final offset =
                  sin(_shakeController.value * 4 * pi) * 10;
              return Transform.translate(
                offset: Offset(offset, 0),
                child: child,
              );
            },
            child: wordWidget,
          )
        else
          wordWidget,
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(
                child: _buildAnswerButton(
                  label: '✓ 认识',
                  color: AppColors.success,
                  onTap: () => _onAnswer(true),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAnswerButton(
                  label: '✗ 不认识',
                  color: AppColors.error,
                  onTap: () => _onAnswer(false),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '${_currentIndex + 1} / ${_questions.length}',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildAnswerButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
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
        ],
      ),
    );
  }
}

class _SpeedQuestion {
  final domain.Card card;
  final String displayedMeaning;
  final bool isCorrectMeaning;

  _SpeedQuestion({
    required this.card,
    required this.displayedMeaning,
    required this.isCorrectMeaning,
  });
}
