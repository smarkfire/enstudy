import 'package:drift/drift.dart';
import '../app_database.dart';

part 'user_profile_dao.g.dart';

@DriftAccessor(tables: [UserProfiles])
class UserProfileDao extends DatabaseAccessor<AppDatabase>
    with _$UserProfileDaoMixin {
  UserProfileDao(super.db);

  Stream<UserProfileRow?> getProfile() =>
      (select(userProfiles)..limit(1)).watchSingleOrNull();

  Future<void> saveProfile(Insertable<UserProfileRow> profile) =>
      into(userProfiles).insertOnConflictUpdate(profile);

  Future<void> updateScore(int score) =>
      (update(userProfiles)..where((t) => t.id.equals('default')))
          .write(UserProfilesCompanion(totalScore: Value(score)));

  Future<void> updateLevel(int level) =>
      (update(userProfiles)..where((t) => t.id.equals('default')))
          .write(UserProfilesCompanion(level: Value(level)));

  Future<void> updateStreak(int streakDays, int lastCheckin) =>
      (update(userProfiles)..where((t) => t.id.equals('default'))).write(
          UserProfilesCompanion(
              streakDays: Value(streakDays),
              lastCheckin: Value(lastCheckin)));
}
