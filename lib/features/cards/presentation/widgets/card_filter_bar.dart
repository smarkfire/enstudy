import 'package:flutter/material.dart';
import 'package:enstudy/core/theme/colors.dart';

class CardFilterBar extends StatelessWidget {
  final String? selectedStatus;
  final Map<String, int> statusCounts;
  final ValueChanged<String?> onStatusSelected;

  const CardFilterBar({
    super.key,
    this.selectedStatus,
    required this.statusCounts,
    required this.onStatusSelected,
  });

  static const List<_StatusOption> _statusOptions = [
    _StatusOption(status: null, label: '全部', color: AppColors.primary),
    _StatusOption(status: 'new', label: '新学', color: AppColors.info),
    _StatusOption(status: 'review', label: '待复习', color: AppColors.warning),
    _StatusOption(status: 'learning', label: '学习中', color: AppColors.accent),
    _StatusOption(status: 'mastered', label: '已掌握', color: AppColors.success),
  ];

  int _getCount(String? status) {
    if (status == null) {
      return statusCounts.values.fold(0, (sum, count) => sum + count);
    }
    return statusCounts[status] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _statusOptions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = _statusOptions[index];
          final isSelected = selectedStatus == option.status;
          final count = _getCount(option.status);

          return FilterChip(
            selected: isSelected,
            label: Text('${option.label} $count'),
            labelStyle: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? Colors.white : option.color,
            ),
            backgroundColor: option.color.withOpacity(0.1),
            selectedColor: option.color,
            side: BorderSide(
              color: option.color.withOpacity(isSelected ? 0.0 : 0.3),
            ),
            showCheckmark: false,
            onSelected: (_) {
              onStatusSelected(isSelected ? null : option.status);
            },
          );
        },
      ),
    );
  }
}

class _StatusOption {
  final String? status;
  final String label;
  final Color color;

  const _StatusOption({
    required this.status,
    required this.label,
    required this.color,
  });
}
