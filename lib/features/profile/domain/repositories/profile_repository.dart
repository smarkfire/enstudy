import 'package:enstudy/features/profile/domain/entities/user_profile.dart';

abstract class ProfileRepository {
  Stream<UserProfile?> getProfile();

  Future<void> saveProfile(UserProfile profile);

  Future<void> updateScore(int score);

  Future<void> updateLevel(int level);

  Future<void> updateStreak(int streakDays, DateTime lastCheckin);
}
