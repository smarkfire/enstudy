import 'package:flutter/material.dart';
import 'package:enstudy/core/theme/colors.dart';

class QualityButtons extends StatelessWidget {
  final ValueChanged<int> onQualitySelected;

  const QualityButtons({
    super.key,
    required this.onQualitySelected,
  });

  static const List<_QualityOption> _options = [
    _QualityOption(quality: 0, label: '完全不认识', color: Color(0xFFE74C3C)),
    _QualityOption(quality: 1, label: '有印象', color: Color(0xFFE67E22)),
    _QualityOption(quality: 2, label: '想起来了', color: Color(0xFFF1C40F)),
    _QualityOption(quality: 3, label: '一定印象', color: Color(0xFF2ECC71)),
    _QualityOption(quality: 4, label: '比较熟悉', color: Color(0xFF27AE60)),
    _QualityOption(quality: 5, label: '非常熟悉', color: Color(0xFF1B8A4A)),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '你的掌握程度',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: _options.map((option) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Material(
                  color: option.color,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: () => onQualitySelected(option.quality),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 56,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${option.quality}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            option.label,
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _QualityOption {
  final int quality;
  final String label;
  final Color color;

  const _QualityOption({
    required this.quality,
    required this.label,
    required this.color,
  });
}
