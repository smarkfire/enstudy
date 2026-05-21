import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const String reviewReminderChannelKey = 'review_reminder';
  static const String streakWarningChannelKey = 'streak_warning';

  static const int _dailyReminderId = 1;
  static const int _overdueReminderId = 2;
  static const int _streakWarningId = 3;

  Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: reviewReminderChannelKey,
          channelName: '复习提醒',
          channelDescription: '每日复习提醒通知',
          importance: NotificationImportance.High,
          defaultColor: const Color(0xFF4CAF50),
          ledColor: Colors.white,
        ),
        NotificationChannel(
          channelKey: streakWarningChannelKey,
          channelName: '打卡提醒',
          channelDescription: '打卡中断预警通知',
          importance: NotificationImportance.Default,
          defaultColor: const Color(0xFFFF9800),
          ledColor: Colors.white,
        ),
      ],
    );
    await _requestPermission();
  }

  Future<bool> _requestPermission() async {
    final isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      final result = await AwesomeNotifications()
          .requestPermissionToSendNotifications();
      return result ?? false;
    }
    return true;
  }

  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: _dailyReminderId,
        channelKey: reviewReminderChannelKey,
        title: '该复习啦！',
        body: '你有待复习的卡片，快来打卡吧 📚',
        payload: {'route': '/cards/review'},
      ),
      schedule: NotificationCalendar(
        hour: hour,
        minute: minute,
        second: 0,
        repeats: true,
      ),
    );
  }

  Future<void> showOverdueReminder({required int overdueCount}) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: _overdueReminderId,
        channelKey: reviewReminderChannelKey,
        title: '你有$overdueCount张逾期卡片',
        body: '再不复习就要忘记啦！',
        payload: {'route': '/cards/review'},
      ),
    );
  }

  Future<void> showStreakWarning() async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: _streakWarningId,
        channelKey: streakWarningChannelKey,
        title: '打卡即将中断！',
        body: '今天还没打卡，连续记录就要断了 🔥',
        payload: {'route': '/games'},
      ),
    );
  }

  Future<void> cancelAllNotifications() async {
    await AwesomeNotifications().cancelAll();
  }

  Future<void> updateReminderTime(int hour, int minute) async {
    await AwesomeNotifications().cancel(_dailyReminderId);
    await scheduleDailyReminder(hour: hour, minute: minute);
  }
}
