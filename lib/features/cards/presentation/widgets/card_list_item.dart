import 'package:flutter/material.dart';
import 'package:enstudy/core/theme/colors.dart';
import 'package:enstudy/features/cards/domain/entities/card.dart' as domain;

class CardListItem extends StatelessWidget {
  final domain.Card card;
  final VoidCallback? onTap;

  const CardListItem({
    super.key,
    required this.card,
    this.onTap,
  });

  Color _statusColor(String status) {
    switch (status) {
      case 'new':
        return AppColors.info;
      case 'review':
        return AppColors.warning;
      case 'learning':
        return AppColors.accent;
      case 'mastered':
        return AppColors.success;
      default:
        return AppColors.textHint;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'new':
        return '新学';
      case 'review':
        return '待复习';
      case 'learning':
        return '学习中';
      case 'mastered':
        return '已掌握';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accuracy =
        card.reviewCount > 0 ? card.correctCount / card.reviewCount : 0.0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          card.content,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          card.translation,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor(card.status).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _statusLabel(card.status),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _statusColor(card.status),
                      ),
                    ),
                  ),
                ],
              ),
              if (card.phonetic != null && card.phonetic!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  card.phonetic!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textHint,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: accuracy,
                        backgroundColor: AppColors.divider,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          accuracy >= 0.8
                              ? AppColors.success
                              : accuracy >= 0.5
                                  ? AppColors.warning
                                  : AppColors.error,
                        ),
                        minHeight: 4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${(accuracy * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: accuracy >= 0.8
                          ? AppColors.success
                          : accuracy >= 0.5
                              ? AppColors.warning
                              : AppColors.error,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.repeat,
                    size: 14,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${card.reviewCount}次',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
