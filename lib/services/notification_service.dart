import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:my_daily_plus/models/event.dart';
import 'package:my_daily_plus/repositories/data_repository.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    final name = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(name));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings();
    const windows = WindowsInitializationSettings(
      appName: 'Мой Ежедневник+',
      appUserModelId: 'Com.Mydailyplus.MyDailyPlus',
      guid: 'c4f8a1b2-9e3d-4f5a-8c7b-1d2e3f4a5b6c',
    );
    const settings = InitializationSettings(
      android: android,
      iOS: darwin,
      windows: windows,
    );
    await _plugin.initialize(settings);
    _initialized = true;

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  DateTime? _nextReminderTime(CalendarEvent e) {
    final minutes = e.reminderMinutesBefore;
    final now = DateTime.now();
    for (var i = 0; i < 800; i++) {
      final day = DateTime(now.year, now.month, now.day)
          .add(Duration(days: i));
      if (!e.occursOnDay(day)) continue;
      final start = e.startOnDay(day);
      final fire = start.subtract(Duration(minutes: minutes));
      if (fire.isAfter(now)) return fire;
    }
    return null;
  }

  Future<void> scheduleEventReminder(CalendarEvent e) async {
    if (e.id == null) return;
    await cancelEventReminder(e.id!);
    if (e.reminderMinutesBefore <= 0) return;
    final fire = _nextReminderTime(e);
    if (fire == null) return;

    const android = AndroidNotificationDetails(
      'events_channel',
      'События',
      channelDescription: 'Напоминания о событиях календаря',
      importance: Importance.high,
      priority: Priority.high,
    );
    const darwin = DarwinNotificationDetails();
    const win = WindowsNotificationDetails(
      scenario: WindowsNotificationScenario.reminder,
    );
    const details = NotificationDetails(
      android: android,
      iOS: darwin,
      windows: win,
    );

    final when = tz.TZDateTime.from(fire, tz.local);
    await _plugin.zonedSchedule(
      e.id!,
      e.title,
      e.description?.isNotEmpty == true
          ? e.description!
          : 'Скоро начало',
      when,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelEventReminder(int eventId) async {
    await _plugin.cancel(eventId);
  }

  Future<void> rescheduleAllFromRepository(DataRepository repo) async {
    final events = await repo.getAllEvents();
    for (final e in events) {
      if (e.id != null) {
        await scheduleEventReminder(e);
      }
    }
  }
}
