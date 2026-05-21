import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enstudy/core/constants/game_constants.dart';
import 'package:enstudy/core/theme/colors.dart';
import 'package:enstudy/core/utils/score_calculator.dart';
import 'package:enstudy/features/games/presentation/providers/game_provider.dart';

class GameResultPage extends ConsumerStatefulWidget {
  const GameResultPage({super.key});

  @override
  ConsumerState<GameResultPage> createState() => _GameResultPageState();
}

class _GameResultPageState extends ConsumerState<GameResultPage>
    with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _scoreController;
  late AnimationController _slideController;
  bool _showWrongCards = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _scoreController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scoreController.forward();
    _slideController.forward();

    final state = ref.read(gameProvider);
    final accuracy = state.totalQuestions > 0
        ? (state.correctQuestions / state.totalQuestions * 100).round()
        : 0;

    if (accuracy >= 80) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _confettiController.play();
      });
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _scoreController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final accuracy = gameState.totalQuestions > 0
        ? (gameState.correctQuestions / gameState.totalQuestions * 100).round()
        : 0;
    final wrongCount = gameState.wrongCards.length;
    final correctCount = gameState.correctQuestions;
    final timeElapsed = gameState.timeElapsed;

    final expGained = gameState.score;
    final calculator = ScoreCalculator();
    final currentLevel = calculator.calculateLevelFromScore(0);
    final nextLevelThresholds = GameConstants.levelThresholds.values.toList()..sort();
    final currentThreshold = nextLevelThresholds[currentLevel - 1];
    final nextThreshold = currentLevel < nextLevelThresholds.length
        ? nextLevelThresholds[currentLevel]
        : nextLevelThresholds.last;
    final progress = (expGained / (nextThreshold - currentThreshold)).clamp(0.0, 1.0);

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildScoreSection(accuracy),
                  const SizedBox(height: 24),
                  _buildStatsGrid(correctCount, wrongCount, gameState.streak, timeElapsed),
                  const SizedBox(height: 24),
                  _buildExpSection(expGained, currentLevel, progress),
                  if (wrongCount > 0) ...[
                    const SizedBox(height: 24),
                    _buildWrongCardsSection(gameState),
                  ],
                  const SizedBox(height: 32),
                  _buildActionButtons(context),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 30,
              gravity: 0.1,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreSection(int accuracy) {
    return ScaleTransition(
      scale: CurvedAnimation(
        parent: _scoreController,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _scoreController,
            builder: (context, child) {
              final displayScore = (accuracy * _scoreController.value).round();
              return Text(
                '$displayScore',
                style: TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                  color: accuracy >= 80
                      ? AppColors.success
                      : accuracy >= 60
                          ? AppColors.accent
                          : AppColors.error,
                  height: 1,
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            accuracy >= 90
                ? '太棒了！完美表现！'
                : accuracy >= 80
                    ? '非常优秀！继续保持！'
                    : accuracy >= 60
                        ? '不错哦，再接再厉！'
                        : '加油，下次会更好！',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(
    int correct,
    int wrong,
    int streak,
    int timeElapsed,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _slideController,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
      )),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.check_circle_rounded,
              label: '正确',
              value: '$correct',
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.cancel_rounded,
              label: '错误',
              value: '$wrong',
              color: AppColors.error,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.local_fire_department_rounded,
              label: '连击',
              value: '$streak',
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.timer_rounded,
              label: '用时',
              value: _formatTime(timeElapsed),
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpSection(int expGained, int level, double progress) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accent.withOpacity(0.1),
            AppColors.accent.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.accent, size: 20),
              const SizedBox(width: 6),
              Text(
                '+$expGained 经验值',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Lv.$level',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.divider,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.accent,
                    ),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Lv.${level + 1}',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWrongCardsSection(GameState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _showWrongCards = !_showWrongCards;
            });
          },
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 20),
              const SizedBox(width: 6),
              Text(
                '错题回顾 (${state.wrongCards.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Icon(
                _showWrongCards
                    ? Icons.expand_less
                    : Icons.expand_more,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
        if (_showWrongCards)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              children: state.wrongCards.map((card) {
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.error.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              card.content,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (card.phonetic != null)
                              Text(
                                card.phonetic!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Text(
                          card.translation,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              context.go('/games');
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: const BorderSide(color: AppColors.primary),
            ),
            child: const Text(
              '返回大厅',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              context.go('/games');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              '再来一局',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}分${s}秒';
  }
}
