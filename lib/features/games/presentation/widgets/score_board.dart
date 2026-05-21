import 'package:flutter/material.dart';
import 'package:enstudy/core/theme/colors.dart';

class ScoreBoard extends StatelessWidget {
  final int score;
  final int streak;
  final int timeRemaining;

  const ScoreBoard({
    super.key,
    required this.score,
    required this.streak,
    required this.timeRemaining,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildItem(
            context,
            icon: Icons.star_rounded,
            label: '得分',
            value: '$score',
            color: AppColors.accent,
          ),
          _buildItem(
            context,
            icon: Icons.local_fire_department_rounded,
            label: '连击',
            value: '$streak',
            color: streak >= 3 ? AppColors.error : AppColors.textSecondary,
          ),
          _buildItem(
            context,
            icon: Icons.timer_rounded,
            label: '剩余',
            value: _formatTime(timeRemaining),
            color: timeRemaining <= 30 ? AppColors.error : AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
