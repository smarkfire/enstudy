import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enstudy/core/theme/colors.dart';
import 'package:enstudy/features/cards/domain/entities/card.dart' as domain;
import 'package:enstudy/features/games/presentation/providers/game_provider.dart';
import 'package:enstudy/shared/services/tts_service.dart';

class ListenGame extends ConsumerStatefulWidget {
  final List<domain.Card> cards;

  const ListenGame({super.key, required this.cards});

  @override
  ConsumerState<ListenGame> createState() => _ListenGameState();
}

class _ListenGameState extends ConsumerState<ListenGame> {
  late List<domain.Card> _cards;
  int _currentIndex = 0;
  late List<domain.Card> _options;
  int? _selectedOption;
  bool _answered = false;
  bool _isCorrect = false;
  final TtsService _ttsService = TtsService();

  @override
  void initState() {
    super.initState();
    _cards = widget.cards;
    _generateOptions();
    _ttsService.init().then((_) {
      _speakCurrent();
    });
  }

  void _generateOptions() {
    if (_currentIndex >= _cards.length) return;
    final correct = _cards[_currentIndex];
    final others = widget.cards.where((c) => c.id != correct.id).toList();
    others.shuffle(Random());
    final distractors = others.take(3).toList();
    _options = [correct, ...distractors]..shuffle(Random());
  }

  void _speakCurrent() {
    if (_currentIndex < _cards.length) {
      _ttsService.speak(_cards[_currentIndex].content);
    }
  }

  void _onOptionTap(int index) {
    if (_answered) return;

    final selected = _options[index];
    final correct = _cards[_currentIndex];
    final isCorrect = selected.id == correct.id;

    setState(() {
      _selectedOption = index;
      _answered = true;
      _isCorrect = isCorrect;
    });

    if (isCorrect) {
      ref.read(gameProvider.notifier).answerCorrect();
    } else {
      ref.read(gameProvider.notifier).answerWrong();
    }

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      _nextQuestion();
    });
  }

  void _nextQuestion() {
    if (_currentIndex + 1 >= _cards.length) {
      ref.read(gameProvider.notifier).completeGame();
      return;
    }

    setState(() {
      _currentIndex++;
      _answered = false;
      _isCorrect = false;
      _selectedOption = null;
    });
    _generateOptions();
    _speakCurrent();
  }

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentIndex >= _cards.length) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _speakCurrent,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.volume_up_rounded,
                color: Colors.white,
                size: 48,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '点击播放发音',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 36),
          ...List.generate(_options.length, (i) {
            return _buildOption(i);
          }),
          const SizedBox(height: 16),
          Text(
            '${_currentIndex + 1} / ${_cards.length}',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(int index) {
    final option = _options[index];
    final isSelected = _selectedOption == index;
    final correctId = _cards[_currentIndex].id;

    Color bgColor = Colors.white;
    Color borderColor = AppColors.divider;
    Color textColor = AppColors.textPrimary;
    IconData? trailingIcon;

    if (_answered) {
      if (option.id == correctId) {
        bgColor = AppColors.success.withOpacity(0.1);
        borderColor = AppColors.success;
        textColor = AppColors.success;
        trailingIcon = Icons.check_circle;
      } else if (isSelected && option.id != correctId) {
        bgColor = AppColors.error.withOpacity(0.1);
        borderColor = AppColors.error;
        textColor = AppColors.error;
        trailingIcon = Icons.cancel;
      }
    } else if (isSelected) {
      bgColor = AppColors.primary.withOpacity(0.1);
      borderColor = AppColors.primary;
      textColor = AppColors.primary;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _onOptionTap(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _answered && option.id == correctId
                      ? AppColors.success
                      : _answered && isSelected && option.id != correctId
                          ? AppColors.error
                          : AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: trailingIcon != null
                      ? Icon(trailingIcon, color: Colors.white, size: 18)
                      : Text(
                          String.fromCharCode(65 + index),
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  option.content,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
