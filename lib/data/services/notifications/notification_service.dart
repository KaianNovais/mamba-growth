import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Wrapper sobre flutter_local_notifications focado nas necessidades
/// da feature de jejum (uma única notificação agendada por vez,
/// id constante).
class NotificationService {
  NotificationService();

  static const fastEndId = 1;
  static const _channelId = 'mamba_growth_fasting';
  static const _channelName = 'Jejum';
  static const _channelDescription = 'Avisos de fim de jejum';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    // ic_notification é uma silhueta branca em fundo transparente
    // (drawable XML em android/app/src/main/res/drawable/). O Android
    // tinta o ícone e descarta cores, então o launcher cheio vira
    // mancha — daí esse asset dedicado.
    const android = AndroidInitializationSettings('@drawable/ic_notification');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );
    _initialized = true;
  }

  Future<bool> requestPermissionIfNeeded() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    bool granted = true;

    if (android != null) {
      granted = await android.requestNotificationsPermission() ?? false;
      try {
        await android.requestExactAlarmsPermission();
      } catch (e, st) {
        debugPrint('exactAlarms permission failed: $e\n$st');
      }
    }

    if (ios != null) {
      granted = await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    return granted;
  }

  Future<void> scheduleFastEnd({
    required DateTime endAt,
    required String title,
    required String body,
  }) async {
    final scheduled = tz.TZDateTime.from(endAt, tz.local);
    // v21: todos os args de zonedSchedule são nomeados (id inclusive).
    await _plugin.zonedSchedule(
      id: fastEndId,
      title: title,
      body: body,
      scheduledDate: scheduled,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          // Cor da marca (AppColors.dark.accent). Aplica como tint do
          // ícone monocromático e bg do círculo no Android 5+.
          color: Color(0xFFD4A24C),
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelFastEnd() => _plugin.cancel(id: fastEndId);
}
