import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enstudy/core/theme/colors.dart';
import 'package:enstudy/features/upload/presentation/providers/upload_provider.dart';
import 'package:enstudy/features/upload/presentation/widgets/upload_area.dart';
import 'package:enstudy/shared/widgets/loading_overlay.dart';

class UploadPage extends ConsumerStatefulWidget {
  const UploadPage({super.key});

  @override
  ConsumerState<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends ConsumerState<UploadPage> {
  final _promptController = TextEditingController();

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uploadState = ref.watch(uploadProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('上传'),
      ),
      body: LoadingOverlay(
        isLoading: uploadState.status != UploadStatus.idle &&
            uploadState.status != UploadStatus.readyToAnalyze &&
            uploadState.status != UploadStatus.previewing &&
            uploadState.status != UploadStatus.error,
        message: _getStatusMessage(uploadState.status),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              UploadArea(
                onTap: uploadState.status == UploadStatus.idle ||
                        uploadState.status == UploadStatus.error
                    ? () => ref.read(uploadProvider.notifier).pickImage()
                    : null,
              ),
              if (uploadState.status == UploadStatus.error &&
                  uploadState.errorMessage != null) ...[
                const SizedBox(height: 12),
                _buildErrorBanner(context, uploadState.errorMessage!),
              ],
              if (uploadState.status == UploadStatus.readyToAnalyze) ...[
                const SizedBox(height: 16),
                _buildImageReadyCard(context, uploadState),
                const SizedBox(height: 16),
                _buildAnalysisChoiceSection(context),
              ],
              if (uploadState.status == UploadStatus.previewing) ...[
                const SizedBox(height: 16),
                _buildPreviewSection(context, ref, uploadState),
              ],
              const SizedBox(height: 24),
              _buildRecentUploads(context),
            ],
          ),
        ),
      ),
    );
  }

  String? _getStatusMessage(UploadStatus status) {
    switch (status) {
      case UploadStatus.pickingImage:
        return '正在选择图片...';
      case UploadStatus.compressing:
        return '正在处理图片...';
      case UploadStatus.analyzing:
        return 'AI 正在分析图片...';
      case UploadStatus.saving:
        return '正在保存...';
      default:
        return null;
    }
  }

  Widget _buildErrorBanner(BuildContext context, String message) {
    final isQuotaError = message.contains('AI使用次数不足');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.error),
                ),
              ),
            ],
          ),
          if (isQuotaError) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 36,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/profile/purchase'),
                icon: const Icon(Icons.add_shopping_cart, size: 16),
                label: const Text('去购买次数', style: TextStyle(fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImageReadyCard(BuildContext context, UploadState uploadState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle,
                    color: AppColors.success, size: 22),
                const SizedBox(width: 8),
                Text(
                  '图片已就绪',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: kIsWeb
                  ? const Center(
                      child: Icon(Icons.image, size: 48, color: Colors.grey),
                    )
                  : (uploadState.imagePath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            uploadState.imagePath!,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.image,
                                  size: 48, color: Colors.grey),
                            ),
                          ),
                        )
                      : const Center(
                          child:
                              Icon(Icons.image, size: 48, color: Colors.grey),
                        )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisChoiceSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '选择解析方式',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        _buildChoiceCard(
          context,
          icon: Icons.auto_awesome,
          iconColor: AppColors.primary,
          title: '智能识别',
          subtitle: 'AI 自动识别标注内容和错题，提取单词和短语',
          onTap: () => ref.read(uploadProvider.notifier).analyzeWithDefault(),
        ),
        const SizedBox(height: 10),
        _buildChoiceCard(
          context,
          icon: Icons.edit_note,
          iconColor: AppColors.accent,
          title: '自定义要求',
          subtitle: '输入你的要求，AI 按需解析图片内容',
          onTap: () => _showCustomPromptSheet(context),
        ),
      ],
    );
  }

  Widget _buildChoiceCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: AppColors.textHint, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  void _showCustomPromptSheet(BuildContext context) {
    _promptController.clear();
    final viewInsets = MediaQuery.of(context).viewInsets;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 20,
            bottom: viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.edit_note,
                      color: AppColors.accent, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    '自定义解析要求',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '告诉 AI 你想如何解析这张图片',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 16),
              _buildQuickChips(context, setSheetState),
              const SizedBox(height: 12),
              TextField(
                controller: _promptController,
                maxLines: 4,
                minLines: 2,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: '例如：只提取图片中划线标注的动词...',
                  hintStyle:
                      const TextStyle(color: AppColors.textHint, fontSize: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
                onChanged: (_) => setSheetState(() {}),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _promptController.text.trim().isEmpty
                      ? null
                      : () {
                          Navigator.of(context).pop();
                          ref
                              .read(uploadProvider.notifier)
                              .analyzeWithCustomPrompt(
                                  _promptController.text.trim());
                        },
                  icon: const Icon(Icons.send_rounded, size: 20),
                  label: const Text('发送',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickChips(BuildContext context, StateSetter setSheetState) {
    final suggestions = [
      '提取划线标注的词',
      '识别错题',
      '提取所有生词',
      '提取固定搭配',
      '按难度分级',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: suggestions.map((s) {
        return ActionChip(
          label: Text(s, style: const TextStyle(fontSize: 12)),
          onPressed: () {
            final current = _promptController.text;
            _promptController.text = current.isEmpty ? s : '$current，$s';
            _promptController.selection = TextSelection.fromPosition(
              TextPosition(offset: _promptController.text.length),
            );
            setSheetState(() {});
          },
          side: const BorderSide(color: AppColors.divider),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        );
      }).toList(),
    );
  }

  Widget _buildPreviewSection(
    BuildContext context,
    WidgetRef ref,
    UploadState uploadState,
  ) {
    final result = uploadState.uploadResult;
    if (result == null) return const SizedBox.shrink();

    final totalCards = result.aiAnalysisResult.markedAnalysis.length +
        result.aiAnalysisResult.recommendations.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: kIsWeb
                  ? Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image, color: Colors.grey),
                    )
                  : Image.asset(
                      uploadState.imagePath!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image, color: Colors.grey),
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '分析完成',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '发现 $totalCards 张卡片',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.push('/upload/preview');
                      },
                      icon: const Icon(Icons.visibility, size: 18),
                      label: const Text('查看卡片'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentUploads(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '最近上传',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                const Icon(
                  Icons.inbox_outlined,
                  size: 48,
                  color: AppColors.textHint,
                ),
                const SizedBox(height: 8),
                Text(
                  '暂无上传记录',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
