import 'package:firebase_messaging/firebase_messaging.dart';

class PushService {
  final FirebaseMessaging _messaging =
      FirebaseMessaging.instance;

  Future<void> init() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print(
      'Notification permission: '
      '${settings.authorizationStatus}',
    );

    final token = await _messaging.getToken();

    print('FCM Token: $token');

    _messaging.onTokenRefresh.listen((newToken) {
      print('FCM Token diperbarui: $newToken');
    });

    await _messaging.subscribeToTopic(
      'pengumuman-kampus',
    );

    print(
      'Berhasil subscribe topic: pengumuman-kampus',
    );
  }
}