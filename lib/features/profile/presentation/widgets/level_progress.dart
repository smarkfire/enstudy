import 'package:flutter/material.dart';
import 'package:enstudy/core/constants/game_constants.dart';
import 'package:enstudy/core/theme/colors.dart';

class LevelProgress extends StatelessWidget {
  final int level;
  final int totalScore;

  const LevelProgress({
    super.key,
    required this.level,
    required this.totalScore,
  });

  String get _levelTitle {
    const titles = {
      1: '初学者',
      2: '入门者',
      3: '中级者',
      4: '中高级者',
      5: '高级者',
      6: '专家',
    };
    return titles[level] ?? '初学者';
  }

  IconData get _levelIcon {
    const icons = {
      1: Icons.looks_one,
      2: Icons.looks_two,
      3: Icons.looks_3,
      4: Icons.looks_4,
      5: Icons.looks_5,
      6: Icons.emoji_events,
    };
    return icons[level] ?? Icons.looks_one;
  }

  Color get _levelColor {
    const colors = {
      1: Color(0xFF90A4AE),
      2: Color(0xFF66BB6A),
      3: Color(0xFF42A5F5),
      4: Color(0xFFAB47BC),
      5: Color(0xFFFF7043),
      6: Color(0xFFFFD54F),
    };
    return colors[level] ?? const Color(0xFF90A4AE);
  }

  double get _progress {
    final thresholds = GameConstants.levelThresholds.values.toList()..sort();
    if (level >= thresholds.length) return 1.0;

    final currentThreshold = thresholds[level - 1];
    final nextThreshold =
        level < thresholds.length ? thresholds[level] : thresholds.last;

    if (nextThreshold == currentThreshold) return 1.0;
    return ((totalScore - currentThreshold) /
            (nextThreshold - currentThreshold))
        .clamp(0.0, 1.0);
  }

  int get _nextLevelScore {
    final thresholds = GameConstants.levelThresholds.values.toList()..sort();
    if (level >= thresholds.length) return thresholds.last;
    return thresholds[level];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _levelColor.withValues(alpha: 0.9),
            _levelColor.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_levelIcon, size: 32, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lv.$level $_levelTitle',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '总积分：$totalScore',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: _progress,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$totalScore',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              Text(
                '$_nextLevelScore',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
