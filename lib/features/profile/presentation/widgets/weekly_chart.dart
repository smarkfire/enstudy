import 'dart:math';

import 'package:flutter/material.dart';
import 'package:enstudy/core/theme/colors.dart';

class WeeklyChart extends StatelessWidget {
  final List<int> data;

  const WeeklyChart({
    super.key,
    required this.data,
  });

  static const _weekDays = ['一', '二', '三', '四', '五', '六', '日'];

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 160),
      painter: _WeeklyChartPainter(data: data),
    );
  }
}

class _WeeklyChartPainter extends CustomPainter {
  final List<int> data;

  _WeeklyChartPainter({required this.data});

  static const _weekDays = ['一', '二', '三', '四', '五', '六', '日'];

  @override
  void paint(Canvas canvas, Size size) {
    final barAreaHeight = size.height - 28;
    final barWidth = (size.width - 40) / 7;
    final maxValue =
        data.isEmpty ? 1 : data.reduce(max).clamp(1, double.maxFinite.toInt());

    final barPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    final barPaintInactive = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    const textStyle = TextStyle(
      color: AppColors.textSecondary,
      fontSize: 11,
    );

    for (int i = 0; i < 7; i++) {
      final x = 20.0 + i * barWidth;
      final value = i < data.length ? data[i] : 0;
      final barHeight =
          maxValue > 0 ? (value / maxValue) * (barAreaHeight - 20) : 0.0;
      final barRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          x + barWidth * 0.2,
          barAreaHeight - barHeight - 4,
          barWidth * 0.6,
          barHeight,
        ),
        Radius.circular(barHeight > 4 ? 4 : 0),
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            x + barWidth * 0.2,
            4,
            barWidth * 0.6,
            barAreaHeight - 8,
          ),
          const Radius.circular(4),
        ),
        barPaintInactive,
      );

      if (barHeight > 0) {
        canvas.drawRRect(barRect, barPaint);
      }

      final dayTextPainter = TextPainter(
        text: TextSpan(text: _weekDays[i], style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      dayTextPainter.paint(
        canvas,
        Offset(x + barWidth / 2 - dayTextPainter.width / 2, barAreaHeight + 6),
      );

      if (value > 0) {
        final valueTextPainter = TextPainter(
          text: TextSpan(
            text: '$value',
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        valueTextPainter.paint(
          canvas,
          Offset(
            x + barWidth / 2 - valueTextPainter.width / 2,
            barAreaHeight - barHeight - 18,
          ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WeeklyChartPainter oldDelegate) {
    return data != oldDelegate.data;
  }
}
