import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enstudy/core/theme/colors.dart';
import 'package:enstudy/features/upload/presentation/providers/upload_provider.dart';
import 'package:enstudy/features/upload/presentation/widgets/card_preview_item.dart';

class CardPreviewPage extends ConsumerWidget {
  const CardPreviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uploadState = ref.watch(uploadProvider);
    final result = uploadState.uploadResult;

    if (result == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('卡片预览')),
        body: const Center(child: Text('暂无数据')),
      );
    }

    final markedAnalysis = result.aiAnalysisResult.markedAnalysis;
    final recommendations = result.aiAnalysisResult.recommendations;
    final selectedIds = uploadState.selectedCardIds;

    return Scaffold(
      appBar: AppBar(
        title: const Text('卡片预览'),
        actions: [
          TextButton.icon(
            onPressed: () => _saveCards(context, ref),
            icon: const Icon(Icons.save, color: Colors.white),
            label: const Text(
              '保存',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildImagePreview(context, uploadState.imagePath),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (markedAnalysis.isNotEmpty) ...[
                    _buildSectionHeader(
                      context,
                      '识别到的内容',
                      Icons.check_circle,
                      AppColors.primary,
                      '${selectedIds.where((id) => id.startsWith('marked_')).length}/${markedAnalysis.length}',
                    ),
                    const SizedBox(height: 8),
                    ...markedAnalysis.map((item) {
                      final cardId = 'marked_${item.content}';
                      final isSelected = selectedIds.contains(cardId);
                      return CardPreviewItem(
                        cardId: cardId,
                        content: item.content,
                        translation: item.translation,
                        phonetic: item.phonetic,
                        example: item.example,
                        exampleTranslation: item.exampleTranslation,
                        isSelected: isSelected,
                        isRecommendation: false,
                        onToggle: () => ref
                            .read(uploadProvider.notifier)
                            .toggleCardSelection(cardId),
                        onEdit: (
                          content,
                          translation,
                          phonetic,
                          example,
                          exampleTranslation,
                        ) {
                          ref.read(uploadProvider.notifier).editCard(
                                cardId,
                                content: content,
                                translation: translation,
                                phonetic: phonetic,
                                example: example,
                                exampleTranslation: exampleTranslation,
                              );
                        },
                      );
                    }),
                  ],
                  if (recommendations.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildSectionHeader(
                      context,
                      'AI推荐补充',
                      Icons.auto_awesome,
                      AppColors.accent,
                      '${selectedIds.where((id) => id.startsWith('rec_')).length}/${recommendations.length}',
                    ),
                    const SizedBox(height: 8),
                    ...recommendations.map((item) {
                      final cardId = 'rec_${item.content}';
                      final isSelected = selectedIds.contains(cardId);
                      return CardPreviewItem(
                        cardId: cardId,
                        content: item.content,
                        translation: item.translation,
                        phonetic: item.phonetic,
                        example: item.example,
                        exampleTranslation: item.exampleTranslation,
                        isSelected: isSelected,
                        isRecommendation: true,
                        reason: item.reason,
                        type: item.type,
                        onToggle: () => ref
                            .read(uploadProvider.notifier)
                            .toggleCardSelection(cardId),
                        onEdit: (
                          content,
                          translation,
                          phonetic,
                          example,
                          exampleTranslation,
                        ) {
                          ref.read(uploadProvider.notifier).editCard(
                                cardId,
                                content: content,
                                translation: translation,
                                phonetic: phonetic,
                                example: example,
                                exampleTranslation: exampleTranslation,
                              );
                        },
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
          _buildBottomBar(context, ref, selectedIds.length),
        ],
      ),
    );
  }

  Widget _buildImagePreview(BuildContext context, String? imagePath) {
    if (imagePath == null) return const SizedBox.shrink();

    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: const Border(
          bottom: BorderSide(color: AppColors.divider),
        ),
      ),
      child: kIsWeb
          ? const Center(child: Icon(Icons.image, size: 64, color: Colors.grey))
          : Image.asset(
              imagePath,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.image, size: 64, color: Colors.grey)),
            ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String count,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(
      BuildContext context, WidgetRef ref, int selectedCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: selectedCount > 0 ? () => _saveCards(context, ref) : null,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            '保存所选卡片 ($selectedCount)',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Future<void> _saveCards(BuildContext context, WidgetRef ref) async {
    final savedCount =
        await ref.read(uploadProvider.notifier).saveSelectedCards();

    if (!context.mounted) return;

    if (savedCount > 0) {
      _showSaveSuccessDialog(context, ref, savedCount);
    } else if (savedCount == -1) {
      _showSaveErrorDialog(context);
    }
  }

  void _showSaveSuccessDialog(BuildContext context, WidgetRef ref, int count) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle,
                  color: AppColors.success, size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              '保存成功！',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '已成功保存 $count 张卡片到卡片库',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    context.go('/cards');
                  },
                  icon: const Icon(Icons.library_books, size: 20),
                  label: const Text('查看卡片库'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    ref.read(uploadProvider.notifier).reset();
                    context.go('/upload');
                  },
                  icon: const Icon(Icons.add_photo_alternate, size: 20),
                  label: const Text('继续上传'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text(
                  '留在当前页',
                  style: TextStyle(color: AppColors.textHint),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSaveErrorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline,
                  color: AppColors.error, size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              '保存失败',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '卡片保存过程中出现错误，请重试。\n如果问题持续，请检查应用设置。',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('知道了'),
            ),
          ),
        ],
      ),
    );
  }
}
