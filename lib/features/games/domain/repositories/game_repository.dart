import 'package:enstudy/features/games/domain/entities/game_type.dart';

abstract class GameRepository {
  Future<void> saveGameSession({
    required String id,
    required GameType gameType,
    required DateTime startedAt,
    DateTime? endedAt,
    int score = 0,
    int totalQuestions = 0,
    int correctQuestions = 0,
  });

  Stream<List<Map<String, dynamic>>> getRecentSessions({int limit = 10});

  Stream<List<Map<String, dynamic>>> getSessionsByType(GameType gameType);
}
