import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:enstudy/core/constants/app_constants.dart';
import 'package:enstudy/core/constants/game_constants.dart';
import 'package:enstudy/core/database/app_database.dart';
import 'package:enstudy/core/database/daos/card_dao.dart';
import 'package:enstudy/core/database/daos/game_session_dao.dart';
import 'package:enstudy/core/database/daos/review_log_dao.dart';
import 'package:enstudy/core/database/daos/source_dao.dart';
import 'package:enstudy/core/database/daos/user_profile_dao.dart';
import 'package:enstudy/core/utils/score_calculator.dart';
import 'package:enstudy/features/profile/data/models/user_profile_model.dart';
import 'package:enstudy/features/profile/domain/entities/user_profile.dart';
import 'package:enstudy/features/upload/presentation/providers/upload_provider.dart';

class ProfileStats {
  final int totalCards;
  final int reviewCount;
  final double correctRate;
  final int streakDays;
  final int masteredCount;
  final int todayDueCount;

  const ProfileStats({
    required this.totalCards,
    required this.reviewCount,
    required this.correctRate,
    required this.streakDays,
    required this.masteredCount,
    required this.todayDueCount,
  });
}

final cardDaoForProfileProvider = Provider<CardDao>((ref) {
  return CardDao(ref.watch(appDatabaseProvider));
});

final reviewLogDaoForProfileProvider = Provider<ReviewLogDao>((ref) {
  return ReviewLogDao(ref.watch(appDatabaseProvider));
});

final gameSessionDaoForProfileProvider = Provider<GameSessionDao>((ref) {
  return GameSessionDao(ref.watch(appDatabaseProvider));
});

final sourceDaoForProfileProvider = Provider<SourceDao>((ref) {
  return SourceDao(ref.watch(appDatabaseProvider));
});

final userProfileDaoProvider = Provider<UserProfileDao>((ref) {
  return UserProfileDao(ref.watch(appDatabaseProvider));
});

class ProfileNotifier extends AsyncNotifier<UserProfile> {
  @override
  Future<UserProfile> build() async {
    return loadProfile();
  }

  UserProfileDao get _userProfileDao => ref.read(userProfileDaoProvider);
  CardDao get _cardDao => ref.read(cardDaoForProfileProvider);
  ReviewLogDao get _reviewLogDao => ref.read(reviewLogDaoForProfileProvider);
  ScoreCalculator get _scoreCalculator => ScoreCalculator();

  Future<UserProfile> loadProfile() async {
    final profileRow = await _userProfileDao.getProfile().first;
    if (profileRow == null) {
      const defaultProfile = UserProfile(
        id: 'default',
        totalScore: 0,
        level: 1,
        streakDays: 0,
        newCardsPerDay: 10,
        remindTime: '08:00',
      );
      await _userProfileDao.saveProfile(defaultProfile.toCompanion());
      state = AsyncData(defaultProfile);
      return defaultProfile;
    }
    final profile = profileRow.toEntity();
    state = AsyncData(profile);
    return profile;
  }

  Future<void> addScore(int points) async {
    final profile = state.valueOrNull;
    if (profile == null) return;

    final newScore = profile.totalScore + points;
    final newLevel = _scoreCalculator.calculateLevelFromScore(newScore);

    await _userProfileDao.updateScore(newScore);
    if (newLevel != profile.level) {
      await _userProfileDao.updateLevel(newLevel);
    }

    final updated = profile.copyWith(totalScore: newScore, level: newLevel);
    state = AsyncData(updated);
  }

  Future<void> checkIn() async {
    final profile = state.valueOrNull;
    if (profile == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int newStreak = profile.streakDays;
    if (profile.lastCheckin != null) {
      final lastCheckinDay = DateTime(
        profile.lastCheckin!.year,
        profile.lastCheckin!.month,
        profile.lastCheckin!.day,
      );
      final diff = today.difference(lastCheckinDay).inDays;
      if (diff == 0) {
        return;
      } else if (diff == 1) {
        newStreak += 1;
      } else {
        newStreak = 1;
      }
    } else {
      newStreak = 1;
    }

    await _userProfileDao.updateStreak(newStreak, now.millisecondsSinceEpoch);

    final checkinScore = _scoreCalculator.calculateDailyCheckin();
    final newScore = profile.totalScore + checkinScore;
    final newLevel = _scoreCalculator.calculateLevelFromScore(newScore);

    await _userProfileDao.updateScore(newScore);
    if (newLevel != profile.level) {
      await _userProfileDao.updateLevel(newLevel);
    }

    final updated = profile.copyWith(
      totalScore: newScore,
      level: newLevel,
      streakDays: newStreak,
      lastCheckin: now,
    );
    state = AsyncData(updated);
  }

  Future<void> updateSettings({
    String? remindTime,
    int? newCardsPerDay,
    String? gameDifficulty,
  }) async {
    final profile = state.valueOrNull;
    if (profile == null) return;

    final updated = profile.copyWith(
      remindTime: remindTime ?? profile.remindTime,
      newCardsPerDay: newCardsPerDay ?? profile.newCardsPerDay,
    );

    await _userProfileDao.saveProfile(updated.toCompanion());
    state = AsyncData(updated);
  }

  Future<List<int>> getWeeklyStats() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final stats = <int>[];

    for (int i = 6; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      final startOfDay = day.millisecondsSinceEpoch;
      final endOfDay = day
          .add(const Duration(days: 1))
          .subtract(const Duration(milliseconds: 1))
          .millisecondsSinceEpoch;

      final logs =
          await _reviewLogDao.getLogsByDateRange(startOfDay, endOfDay).first;
      stats.add(logs.length);
    }

    return stats;
  }
}

final profileProvider = AsyncNotifierProvider<ProfileNotifier, UserProfile>(
  ProfileNotifier.new,
);

final weeklyStatsProvider = FutureProvider<List<int>>((ref) async {
  final notifier = ref.read(profileProvider.notifier);
  return notifier.getWeeklyStats();
});

final profileStatsProvider = FutureProvider<ProfileStats>((ref) async {
  final profileAsync = ref.watch(profileProvider);
  final profile = profileAsync.valueOrNull;

  final cardDao = ref.read(cardDaoForProfileProvider);
  final reviewLogDao = ref.read(reviewLogDaoForProfileProvider);

  final allCards = await cardDao.getAllCards().first;
  final allLogs = await reviewLogDao.getAllLogs().first;

  final totalCards = allCards.length;
  final reviewCount = allLogs.length;

  int correctCount = 0;
  for (final log in allLogs) {
    if (log.quality >= 3) correctCount++;
  }
  final correctRate = reviewCount > 0 ? correctCount / reviewCount : 0.0;

  final masteredCount = allCards.where((c) => c.status == 'mastered').length;

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final todayDueCount = allCards
      .where((c) =>
          c.nextReview <= today.millisecondsSinceEpoch &&
          c.status != 'mastered')
      .length;

  return ProfileStats(
    totalCards: totalCards,
    reviewCount: reviewCount,
    correctRate: correctRate,
    streakDays: profile?.streakDays ?? 0,
    masteredCount: masteredCount,
    todayDueCount: todayDueCount,
  );
});
