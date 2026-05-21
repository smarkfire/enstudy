import 'package:drift/drift.dart';
import '../app_database.dart';

part 'game_session_dao.g.dart';

@DriftAccessor(tables: [GameSessions])
class GameSessionDao extends DatabaseAccessor<AppDatabase>
    with _$GameSessionDaoMixin {
  GameSessionDao(super.db);

  Stream<List<GameSessionRow>> getAllSessions() => select(gameSessions).watch();

  Future<void> insertSession(Insertable<GameSessionRow> session) =>
      into(gameSessions).insert(session);

  Stream<List<GameSessionRow>> getRecentSessions({int limit = 10}) =>
      (select(gameSessions)..orderBy([(t) => OrderingTerm.desc(t.startedAt)])..limit(limit))
          .watch();

  Stream<List<GameSessionRow>> getSessionsByType(String gameType) =>
      (select(gameSessions)..where((t) => t.gameType.equals(gameType))).watch();
}
