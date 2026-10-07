import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class PushService {
  PushService({required this.go, required this.devicesApi});
  // Tidak mengakses BuildContext; navigasi hanya lewat callback GoRouter.go.
  final void Function(String route) go;
  final Dio devicesApi;
  final _messaging = FirebaseMessaging.instance;
  final _local = FlutterLocalNotificationsPlugin();
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  static const topic = 'pengumuman-kampus';
  bool _disposed = false;
  Future<void>? _initialization;

  Future<void> init() => _initialization ??= _init();

  Future<void> _init() async {
    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // iOS: izin diminta lewat Firebase, bukan dua kali lewat plugin local.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) => _open(response.payload),
    );
    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'pengumuman',
            'Pengumuman Kampus',
            description: 'Notifikasi pengumuman kampus',
            importance: Importance.high,
          ),
        );
    // iOS: hindari duplikasi dengan presentasi manual di onMessage.
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: false,
      sound: false,
    );
    if (_disposed) return;
    _subscriptions.add(
      FirebaseMessaging.onMessage.listen((message) {
        debugPrint('Pesan foreground diterima');
        debugPrint('Data FCM: ${message.data}');

        unawaited(_guard(() => _show(message)));
      }),
    );
    _subscriptions.add(
      FirebaseMessaging.onMessageOpenedApp.listen(
        (message) => _open(message.data['route']),
      ),
    );
    _subscriptions.add(
      _messaging.onTokenRefresh.listen(
        (token) {
          unawaited(_guard(() => _postToken(token)));
        },
        onError: (Object error) {
          debugPrint('FCM token refresh gagal: ${error.runtimeType}');
        },
      ),
    );
    final launch = await _local.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      _open(launch?.notificationResponse?.payload);
    }
    final initial = await _messaging.getInitialMessage();
    if (initial != null) _open(initial.data['route']);
    // Android 13+: dialog runtime POST_NOTIFICATIONS + deklarasi manifest.
    // Android <=12: tidak ada dialog runtime notifikasi.
    // iOS: meminta izin alert/badge/sound melalui APNs.
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;
    await _guard(registerDevice);
    await _guard(subscribeTopic);
  }

  // Panggil ulang setelah login atau koneksi pulih jika registrasi gagal.
  Future<void> registerDevice() async {
    // iOS: token APNs harus tersedia sebelum API token FCM dipanggil.
    if (defaultTargetPlatform == TargetPlatform.iOS &&
        await _messaging.getAPNSToken() == null) {
      throw StateError('Token APNs belum tersedia; ulangi registerDevice.');
    }
    final token = await _messaging.getToken();
    if (token != null) await _postToken(token);
  }

  Future<void> _postToken(String token) async {
    if (_disposed) return;
    final endpoint = Uri.tryParse(devicesApi.options.baseUrl);
    if (endpoint == null ||
        endpoint.scheme != 'https' ||
        endpoint.host.isEmpty) {
      throw StateError(
        'Konfigurasikan DEVICES_API_BASE_URL ke backend kampus HTTPS.',
      );
    }
    // Dio memakai interceptor Authorization dari secure storage.
    // Backend perlu upsert agar registrasi ulang idempotent.
    await devicesApi.post<void>(
      '/devices',
      data: {'token': token, 'platform': defaultTargetPlatform.name},
    );
  }

  Future<void> _show(RemoteMessage message) async {
    if (_disposed) return;
    final title = message.notification?.title ?? message.data['title'];
    final body = message.notification?.body ?? message.data['body'];
    if (title == null && body == null) return;
    await _local.show(
      id: message.hashCode & 0x7fffffff,
      title: title?.toString() ?? 'Pengumuman',
      body: body?.toString(),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'pengumuman',
          'Pengumuman Kampus',
          channelDescription: 'Notifikasi pengumuman kampus',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data['route']?.toString(),
    );
  }

  void _open(Object? value) {
    debugPrint('Payload klik notifikasi: $value');

    if (_disposed || value is! String) {
      debugPrint('Navigasi dibatalkan: payload bukan String');
      return;
    }

    final uri = Uri.tryParse(value);

    if (uri == null ||
        uri.hasScheme ||
        uri.hasAuthority ||
        !(uri.path == '/' ||
            uri.path == '/login' ||
            RegExp(r'^/pengumuman/[^/]+$')
                .hasMatch(uri.path))) {
      debugPrint(
        'Navigasi dibatalkan: route tidak valid',
      );
      return;
    }

    debugPrint(
      'Route valid, navigasi ke: $value',
    );

    go(value);
  }

  Future<void> subscribeTopic() => _messaging.subscribeToTopic(topic);
  Future<void> unsubscribeTopic() => _messaging.unsubscribeFromTopic(topic);

  Future<void> _guard(Future<void> Function() operation) async {
    try {
      await operation();
    } catch (error) {
      // Jangan log token atau header autentikasi.
      debugPrint('Operasi push gagal: ${error.runtimeType}');
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
  }
}
