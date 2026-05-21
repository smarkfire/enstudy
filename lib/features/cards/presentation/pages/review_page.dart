import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:enstudy/core/theme/colors.dart';
import 'package:enstudy/features/cards/presentation/providers/review_provider.dart';
import 'package:enstudy/features/cards/presentation/widgets/quality_buttons.dart';
import 'package:enstudy/features/profile/presentation/providers/daily_task_provider.dart';

class ReviewPage extends ConsumerStatefulWidget {
  const ReviewPage({super.key});

  @override
  ConsumerState<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends ConsumerState<ReviewPage> {
  final Map<String, GlobalKey<_ReviewCardWrapperState>> _cardKeys = {};
  bool _isFlipped = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(reviewProvider.notifier).getDueCards();
    });
  }

  void _onQualitySelected(int quality) {
    final reviewState = ref.read(reviewProvider);
    final card = reviewState.currentCard;
    if (card == null) return;

    ref.read(reviewProvider.notifier).recordReview(
          cardId: card.id,
          quality: quality,
          gameType: 'flip',
        );

    ref.read(dailyTaskProvider.notifier).completeReviewTask();

    setState(() {
      _isFlipped = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final reviewState = ref.watch(reviewProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          reviewState.isCompleted
              ? '复习完成'
              : '${reviewState.currentIndex + 1} / ${reviewState.dueCards.length}',
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: reviewState.dueCards.isEmpty
          ? _buildEmptyState()
          : reviewState.isCompleted
              ? _buildCompleteState(reviewState)
              : _buildReviewContent(reviewState),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 64,
            color: AppColors.success,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无待复习卡片',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '所有卡片都已复习完毕',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textHint,
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.pop(),
            child: const Text('返回'),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewContent(ReviewState reviewState) {
    final card = reviewState.currentCard;
    if (card == null) return const SizedBox.shrink();

    return Column(
      children: [
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _ReviewCardWrapper(
                key: _cardKeys.putIfAbsent(card.id, () => GlobalKey()),
                content: card.content,
                phonetic: card.phonetic,
                translation: card.translation,
                example: card.example,
                exampleTranslation: card.exampleTranslation,
                onFlipped: (isFront) {
                  setState(() {
                    _isFlipped = !isFront;
                  });
                },
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: AnimatedOpacity(
            opacity: _isFlipped ? 1.0 : 0.3,
            duration: const Duration(milliseconds: 300),
            child: IgnorePointer(
              ignoring: !_isFlipped,
              child: QualityButtons(
                onQualitySelected: _onQualitySelected,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompleteState(ReviewState reviewState) {
    final accuracy = reviewState.accuracy;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accuracy >= 0.8
                        ? AppColors.success
                        : accuracy >= 0.5
                            ? AppColors.warning
                            : AppColors.error,
                    accuracy >= 0.8
                        ? AppColors.secondaryLight
                        : accuracy >= 0.5
                            ? AppColors.accent
                            : Color(0xFFFF6B6B),
                  ],
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                '${(accuracy * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '复习完成！',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem('复习总数', '${reviewState.totalReviewed}'),
                _buildStatItem('正确数', '${reviewState.correctCount}'),
                _buildStatItem(
                    '正确率', '${(accuracy * 100).toInt()}%'),
              ],
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => context.pop(),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('返回卡片库'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ReviewCardWrapper extends StatefulWidget {
  final String content;
  final String? phonetic;
  final String translation;
  final String? example;
  final String? exampleTranslation;
  final ValueChanged<bool> onFlipped;

  const _ReviewCardWrapper({
    super.key,
    required this.content,
    this.phonetic,
    required this.translation,
    this.example,
    this.exampleTranslation,
    required this.onFlipped,
  });

  @override
  State<_ReviewCardWrapper> createState() => _ReviewCardWrapperState();
}

class _ReviewCardWrapperState extends State<_ReviewCardWrapper> {
  bool _isFlipped = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isFlipped = !_isFlipped;
        });
        widget.onFlipped(_isFlipped);
      },
      child: AnimatedCrossFade(
        firstChild: _buildFront(),
        secondChild: _buildBack(),
        crossFadeState:
            _isFlipped ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        duration: const Duration(milliseconds: 500),
      ),
    );
  }

  Widget _buildFront() {
    return Container(
      width: double.infinity,
      height: 320,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryLight,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.content,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          if (widget.phonetic != null && widget.phonetic!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              widget.phonetic!,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 32),
          Icon(
            Icons.touch_app,
            color: Colors.white.withOpacity(0.5),
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            '点击翻转查看释义',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBack() {
    return Container(
      width: double.infinity,
      height: 320,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.secondary,
            AppColors.secondaryLight,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.translation,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            if (widget.example != null && widget.example!.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      widget.example!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (widget.exampleTranslation != null &&
                        widget.exampleTranslation!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        widget.exampleTranslation!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            Text(
              '请在下方评分',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
