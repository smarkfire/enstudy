import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enstudy/core/theme/colors.dart';
import 'package:enstudy/features/games/domain/entities/game_type.dart';
import 'package:enstudy/features/games/presentation/games/fill_blank_game.dart';
import 'package:enstudy/features/games/presentation/games/listen_game.dart';
import 'package:enstudy/features/games/presentation/games/match_game.dart';
import 'package:enstudy/features/games/presentation/games/reorder_game.dart';
import 'package:enstudy/features/games/presentation/games/shooting_game.dart';
import 'package:enstudy/features/games/presentation/games/speed_game.dart';
import 'package:enstudy/features/games/presentation/games/spell_game.dart';
import 'package:enstudy/features/games/presentation/games/whack_game.dart';
import 'package:enstudy/features/games/presentation/providers/game_provider.dart';
import 'package:enstudy/features/games/presentation/widgets/score_board.dart';

class GamePlayPage extends ConsumerWidget {
  final GameType gameType;

  const GamePlayPage({super.key, required this.gameType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);

    ref.listen<GameState>(gameProvider, (prev, next) {
      if (next.isCompleted && !(prev?.isCompleted ?? false)) {
        context.go('/games/result');
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('退出游戏'),
                content: const Text('确定要退出当前游戏吗？进度将不会保存。'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('继续游戏'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.go('/games');
                    },
                    child: const Text('退出'),
                  ),
                ],
              ),
            );
          },
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(gameType.icon, size: 20),
            const SizedBox(width: 6),
            Text(gameType.displayName),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 18,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(gameState.timeElapsed),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildGameContent(gameState),
          ),
          ScoreBoard(
            score: gameState.score,
            streak: gameState.streak,
            timeRemaining: gameState.timeRemaining,
          ),
        ],
      ),
    );
  }

  Widget _buildGameContent(GameState state) {
    if (state.cards.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    switch (gameType) {
      case GameType.match:
        return MatchGame(cards: state.cards);
      case GameType.spell:
        return SpellGame(cards: state.cards);
      case GameType.listen:
        return ListenGame(cards: state.cards);
      case GameType.fillBlank:
        return FillBlankGame(cards: state.cards);
      case GameType.speed:
        return SpeedGame(cards: state.cards);
      case GameType.reorder:
        return ReorderGame(cards: state.cards);
      case GameType.shooting:
        return ShootingGame(cards: state.cards);
      case GameType.whack:
        return WhackGame(cards: state.cards);
    }
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
