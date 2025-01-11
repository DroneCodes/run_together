import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/browser.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/date_plan.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  // // Handle background messages
  // FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  //
  // // Handle foreground messages
  // FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

  static Future<void> initialize() async {
    // Initialize timezone
    tz.initializeTimeZones();

    // Request permission
    await _messaging.requestPermission();

    // Initialize local notifications
    const initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notifications.initialize(initializationSettings);
  }

  static Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    print("Handling a background message: ${message.messageId}");
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    _notifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'default_channel',
          'Default Channel',
          importance: Importance.high,
        ),
      ),
    );
  }

  static Future<void> scheduleUpcomingDateNotification(
      DatePlan datePlan) async {
    final scheduledDate = datePlan.date.subtract(const Duration(hours: 24));

    if (scheduledDate.isAfter(DateTime.now())) {
      await _notifications.zonedSchedule(
        datePlan.hashCode,
        'Upcoming Date',
        'You have a date planned tomorrow: ${datePlan.activity}',
        tz.TZDateTime.from(scheduledDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'date_reminder',
            'Date Reminders',
            importance: Importance.high,
          ),
        ),
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime, androidScheduleMode: AndroidScheduleMode.alarmClock,
      );
    }
  }
}