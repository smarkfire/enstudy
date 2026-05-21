import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enstudy/core/theme/colors.dart';
import 'package:enstudy/features/cards/domain/entities/card.dart' as domain;
import 'package:enstudy/features/games/presentation/providers/game_provider.dart';

class FillBlankGame extends ConsumerStatefulWidget {
  final List<domain.Card> cards;

  const FillBlankGame({super.key, required this.cards});

  @override
  ConsumerState<FillBlankGame> createState() => _FillBlankGameState();
}

class _FillBlankGameState extends ConsumerState<FillBlankGame> {
  late List<domain.Card> _cards;
  int _currentIndex = 0;
  late List<domain.Card> _options;
  int? _selectedOption;
  bool _answered = false;
  bool _isCorrect = false;

  @override
  void initState() {
    super.initState();
    _cards = widget.cards.where((c) => c.example != null && c.example!.isNotEmpty).toList();
    if (_cards.isEmpty) {
      _cards = widget.cards;
    }
    _generateOptions();
  }

  void _generateOptions() {
    if (_currentIndex >= _cards.length) return;
    final correct = _cards[_currentIndex];
    final others = widget.cards.where((c) => c.id != correct.id).toList();
    others.shuffle(Random());
    final distractors = others.take(3).toList();
    _options = [correct, ...distractors]..shuffle(Random());
  }

  String _getBlankedSentence(domain.Card card) {
    if (card.example == null || card.example!.isEmpty) {
      return '____ ${card.translation}';
    }
    final sentence = card.example!;
    final word = card.content;
    final regex = RegExp(RegExp.escape(word), caseSensitive: false);
    return sentence.replaceFirst(regex, '____');
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

    Future.delayed(const Duration(milliseconds: 1500), () {
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
  }

  @override
  Widget build(BuildContext context) {
    if (_currentIndex >= _cards.length) {
      return const Center(child: CircularProgressIndicator());
    }

    final card = _cards[_currentIndex];
    final blankedSentence = _getBlankedSentence(card);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const Row(
                  children: [
                    Icon(Icons.format_quote, color: AppColors.primary, size: 20),
                    SizedBox(width: 4),
                    Text(
                      '填入正确的单词',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  blankedSentence,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: _answered && _isCorrect
                        ? AppColors.success
                        : AppColors.textPrimary,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (card.exampleTranslation != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    card.exampleTranslation!,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 28),
          if (_answered && !_isCorrect)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.error),
              ),
              child: Text(
                '正确答案: ${card.content}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.error,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(_options.length, (i) {
              return _buildOptionChip(i);
            }),
          ),
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

  Widget _buildOptionChip(int index) {
    final option = _options[index];
    final isSelected = _selectedOption == index;
    final correctId = _cards[_currentIndex].id;

    Color bgColor = Colors.white;
    Color borderColor = AppColors.divider;
    Color textColor = AppColors.textPrimary;

    if (_answered) {
      if (option.id == correctId) {
        bgColor = AppColors.success.withOpacity(0.1);
        borderColor = AppColors.success;
        textColor = AppColors.success;
      } else if (isSelected && option.id != correctId) {
        bgColor = AppColors.error.withOpacity(0.1);
        borderColor = AppColors.error;
        textColor = AppColors.error;
      }
    } else if (isSelected) {
      bgColor = AppColors.primary.withOpacity(0.1);
      borderColor = AppColors.primary;
      textColor = AppColors.primary;
    }

    return GestureDetector(
      onTap: () => _onOptionTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_answered && option.id == correctId)
              const Icon(Icons.check_circle, color: AppColors.success, size: 18)
            else if (_answered && isSelected && option.id != correctId)
              const Icon(Icons.cancel, color: AppColors.error, size: 18),
            if (_answered && (option.id == correctId || (isSelected && option.id != correctId)))
              const SizedBox(width: 6),
            Text(
              option.content,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
