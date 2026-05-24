import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enstudy/core/theme/colors.dart';
import 'package:enstudy/features/cards/domain/entities/card.dart' as domain;
import 'package:enstudy/features/cards/presentation/providers/card_provider.dart';
import 'package:enstudy/features/games/domain/entities/game_type.dart';
import 'package:enstudy/features/games/presentation/providers/game_provider.dart';
import 'package:enstudy/features/profile/presentation/providers/daily_task_provider.dart';

class GameLobbyPage extends ConsumerWidget {
  const GameLobbyPage({super.key});

  static const List<_GameInfo> _games = [
    _GameInfo(
      type: GameType.match,
      description: '英中配对，消除方块',
      color: Color(0xFF6C5CE7),
      gradient: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
    ),
    _GameInfo(
      type: GameType.spell,
      description: '看义拼词，巩固记忆',
      color: Color(0xFF00B894),
      gradient: [Color(0xFF00B894), Color(0xFF55EFC4)],
    ),
    _GameInfo(
      type: GameType.listen,
      description: '听音选词，练耳力',
      color: Color(0xFF0984E3),
      gradient: [Color(0xFF0984E3), Color(0xFF74B9FF)],
    ),
    _GameInfo(
      type: GameType.fillBlank,
      description: '例句填空，学以致用',
      color: Color(0xFFE17055),
      gradient: [Color(0xFFE17055), Color(0xFFFAB1A0)],
    ),
    _GameInfo(
      type: GameType.speed,
      description: '限时挑战，拼手速',
      color: Color(0xFFFD79A8),
      gradient: [Color(0xFFFD79A8), Color(0xFFFDCB6E)],
    ),
    _GameInfo(
      type: GameType.reorder,
      description: '短语重组，练语法',
      color: Color(0xFF00CEC9),
      gradient: [Color(0xFF00CEC9), Color(0xFF81ECEC)],
    ),
    _GameInfo(
      type: GameType.shooting,
      description: '瞄准射击，快准狠',
      color: Color(0xFFE84393),
      gradient: [Color(0xFFE84393), Color(0xFFFD79A8)],
    ),
    _GameInfo(
      type: GameType.whack,
      description: '打地鼠，趣味记忆',
      color: Color(0xFFFDCB6E),
      gradient: [Color(0xFFFDCB6E), Color(0xFFF39C12)],
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyTaskState = ref.watch(dailyTaskProvider);
    final cardListAsync = ref.watch(cardListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('游戏大厅'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDailyTaskCard(context, dailyTaskState),
            const SizedBox(height: 20),
            Text(
              '选择游戏模式',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            cardListAsync.when(
              data: (cards) => _buildGameGrid(context, ref, cards),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => _buildGameGrid(context, ref, []),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyTaskCard(BuildContext context, DailyTaskState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department,
                  color: Colors.orange, size: 24),
              const SizedBox(width: 6),
              Text(
                '连续打卡 ${state.streakDays} 天',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              _buildCheckinBadge(state),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTaskItem(
                icon: Icons.replay_rounded,
                label: '复习任务',
                isCompleted: state.reviewTask.isCompleted,
              ),
              _buildTaskItem(
                icon: Icons.sports_esports_rounded,
                label: '游戏任务',
                isCompleted: state.gameTask.isCompleted,
              ),
              _buildTaskItem(
                icon: Icons.add_card_rounded,
                label: '新卡任务',
                isCompleted: state.newCardTask.isCompleted,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCheckinBadge(DailyTaskState state) {
    final isToday = state.lastCheckin != null &&
        DateTime.now().difference(state.lastCheckin!).inDays == 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isToday ? Colors.orange : Colors.white24,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isToday ? '已打卡' : '未打卡',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTaskItem({
    required IconData icon,
    required String label,
    required bool isCompleted,
  }) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isCompleted ? Colors.orange : Colors.white24,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCompleted ? Icons.check_rounded : icon,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildGameGrid(
      BuildContext context, WidgetRef ref, List<domain.Card> cards) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.1,
      children: _games.map((game) {
        return _buildGameCard(context, ref, game, cards);
      }).toList(),
    );
  }

  Widget _buildGameCard(
    BuildContext context,
    WidgetRef ref,
    _GameInfo game,
    List<domain.Card> cards,
  ) {
    final isAvailable = cards.isNotEmpty;

    return GestureDetector(
      onTap: isAvailable
          ? () async {
              await ref.read(gameProvider.notifier).startGame(
                    game.type,
                    cards,
                  );
              if (context.mounted) {
                context.push('/games/play', extra: game.type);
              }
            }
          : null,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isAvailable
                ? game.gradient
                : [Colors.grey, Colors.grey.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isAvailable
              ? [
                  BoxShadow(
                    color: game.color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  game.type.icon,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game.type.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    game.description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

class _GameInfo {
  final GameType type;
  final String description;
  final Color color;
  final List<Color> gradient;

  const _GameInfo({
    required this.type,
    required this.description,
    required this.color,
    required this.gradient,
  });
}
