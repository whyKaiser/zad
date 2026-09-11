import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// إشعارات التطبيق. تذكيرات الماء تُجدول في **ساعات اليقظة فقط**
/// (٨ صباحاً–١٠ مساءً) — النسخة السابقة كانت تكرّر كل ساعة طوال الليل.
class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _init = false;
  static bool _tzReady = false;

  /// نطاق معرّفات تذكيرات الماء — واحد لكل ساعة مجدولة.
  static const _waterIdBase = 100;
  static const _firstHour = 8;
  static const _lastHour = 22;

  static const _waterDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'water_reminder',
      'تذكيرات الماء',
      channelDescription: 'تذكير بشرب الماء خلال اليوم',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    ),
    iOS: DarwinNotificationDetails(),
  );

  static Future<void> init() async {
    if (_init) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false, // نطلب الإذن عند تفعيل التذكيرات لا عند الإقلاع
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _init = true;
  }

  /// يضبط المنطقة الزمنية المحلية. حزمة timezone تبدأ على UTC،
  /// فنختار منطقة يطابق إزاحتها إزاحة الجهاز حتى تقع التذكيرات بالتوقيت الصحيح.
  static void _ensureTimeZone() {
    if (_tzReady) return;
    try {
      tzdata.initializeTimeZones();
      final offset = DateTime.now().timeZoneOffset;
      for (final loc in tz.timeZoneDatabase.locations.values) {
        if (tz.TZDateTime.now(loc).timeZoneOffset == offset) {
          tz.setLocalLocation(loc);
          break;
        }
      }
      _tzReady = true;
    } catch (e) {
      debugPrint('timezone init failed: $e');
    }
  }

  /// أقرب وقوع لساعة معيّنة بالتوقيت المحلي (اليوم أو غداً).
  static tz.TZDateTime _nextAt(int hour) {
    final now = tz.TZDateTime.now(tz.local);
    var when = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour);
    if (!when.isAfter(now)) when = when.add(const Duration(days: 1));
    return when;
  }

  /// يجدول تذكيراً يومياً متكرراً كل [intervalHours] ضمن ساعات اليقظة.
  static Future<void> scheduleWaterReminders({int intervalHours = 2}) async {
    if (kIsWeb) return;
    final step = intervalHours.clamp(1, 12);
    await cancelWaterReminders();
    _ensureTimeZone();

    try {
      var slot = 0;
      for (var hour = _firstHour; hour <= _lastHour; hour += step) {
        await _plugin.zonedSchedule(
          _waterIdBase + slot,
          'زاد 💧',
          'لا تنسَ تشرب ماء — هدفك ٨ أكواب.',
          _nextAt(hour),
          _waterDetails,
          // غير مضبوط بالثانية: لا يحتاج إذن المنبّهات الدقيقة على أندرويد ١٢+
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time, // يتكرّر يومياً
        );
        slot++;
      }
    } catch (e) {
      debugPrint('scheduleWaterReminders failed: $e');
    }
  }

  static Future<void> cancelWaterReminders() async {
    if (kIsWeb) return;
    try {
      // نمسح كامل النطاق حتى لو تغيّرت الفترة بين استدعاءين.
      for (var i = 0; i <= _lastHour - _firstHour; i++) {
        await _plugin.cancel(_waterIdBase + i);
      }
    } catch (e) {
      debugPrint('cancelWaterReminders failed: $e');
    }
  }

  static Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    try {
      final ios = await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      final android = await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      // على سطح المكتب/المنصات بلا تنفيذ خاص نعتبرها ممنوحة.
      if (ios == null && android == null) return true;
      return (ios ?? false) || (android ?? false);
    } catch (e) {
      debugPrint('requestPermissions failed: $e');
      return false;
    }
  }
}
