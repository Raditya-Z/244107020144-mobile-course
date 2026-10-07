import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class PushService {
  PushService({
    required this.go,
  });

  final void Function(String route) go;

  final FirebaseMessaging _messaging =
      FirebaseMessaging.instance;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initializationSettings =
        InitializationSettings(
      android: androidSettings,
    );

    await _localNotifications.initialize(
    settings: initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        final route = response.payload;

        if (route != null && route.isNotEmpty) {
          debugPrint(
            'Notifikasi foreground diklik: $route',
          );

          go(route);
        }
      },
    );

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint(
      'Notification permission: '
      '${settings.authorizationStatus}',
    );

    final token = await _messaging.getToken();

    debugPrint('FCM Token: $token');

    _messaging.onTokenRefresh.listen(
      (newToken) {
        debugPrint(
          'FCM Token diperbarui: $newToken',
        );
      },
    );

    await _messaging.subscribeToTopic(
      'pengumuman-kampus',
    );

    debugPrint(
      'Berhasil subscribe topic: pengumuman-kampus',
    );

    FirebaseMessaging.onMessage.listen(
      (RemoteMessage message) async {
        debugPrint('Pesan foreground diterima');
        debugPrint(
          'Message ID: ${message.messageId}',
        );
        debugPrint(
          'Title: ${message.notification?.title}',
        );
        debugPrint(
          'Body: ${message.notification?.body}',
        );
        debugPrint(
          'Data: ${message.data}',
        );

        final notification =
            message.notification;

        final route =
            message.data['route'] ?? '/';

        if (notification != null) {
          await _localNotifications.show(
              id: message.hashCode,
              title: notification.title ?? 'Pengumuman',
              body: notification.body ?? '',
              notificationDetails: const NotificationDetails(
              android: AndroidNotificationDetails(
                'pengumuman',
                'Pengumuman Kampus',
                channelDescription:
                    'Notifikasi pengumuman kampus',
                importance: Importance.high,
                priority: Priority.high,
              ),
            ),
            payload: route,
          );
        }
      },
    );

    FirebaseMessaging.onMessageOpenedApp.listen(
      (RemoteMessage message) {
        final route =
            message.data['route'] ?? '/';

        debugPrint(
          'Notifikasi background diklik: $route',
        );

        go(route);
      },
    );

    final initialMessage =
        await _messaging.getInitialMessage();

    if (initialMessage != null) {
      final route =
          initialMessage.data['route'] ?? '/';

      debugPrint(
        'Notifikasi terminated diklik: $route',
      );

      Future.microtask(() {
        go(route);
      });
    }
  }

  Future<void> unsubscribeTopic() async {
    await _messaging.unsubscribeFromTopic(
      'pengumuman-kampus',
    );

    debugPrint(
      'Berhasil unsubscribe topic: pengumuman-kampus',
    );
  }
}