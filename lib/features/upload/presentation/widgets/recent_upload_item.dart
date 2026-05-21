import 'package:flutter/material.dart';
import 'package:enstudy/core/theme/colors.dart';

class RecentUploadItem extends StatelessWidget {
  final String thumbnailPath;
  final int cardCount;
  final DateTime date;

  const RecentUploadItem({
    super.key,
    required this.thumbnailPath,
    required this.cardCount,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildThumbnail(),
              const SizedBox(width: 12),
              Expanded(child: _buildInfo(context)),
              Icon(
                Icons.chevron_right,
                color: AppColors.textHint,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: AppColors.background,
        image: DecorationImage(
          image: AssetImage(thumbnailPath),
          fit: BoxFit.cover,
          onError: (_, __) {},
        ),
      ),
      child: thumbnailPath.isEmpty
          ? Icon(
              Icons.image_outlined,
              color: AppColors.textHint,
              size: 24,
            )
          : null,
    );
  }

  Widget _buildInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$cardCount 张卡片',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          _formatDate(date),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return '今天';
    if (diff.inDays == 1) return '昨天';
    if (diff.inDays < 7) return '${diff.inDays}天前';

    return '${date.month}月${date.day}日';
  }
}
