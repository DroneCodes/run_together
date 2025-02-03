import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackgroundTrackingService {
  static const String notificationChannelId = 'running_tracker_channel';
  static const int notificationId = 888;

  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    // Configure notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      notificationChannelId,
      'Running Tracker Service',
      description: 'Keeps track of your running activities in the background',
      importance: Importance.high,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: notificationChannelId,
        initialNotificationTitle: 'Running Tracker Active',
        initialNotificationContent: 'Tracking your run...',
        foregroundServiceNotificationId: notificationId,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    return true;
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isPaused = prefs.getBool('is_paused') ?? false;

    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });

      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }

    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    // Handle pause/resume
    service.on('setPaused').listen((event) async {
      isPaused = event?['isPaused'] ?? false;
      await prefs.setBool('is_paused', isPaused);
    });

    // Start the timer
    Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (service is AndroidServiceInstance) {
        if (!isPaused) {
          double distance = prefs.getDouble('current_distance') ?? 0;
          int durationInSeconds = prefs.getInt('current_duration') ?? 0;

          await prefs.setInt('current_duration', durationInSeconds + 1);

          service.setForegroundNotificationInfo(
            title: 'Running Tracker Active',
            content: 'Distance: ${(distance * 0.000621371).toStringAsFixed(2)} miles | ' +
                'Time: ${Duration(seconds: durationInSeconds + 1).toString().split('.').first}',
          );

          // Broadcast status
          service.invoke(
            'update',
            {
              'duration': durationInSeconds + 1,
              'isTracking': true,
            },
          );
        }
      }
    });

    // Start location tracking
    if (!isPaused) {
      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 1,
        ),
      ).listen((Position position) async {
        if (!isPaused) {
          final lastLat = prefs.getDouble('last_latitude');
          final lastLng = prefs.getDouble('last_longitude');

          if (lastLat != null && lastLng != null) {
            final newDistance = Geolocator.distanceBetween(
              lastLat,
              lastLng,
              position.latitude,
              position.longitude,
            );

            double currentDistance = prefs.getDouble('current_distance') ?? 0;
            await prefs.setDouble('current_distance', currentDistance + newDistance);

            service.invoke(
              'updateLocation',
              {
                'distance': currentDistance + newDistance,
                'latitude': position.latitude,
                'longitude': position.longitude,
              },
            );
          }

          await prefs.setDouble('last_latitude', position.latitude);
          await prefs.setDouble('last_longitude', position.longitude);
        }
      });
    }
  }
}