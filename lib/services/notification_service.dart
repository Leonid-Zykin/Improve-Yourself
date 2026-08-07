import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../domain/models/models.dart';

/// Local notifications hook for day-2 (warning) reminders.
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    try {
      tzdata.initializeTimeZones();
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings();
      const settings = InitializationSettings(android: android, iOS: ios);
      await _plugin.initialize(settings: settings);
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      _ready = true;
    } catch (_) {
      // Notifications are best-effort on platforms without support.
      _ready = false;
    }
  }

  Future<void> syncDay2Warnings(List<RecoveryItem> items) async {
    if (!_ready) return;
    await _plugin.cancelAll();
    final warnings =
        items.where((i) => i.twoDay.state == TwoDayState.warning).toList();
    if (warnings.isEmpty) return;

    final titles = warnings.map((w) => w.title).take(3).join(', ');
    final body = warnings.length == 1
        ? '«${warnings.first.title}» — остался 1 день. Вернись сегодня.'
        : 'Под риском: $titles. Вернись сегодня.';

    try {
      final when = _nextEvening();
      await _plugin.zonedSchedule(
        id: 2002,
        title: 'День 2 — вернись',
        body: body,
        scheduledDate: when,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'day2_warnings',
            'Правило двух дней',
            channelDescription: 'Напоминание на второй день пропуска',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (_) {
      // Ignore scheduling failures (timezone / platform limits).
    }
  }

  tz.TZDateTime _nextEvening() {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, 19);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
