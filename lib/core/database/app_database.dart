import 'package:drift/drift.dart';

import 'daos/card_dao.dart';
import 'daos/source_dao.dart';
import 'daos/game_session_dao.dart';
import 'daos/review_log_dao.dart';
import 'daos/user_profile_dao.dart';

part 'app_database.g.dart';

@DataClassName('CardRow')
class Cards extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()();
  TextColumn get content => text()();
  TextColumn get translation => text()();
  TextColumn get phonetic => text().nullable()();
  TextColumn get example => text().nullable()();
  TextColumn get exampleTranslation => text().nullable()();
  TextColumn get sourceId => text().nullable()();
  TextColumn get tags => text().withDefault(const Constant('[]'))();
  IntColumn get difficulty => integer().withDefault(const Constant(3))();
  IntColumn get createdAt => integer()();
  IntColumn get reviewCount => integer().withDefault(const Constant(0))();
  IntColumn get correctCount => integer().withDefault(const Constant(0))();
  IntColumn get nextReview => integer()();
  RealColumn get interval => real().withDefault(const Constant(1.0))();
  RealColumn get easeFactor => real().withDefault(const Constant(2.5))();
  TextColumn get status => text().withDefault(const Constant('new'))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SourceRow')
class Sources extends Table {
  TextColumn get id => text()();
  TextColumn get imagePath => text()();
  TextColumn get thumbnailPath => text().nullable()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('GameSessionRow')
class GameSessions extends Table {
  TextColumn get id => text()();
  TextColumn get gameType => text()();
  IntColumn get startedAt => integer()();
  IntColumn get endedAt => integer().nullable()();
  IntColumn get score => integer().withDefault(const Constant(0))();
  IntColumn get totalQuestions => integer().withDefault(const Constant(0))();
  IntColumn get correctQuestions => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ReviewLogRow')
class ReviewLogs extends Table {
  TextColumn get id => text()();
  TextColumn get cardId => text()();
  TextColumn get sessionId => text().nullable()();
  IntColumn get quality => integer()();
  IntColumn get answeredAt => integer()();
  TextColumn get gameType => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('UserProfileRow')
class UserProfiles extends Table {
  @override
  String get tableName => 'user_profile';

  TextColumn get id => text()();
  IntColumn get totalScore => integer().withDefault(const Constant(0))();
  IntColumn get level => integer().withDefault(const Constant(1))();
  IntColumn get streakDays => integer().withDefault(const Constant(0))();
  IntColumn get lastCheckin => integer().nullable()();
  IntColumn get newCardsPerDay => integer().withDefault(const Constant(10))();
  TextColumn get remindTime => text().withDefault(const Constant('08:00'))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [Cards, Sources, GameSessions, ReviewLogs, UserProfiles],
  daos: [CardDao, SourceDao, GameSessionDao, ReviewLogDao, UserProfileDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_cards_status ON cards (status)');
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_cards_next_review ON cards (next_review)');
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_cards_created_at ON cards (created_at)');
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_review_logs_card_id ON review_logs (card_id)');
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_review_logs_session_id ON review_logs (session_id)');
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_review_logs_answered_at ON review_logs (answered_at)');
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_game_sessions_game_type ON game_sessions (game_type)');
        },
      );
}
