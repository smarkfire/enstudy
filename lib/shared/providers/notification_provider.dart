import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enstudy/core/database/app_database.dart';
import 'package:enstudy/core/database/daos/card_dao.dart';
import 'package:enstudy/features/profile/presentation/providers/profile_provider.dart';
import 'package:enstudy/features/upload/presentation/providers/upload_provider.dart';
import 'package:enstudy/shared/services/notification_service.dart';

final _notificationCardDaoProvider = Provider<CardDao>((ref) {
  return CardDao(ref.watch(appDatabaseProvider));
});

class NotificationNotifier extends Notifier<void> {
  @override
  void build() {
    initNotifications();
  }

  Future<void> initNotifications() async {
    await NotificationService().initialize();
  }

  Future<void> scheduleReminder() async {
    final profile = ref.read(profileProvider).valueOrNull;
    if (profile == null) return;

    final parts = profile.remindTime.split(':');
    final hour = int.tryParse(parts[0]) ?? 8;
    final minute = int.tryParse(parts[1]) ?? 0;

    await NotificationService().scheduleDailyReminder(
      hour: hour,
      minute: minute,
    );
  }

  Future<void> checkAndNotify() async {
    final cardDao = ref.read(_notificationCardDaoProvider);
    final now = DateTime.now().millisecondsSinceEpoch;
    final dueCards = await cardDao.getCardsDueForReview(now).first;
    final overdueCount =
        dueCards.where((c) => c.status != 'mastered').length;

    if (overdueCount > 0) {
      await NotificationService().showOverdueReminder(
        overdueCount: overdueCount,
      );
    }

    final profile = ref.read(profileProvider).valueOrNull;
    if (profile != null && profile.streakDays > 0) {
      final lastCheckin = profile.lastCheckin;
      if (lastCheckin != null) {
        final nowDate = DateTime.now();
        final today = DateTime(nowDate.year, nowDate.month, nowDate.day);
        final lastDay = DateTime(
          lastCheckin.year,
          lastCheckin.month,
          lastCheckin.day,
        );
        if (today.difference(lastDay).inDays > 0) {
          await NotificationService().showStreakWarning();
        }
      }
    }
  }

  Future<void> updateReminderTime(int hour, int minute) async {
    await NotificationService().updateReminderTime(hour, minute);
  }
}

final notificationProvider = NotifierProvider<NotificationNotifier, void>(
  NotificationNotifier.new,
);
