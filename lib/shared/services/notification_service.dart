import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const String reviewReminderChannelId = 'review_reminder';
  static const String reviewReminderChannelName = '复习提醒';
  static const String streakWarningChannelId = 'streak_warning';
  static const String streakWarningChannelName = '打卡提醒';

  static const int _dailyReminderId = 1;
  static const int _overdueReminderId = 2;
  static const int _streakWarningId = 3;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    await _requestPermission();
  }

  void _onNotificationResponse(NotificationResponse response) {
    debugPrint('Notification payload: ${response.payload}');
  }

  Future<bool> _requestPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidPlugin =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        return granted ?? false;
      }
    }
    return true;
  }

  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      reviewReminderChannelId,
      reviewReminderChannelName,
      channelDescription: '每日复习提醒通知',
      importance: Importance.high,
      priority: Priority.high,
    );
    const darwinDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    await _plugin.zonedSchedule(
      _dailyReminderId,
      '该复习啦！',
      '你有待复习的卡片，快来打卡吧 📚',
      _nextInstanceOfTime(hour, minute),
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: '/cards/review',
    );
  }

  Future<void> showOverdueReminder({required int overdueCount}) async {
    const androidDetails = AndroidNotificationDetails(
      reviewReminderChannelId,
      reviewReminderChannelName,
      channelDescription: '每日复习提醒通知',
      importance: Importance.high,
      priority: Priority.high,
    );
    const darwinDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    await _plugin.show(
      _overdueReminderId,
      '你有$overdueCount张逾期卡片',
      '再不复习就要忘记啦！',
      details,
      payload: '/cards/review',
    );
  }

  Future<void> showStreakWarning() async {
    const androidDetails = AndroidNotificationDetails(
      streakWarningChannelId,
      streakWarningChannelName,
      channelDescription: '打卡中断预警通知',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const darwinDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    await _plugin.show(
      _streakWarningId,
      '打卡即将中断！',
      '今天还没打卡，连续记录就要断了 🔥',
      details,
      payload: '/games',
    );
  }

  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }

  Future<void> updateReminderTime(int hour, int minute) async {
    await _plugin.cancel(_dailyReminderId);
    await scheduleDailyReminder(hour: hour, minute: minute);
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
