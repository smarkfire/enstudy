import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enstudy/core/theme/colors.dart';
import 'package:enstudy/features/cards/domain/entities/card.dart' as domain;
import 'package:enstudy/features/games/presentation/providers/game_provider.dart';

class MatchGame extends ConsumerStatefulWidget {
  final List<domain.Card> cards;

  const MatchGame({super.key, required this.cards});

  @override
  ConsumerState<MatchGame> createState() => _MatchGameState();
}

class _MatchGameState extends ConsumerState<MatchGame>
    with TickerProviderStateMixin {
  late List<_MatchItem> _leftItems;
  late List<_MatchItem> _rightItems;
  int? _selectedLeftIndex;
  int? _selectedRightIndex;
  late AnimationController _successController;
  late AnimationController _shakeController;
  late AnimationController _fadeController;
  int? _shakeLeftIndex;
  int? _shakeRightIndex;
  int _matchedCount = 0;

  @override
  void initState() {
    super.initState();
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _initItems();
  }

  void _initItems() {
    _leftItems = widget.cards
        .map((c) => _MatchItem(id: c.id, text: c.content, card: c))
        .toList();
    _rightItems = widget.cards
        .map((c) => _MatchItem(id: c.id, text: c.translation, card: c))
        .toList();
    _rightItems.shuffle(Random());
  }

  @override
  void dispose() {
    _successController.dispose();
    _shakeController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _onLeftTap(int index) {
    if (_leftItems[index].isMatched) return;
    setState(() {
      _selectedLeftIndex = index;
      _selectedRightIndex = null;
    });
    if (_selectedRightIndex != null) {
      _checkMatch();
    }
  }

  void _onRightTap(int index) {
    if (_rightItems[index].isMatched) return;
    setState(() {
      _selectedRightIndex = index;
    });
    if (_selectedLeftIndex != null) {
      _checkMatch();
    }
  }

  void _checkMatch() {
    final left = _leftItems[_selectedLeftIndex!];
    final right = _rightItems[_selectedRightIndex!];

    if (left.id == right.id) {
      setState(() {
        left.isMatched = true;
        right.isMatched = true;
        _matchedCount++;
      });
      _successController.forward(from: 0).then((_) {
        _fadeController.forward(from: 0);
      });
      ref.read(gameProvider.notifier).answerCorrect();

      if (_matchedCount >= widget.cards.length) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) {
            ref.read(gameProvider.notifier).completeGame();
          }
        });
      }

      setState(() {
        _selectedLeftIndex = null;
        _selectedRightIndex = null;
      });
    } else {
      setState(() {
        _shakeLeftIndex = _selectedLeftIndex;
        _shakeRightIndex = _selectedRightIndex;
      });
      _shakeController.forward(from: 0).then((_) {
        setState(() {
          _shakeLeftIndex = null;
          _shakeRightIndex = null;
          _selectedLeftIndex = null;
          _selectedRightIndex = null;
        });
      });
      ref.read(gameProvider.notifier).answerWrong();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: List.generate(_leftItems.length, (i) {
                return _buildLeftCard(i);
              }),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: List.generate(_rightItems.length, (i) {
                return _buildRightCard(i);
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftCard(int index) {
    final item = _leftItems[index];
    final isSelected = _selectedLeftIndex == index;
    final isShaking = _shakeLeftIndex == index;

    if (item.isMatched) {
      return AnimatedBuilder(
        animation: _fadeController,
        builder: (context, child) {
          return Opacity(
            opacity: 1.0 - _fadeController.value,
            child: child,
          );
        },
        child: _buildCardContainer(
          text: item.text,
          backgroundColor: AppColors.success.withValues(alpha: 0.3),
          borderColor: AppColors.success,
        ),
      );
    }

    Color bgColor = Colors.white;
    Color borderColor = Colors.transparent;

    if (isSelected) {
      bgColor = AppColors.primaryLight.withValues(alpha: 0.2);
      borderColor = AppColors.primary;
    }

    Widget card = _buildCardContainer(
      text: item.text,
      backgroundColor: bgColor,
      borderColor: borderColor,
      onTap: () => _onLeftTap(index),
    );

    if (isShaking) {
      card = AnimatedBuilder(
        animation: _shakeController,
        builder: (context, child) {
          final offset = sin(_shakeController.value * 4 * pi) * 8;
          return Transform.translate(
            offset: Offset(offset, 0),
            child: child,
          );
        },
        child: _buildCardContainer(
          text: item.text,
          backgroundColor: AppColors.error.withValues(alpha: 0.2),
          borderColor: AppColors.error,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: card,
    );
  }

  Widget _buildRightCard(int index) {
    final item = _rightItems[index];
    final isSelected = _selectedRightIndex == index;
    final isShaking = _shakeRightIndex == index;

    if (item.isMatched) {
      return AnimatedBuilder(
        animation: _fadeController,
        builder: (context, child) {
          return Opacity(
            opacity: 1.0 - _fadeController.value,
            child: child,
          );
        },
        child: _buildCardContainer(
          text: item.text,
          backgroundColor: AppColors.success.withValues(alpha: 0.3),
          borderColor: AppColors.success,
        ),
      );
    }

    Color bgColor = Colors.white;
    Color borderColor = Colors.transparent;

    if (isSelected) {
      bgColor = AppColors.accent.withValues(alpha: 0.2);
      borderColor = AppColors.accent;
    }

    Widget card = _buildCardContainer(
      text: item.text,
      backgroundColor: bgColor,
      borderColor: borderColor,
      onTap: () => _onRightTap(index),
    );

    if (isShaking) {
      card = AnimatedBuilder(
        animation: _shakeController,
        builder: (context, child) {
          final offset = sin(_shakeController.value * 4 * pi) * 8;
          return Transform.translate(
            offset: Offset(offset, 0),
            child: child,
          );
        },
        child: _buildCardContainer(
          text: item.text,
          backgroundColor: AppColors.error.withValues(alpha: 0.2),
          borderColor: AppColors.error,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: card,
    );
  }

  Widget _buildCardContainer({
    required String text,
    required Color backgroundColor,
    required Color borderColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

class _MatchItem {
  final String id;
  final String text;
  final domain.Card card;
  bool isMatched;

  _MatchItem({
    required this.id,
    required this.text,
    required this.card,
  }) : isMatched = false;
}
