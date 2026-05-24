import 'package:drift/drift.dart';
import 'package:enstudy/core/database/app_database.dart';
import 'package:enstudy/core/database/daos/game_session_dao.dart';
import 'package:enstudy/features/games/domain/entities/game_type.dart';
import 'package:enstudy/features/games/domain/repositories/game_repository.dart';

class GameRepositoryImpl implements GameRepository {
  final GameSessionDao _gameSessionDao;

  GameRepositoryImpl(this._gameSessionDao);

  @override
  Future<void> saveGameSession({
    required String id,
    required GameType gameType,
    required DateTime startedAt,
    DateTime? endedAt,
    int score = 0,
    int totalQuestions = 0,
    int correctQuestions = 0,
  }) =>
      _gameSessionDao.insertSession(
        GameSessionsCompanion(
          id: Value(id),
          gameType: Value(gameType.name),
          startedAt: Value(startedAt.millisecondsSinceEpoch),
          endedAt: Value(endedAt?.millisecondsSinceEpoch),
          score: Value(score),
          totalQuestions: Value(totalQuestions),
          correctQuestions: Value(correctQuestions),
        ),
      );

  @override
  Stream<List<Map<String, dynamic>>> getRecentSessions({int limit = 10}) =>
      _gameSessionDao
          .getRecentSessions(limit: limit)
          .map((rows) => rows.map((r) => r.toJson()).toList());

  @override
  Stream<List<Map<String, dynamic>>> getSessionsByType(GameType gameType) =>
      _gameSessionDao
          .getSessionsByType(gameType.name)
          .map((rows) => rows.map((r) => r.toJson()).toList());
}
