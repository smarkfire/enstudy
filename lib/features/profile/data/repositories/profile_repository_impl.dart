import 'package:enstudy/core/database/daos/user_profile_dao.dart';
import 'package:enstudy/features/profile/data/models/user_profile_model.dart';
import 'package:enstudy/features/profile/domain/entities/user_profile.dart';
import 'package:enstudy/features/profile/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final UserProfileDao _userProfileDao;

  ProfileRepositoryImpl(this._userProfileDao);

  @override
  Stream<UserProfile?> getProfile() =>
      _userProfileDao.getProfile().map((row) => row?.toEntity());

  @override
  Future<void> saveProfile(UserProfile profile) =>
      _userProfileDao.saveProfile(profile.toCompanion());

  @override
  Future<void> updateScore(int score) => _userProfileDao.updateScore(score);

  @override
  Future<void> updateLevel(int level) => _userProfileDao.updateLevel(level);

  @override
  Future<void> updateStreak(int streakDays, DateTime lastCheckin) =>
      _userProfileDao.updateStreak(
        streakDays,
        lastCheckin.millisecondsSinceEpoch,
      );
}
