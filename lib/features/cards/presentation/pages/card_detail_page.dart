import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:enstudy/core/theme/colors.dart';
import 'package:enstudy/features/cards/domain/entities/card.dart' as domain;
import 'package:enstudy/features/cards/presentation/providers/card_provider.dart';
import 'package:enstudy/features/cards/presentation/widgets/card_edit_dialog.dart';

class CardDetailPage extends ConsumerWidget {
  final String cardId;

  const CardDetailPage({super.key, required this.cardId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardAsync = ref.watch(cardDetailProvider(cardId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('卡片详情'),
        actions: [
          cardAsync.maybeWhen(
            data: (card) => PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _showEditDialog(context, ref, card);
                    break;
                  case 'delete':
                    _showDeleteDialog(context, ref);
                    break;
                  case 'source':
                    _viewSource(context, card.sourceId);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 20),
                      SizedBox(width: 8),
                      Text('编辑'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'source',
                  child: Row(
                    children: [
                      Icon(Icons.image_outlined, size: 20),
                      SizedBox(width: 8),
                      Text('查看来源图片'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                      SizedBox(width: 8),
                      Text('删除', style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
              ],
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: cardAsync.when(
        data: (card) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMainCard(context, card),
              const SizedBox(height: 16),
              _buildInfoSection(context, card),
              const SizedBox(height: 16),
              _buildProgressSection(context, card),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('加载失败: $error')),
      ),
    );
  }

  Widget _buildMainCard(BuildContext context, domain.Card card) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    card.content,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                _buildStatusChip(card.status),
              ],
            ),
            if (card.phonetic != null && card.phonetic!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                card.phonetic!,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const Divider(height: 32),
            Text(
              card.translation,
              style: const TextStyle(
                fontSize: 20,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    switch (status) {
      case 'new':
        color = AppColors.info;
        label = '新学';
        break;
      case 'review':
        color = AppColors.warning;
        label = '待复习';
        break;
      case 'learning':
        color = AppColors.accent;
        label = '学习中';
        break;
      case 'mastered':
        color = AppColors.success;
        label = '已掌握';
        break;
      default:
        color = AppColors.textHint;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, domain.Card card) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '详细信息',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            if (card.example != null && card.example!.isNotEmpty) ...[
              _buildInfoRow(
                context,
                Icons.format_quote,
                '例句',
                card.example!,
              ),
              const SizedBox(height: 8),
            ],
            if (card.exampleTranslation != null &&
                card.exampleTranslation!.isNotEmpty) ...[
              _buildInfoRow(
                context,
                Icons.translate,
                '例句翻译',
                card.exampleTranslation!,
              ),
              const SizedBox(height: 8),
            ],
            if (card.tags.isNotEmpty) ...[
              _buildInfoRow(
                context,
                Icons.label_outline,
                '标签',
                card.tags.join('、'),
              ),
              const SizedBox(height: 8),
            ],
            _buildInfoRow(
              context,
              Icons.signal_cellular_alt,
              '难度',
              '${card.difficulty} / 5',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
      BuildContext context, IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSection(BuildContext context, domain.Card card) {
    final accuracy =
        card.reviewCount > 0 ? card.correctCount / card.reviewCount : 0.0;
    final nextReviewStr = DateFormat('yyyy-MM-dd HH:mm').format(card.nextReview);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '复习进度',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildProgressItem(
                  context,
                  Icons.repeat,
                  '复习次数',
                  '${card.reviewCount}',
                ),
                _buildProgressItem(
                  context,
                  Icons.check_circle_outline,
                  '正确次数',
                  '${card.correctCount}',
                ),
                _buildProgressItem(
                  context,
                  Icons.percent,
                  '正确率',
                  '${(accuracy * 100).toInt()}%',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.schedule,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  '下次复习：$nextReviewStr',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressItem(
      BuildContext context, IconData icon, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, domain.Card card) {
    showDialog(
      context: context,
      builder: (context) => CardEditDialog(
        card: card,
        onSave: (updatedCard) {
          ref.read(cardNotifierProvider.notifier).updateCard(updatedCard);
          ref.invalidate(cardDetailProvider(cardId));
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('删除后无法恢复，确定要删除这张卡片吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(cardNotifierProvider.notifier).deleteCard(cardId);
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _viewSource(BuildContext context, String? sourceId) {
    if (sourceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('该卡片没有关联的来源图片')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('来源图片查看功能开发中')),
    );
  }
}
