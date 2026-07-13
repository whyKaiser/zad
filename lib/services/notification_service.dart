import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _init = false;

  static const _waterId = 100;

  static Future<void> init() async {
    if (_init) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _init = true;
  }

  static Future<void> scheduleWaterReminders({int intervalHours = 2}) async {
    if (kIsWeb) return;
    await cancelWaterReminders();
    await _plugin.periodicallyShow(
      _waterId,
      'زاد 💧',
      'لا تنسى تشرب ماء! هدفك 8 أكواب.',
      RepeatInterval.hourly,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'water_reminder', 'تذكيرات الماء',
          channelDescription: 'تذكير بشرب الماء',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  static Future<void> cancelWaterReminders() async {
    if (kIsWeb) return;
    await _plugin.cancel(_waterId);
  }

  static Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    final ios = await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    final android = await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    return (ios ?? false) || (android ?? false);
  }
}
