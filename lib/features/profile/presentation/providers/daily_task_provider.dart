import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:enstudy/core/database/app_database.dart';
import 'package:enstudy/core/database/daos/user_profile_dao.dart';
import 'package:enstudy/features/profile/data/models/daily_task.dart';
import 'package:enstudy/features/profile/domain/entities/user_profile.dart';
import 'package:enstudy/features/profile/data/models/user_profile_model.dart';
import 'package:enstudy/features/upload/presentation/providers/upload_provider.dart';

final userProfileDaoProvider = Provider<UserProfileDao>((ref) {
  return UserProfileDao(ref.watch(appDatabaseProvider));
});

class DailyTaskState {
  final DailyTask reviewTask;
  final DailyTask gameTask;
  final DailyTask newCardTask;
  final int streakDays;
  final DateTime? lastCheckin;

  const DailyTaskState({
    required this.reviewTask,
    required this.gameTask,
    required this.newCardTask,
    this.streakDays = 0,
    this.lastCheckin,
  });

  DailyTaskState copyWith({
    DailyTask? reviewTask,
    DailyTask? gameTask,
    DailyTask? newCardTask,
    int? streakDays,
    DateTime? lastCheckin,
  }) {
    return DailyTaskState(
      reviewTask: reviewTask ?? this.reviewTask,
      gameTask: gameTask ?? this.gameTask,
      newCardTask: newCardTask ?? this.newCardTask,
      streakDays: streakDays ?? this.streakDays,
      lastCheckin: lastCheckin ?? this.lastCheckin,
    );
  }
}

class DailyTaskNotifier extends StateNotifier<DailyTaskState> {
  final UserProfileDao _userProfileDao;

  DailyTaskNotifier(this._userProfileDao)
      : super(
          const DailyTaskState(
            reviewTask: DailyTask(
              taskId: 'daily_review',
              title: '每日复习',
              description: '完成今日复习任务',
              reward: 10,
            ),
            gameTask: DailyTask(
              taskId: 'daily_game',
              title: '每日游戏',
              description: '完成一次游戏',
              reward: 10,
            ),
            newCardTask: DailyTask(
              taskId: 'daily_new_card',
              title: '每日新卡',
              description: '学习新卡片',
              reward: 10,
            ),
          ),
        );

  Future<void> checkDailyTasks() async {
    final profileRow = await _userProfileDao.getProfile().first;
    if (profileRow == null) return;
    final profile = profileRow.toEntity();

    state = state.copyWith(
      streakDays: profile.streakDays,
      lastCheckin: profile.lastCheckin,
    );
  }

  void completeReviewTask() {
    if (!state.reviewTask.isCompleted) {
      state = state.copyWith(
        reviewTask: state.reviewTask.copyWith(isCompleted: true),
      );
    }
  }

  void completeGameTask() {
    if (!state.gameTask.isCompleted) {
      state = state.copyWith(
        gameTask: state.gameTask.copyWith(isCompleted: true),
      );
    }
  }

  void completeNewCardTask() {
    if (!state.newCardTask.isCompleted) {
      state = state.copyWith(
        newCardTask: state.newCardTask.copyWith(isCompleted: true),
      );
    }
  }

  Future<void> checkIn() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final lastCheckin = state.lastCheckin;
    int newStreak = state.streakDays;

    if (lastCheckin != null) {
      final lastCheckinDay =
          DateTime(lastCheckin.year, lastCheckin.month, lastCheckin.day);
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
    state = state.copyWith(
      streakDays: newStreak,
      lastCheckin: now,
    );
  }

  int getStreakDays() => state.streakDays;
}

final dailyTaskProvider =
    StateNotifierProvider<DailyTaskNotifier, DailyTaskState>((ref) {
  return DailyTaskNotifier(ref.watch(userProfileDaoProvider));
});
