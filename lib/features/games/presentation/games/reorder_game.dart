import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enstudy/core/theme/colors.dart';
import 'package:enstudy/features/cards/domain/entities/card.dart' as domain;
import 'package:enstudy/features/games/presentation/providers/game_provider.dart';

class ReorderGame extends ConsumerStatefulWidget {
  final List<domain.Card> cards;

  const ReorderGame({super.key, required this.cards});

  @override
  ConsumerState<ReorderGame> createState() => _ReorderGameState();
}

class _ReorderGameState extends ConsumerState<ReorderGame>
    with TickerProviderStateMixin {
  late List<domain.Card> _cards;
  int _currentIndex = 0;
  late List<String> _shuffledParts;
  late List<String> _correctParts;
  List<String> _selectedParts = [];
  bool _answered = false;
  bool _isCorrect = false;
  late AnimationController _successController;
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _cards = widget.cards;
    _setupQuestion();
  }

  void _setupQuestion() {
    if (_currentIndex >= _cards.length) return;
    final card = _cards[_currentIndex];
    _correctParts = _splitWord(card.content);
    _shuffledParts = List<String>.from(_correctParts)..shuffle(Random());
    _selectedParts = [];
    _answered = false;
    _isCorrect = false;
  }

  List<String> _splitWord(String word) {
    if (word.length <= 3) {
      return [word];
    }
    final parts = <String>[];
    int i = 0;
    final random = Random();
    while (i < word.length) {
      final chunkSize = word.length - i <= 2
          ? word.length - i
          : (random.nextBool() ? 2 : 3);
      final end = (i + chunkSize).clamp(0, word.length);
      parts.add(word.substring(i, end));
      i = end;
    }
    if (parts.length < 3) {
      final letters = word.split('');
      final result = <String>[];
      for (int j = 0; j < letters.length; j++) {
        if (j > 0 && j < letters.length - 1 && random.nextBool()) {
          result[result.length - 1] = result.last + letters[j];
        } else {
          result.add(letters[j]);
        }
      }
      return result.length >= 2 ? result : word.split('');
    }
    return parts;
  }

  void _onPartTap(String part) {
    if (_answered) return;
    setState(() {
      _selectedParts.add(part);
    });
    if (_selectedParts.length == _correctParts.length) {
      _checkAnswer();
    }
  }

  void _onSelectedPartTap(int index) {
    if (_answered) return;
    setState(() {
      _selectedParts.removeAt(index);
    });
  }

  void _checkAnswer() {
    final userAnswer = _selectedParts.join();
    final correctAnswer = _correctParts.join();
    final correct = userAnswer.toLowerCase() == correctAnswer.toLowerCase();

    setState(() {
      _answered = true;
      _isCorrect = correct;
    });

    if (correct) {
      _successController.forward(from: 0);
      ref.read(gameProvider.notifier).answerCorrect();
    } else {
      _shakeController.forward(from: 0);
      ref.read(gameProvider.notifier).answerWrong();
    }

    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      _nextQuestion();
    });
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (_answered) return;
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _selectedParts.removeAt(oldIndex);
      _selectedParts.insert(newIndex, item);
    });
  }

  void _submitAnswer() {
    if (_answered || _selectedParts.isEmpty) return;
    if (_selectedParts.length < _correctParts.length) {
      return;
    }
    _checkAnswer();
  }

  void _nextQuestion() {
    if (_currentIndex + 1 >= _cards.length) {
      ref.read(gameProvider.notifier).completeGame();
      return;
    }
    setState(() {
      _currentIndex++;
    });
    _setupQuestion();
  }

  @override
  void dispose() {
    _successController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentIndex >= _cards.length) {
      return const Center(child: CircularProgressIndicator());
    }

    final card = _cards[_currentIndex];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
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
                const Icon(Icons.translate,
                    color: AppColors.primary, size: 28),
                const SizedBox(height: 8),
                Text(
                  card.translation,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildAnswerArea(),
          const SizedBox(height: 20),
          if (!_answered)
            Container(
              constraints: const BoxConstraints(minHeight: 80),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: _shuffledParts.map((part) {
                  final isUsed = _selectedParts.contains(part) &&
                      _countInList(_selectedParts, part) >
                          _countBeforeIndex(
                              _shuffledParts, part, _shuffledParts.indexOf(part));
                  return _buildDraggableChip(
                    text: part,
                    onTap: isUsed ? null : () => _onPartTap(part),
                    isUsed: isUsed,
                  );
                }).toList(),
              ),
            ),
          if (_answered && !_isCorrect) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.success),
              ),
              child: Text(
                '正确顺序: ${_correctParts.join()}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          const Spacer(),
          if (!_answered &&
              _selectedParts.length == _correctParts.length)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _submitAnswer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '提交',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
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

  int _countInList(List<String> list, String item) {
    return list.where((e) => e == item).length;
  }

  int _countBeforeIndex(List<String> list, String item, int index) {
    int count = 0;
    for (int i = 0; i < index; i++) {
      if (list[i] == item) count++;
    }
    return count;
  }

  Widget _buildAnswerArea() {
    if (_answered && _isCorrect) {
      return ScaleTransition(
        scale: CurvedAnimation(
          parent: _successController,
          curve: Curves.elasticOut,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.success, width: 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle,
                  color: AppColors.success, size: 28),
              const SizedBox(width: 8),
              Text(
                _correctParts.join(),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_answered && !_isCorrect) {
      return AnimatedBuilder(
        animation: _shakeController,
        builder: (context, child) {
          final offset = sin(_shakeController.value * 4 * pi) * 8;
          return Transform.translate(
            offset: Offset(offset, 0),
            child: child,
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.error, width: 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cancel, color: AppColors.error, size: 28),
              const SizedBox(width: 8),
              Text(
                _selectedParts.join(),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.error,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 60),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _selectedParts.length == _correctParts.length
              ? AppColors.primary
              : AppColors.divider,
          width: 2,
        ),
      ),
      child: _selectedParts.isEmpty
          ? Center(
              child: Text(
                '点击下方卡片排列正确顺序',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textHint,
                ),
              ),
            )
          : ReorderableWrap(
              onReorder: _onReorder,
              children: _selectedParts.asMap().entries.map((entry) {
                return _buildSelectedChip(
                  key: ValueKey('selected_${entry.key}'),
                  text: entry.value,
                  index: entry.key,
                );
              }).toList(),
            ),
    );
  }

  Widget _buildSelectedChip({
    required Key key,
    required String text,
    required int index,
  }) {
    return GestureDetector(
      key: key,
      onTap: () => _onSelectedPartTap(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildDraggableChip({
    required String text,
    VoidCallback? onTap,
    bool isUsed = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isUsed ? 0.3 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isUsed ? AppColors.divider : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isUsed ? AppColors.divider : AppColors.primary,
              width: 2,
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isUsed ? AppColors.textHint : AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

class ReorderableWrap extends StatelessWidget {
  final List<Widget> children;
  final void Function(int, int) onReorder;

  const ReorderableWrap({
    super.key,
    required this.children,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: children,
    );
  }
}
