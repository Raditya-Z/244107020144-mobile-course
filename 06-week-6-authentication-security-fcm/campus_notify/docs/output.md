# Hasil Implementasi PushService

PushService sudah diimplementasikan untuk Flutter Campus Notification App dengan fitur:

- `requestPermission()` dan `getToken()`.
- `onTokenRefresh` mengirim token terbaru ke `POST /devices`.
- `onMessage` menampilkan local notification secara manual.
- `onMessageOpenedApp` dan `getInitialMessage()` melakukan navigasi ke `data.route` melalui callback GoRouter.
- Tap local notification melakukan navigasi melalui payload, termasuk saat aplikasi diluncurkan dari notifikasi.
- Subscribe/unsubscribe topic `pengumuman-kampus`.
- Handler background top-level dengan `@pragma('vm:entry-point')`.
- Pembersihan listener ketika aplikasi dilepas.

## Android 13+ dan iOS

- **Android 13+:** membutuhkan deklarasi `POST_NOTIFICATIONS` di manifest dan permintaan izin saat runtime. Android 12 ke bawah tidak memiliki dialog izin runtime tersebut.
- **Android:** menggunakan notification channel `pengumuman` dengan importance tinggi.
- **iOS:** menggunakan `DarwinInitializationSettings` dan `DarwinNotificationDetails`. Presentasi foreground otomatis FCM dinonaktifkan agar notifikasi manual tidak tampil dua kali.
- **iOS:** token APNs harus tersedia sebelum mengambil token FCM. Aktifkan Push Notifications, Background Modes > Remote notifications, serta konfigurasi APNs key di Firebase.

## Batasan BuildContext

PushService tidak menyimpan atau mengakses `BuildContext`; navigasi menggunakan callback `GoRouter.go`. Handler background tidak boleh mengakses `BuildContext`, ref Riverpod dari UI, atau melakukan navigasi. Pada Android handler berjalan di isolate terpisah; pada iOS tidak memerlukan isolate terpisah, tetapi tetap tidak boleh mengubah UI.

## Konfigurasi backend

Jalankan aplikasi dengan alamat backend kampus yang dipercaya:

```sh
flutter run --dart-define=DEVICES_API_BASE_URL=https://backend-kampus-anda
```

Ganti alamat contoh dengan endpoint HTTPS backend asli. `POST /devices` mengirim JSON berisi `token` dan `platform`, dengan header autentikasi dari TokenStore jika tersedia. Tanpa konfigurasi endpoint HTTPS, token tidak dikirim. Backend perlu mendukung upsert token. Jika registrasi gagal, panggil kembali `registerDevice()` setelah login atau koneksi pulih; belum ada antrean retry persisten.

## Validasi

`flutter analyze` selesai dengan **No issues found**. Pengujian penerimaan FCM, tap notifikasi, refresh token, dan subscribe/unsubscribe pada perangkat Android/iOS masih diperlukan. Konfigurasi signing dan APNs iOS juga perlu diselesaikan menggunakan akun proyek terkait.

Peninjauan otomatis menolak integrasi awal yang dapat mengirim token ke JSONPlaceholder. Implementasi kemudian diperbaiki agar registrasi perangkat hanya menggunakan endpoint HTTPS yang dikonfigurasi secara eksplisit.

Detail penggunaan dan batasan tersedia di [push_service.md](push_service.md).

## Kode lengkap file yang diubah

### lib/messaging/push_service.dart

```dart
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
    if (_disposed || value is! String) return;
    final uri = Uri.tryParse(value);
    if (uri == null ||
        uri.hasScheme ||
        uri.hasAuthority ||
        !(uri.path == '/' ||
            uri.path == '/login' ||
            RegExp(r'^/pengumuman/[^/]+$').hasMatch(uri.path))) {
      return;
    }
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
```

### lib/main.dart

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'router.dart';
import 'messaging/push_service.dart';
import 'data/api_client.dart';
import 'providers/auth_provider.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // TANPA BuildContext/ref/navigasi. Android: isolate terpisah;
  // iOS: tidak memerlukan isolate terpisah, tetap tidak boleh mengubah UI.
  await Firebase.initializeApp();

  debugPrint('Pesan background diterima: ${message.messageId}');

  debugPrint('Data: ${message.data}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  PushService? _pushService;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      _pushService = PushService(
        devicesApi: buildDio(
          tokenStore: ref.read(tokenStoreProvider),
          authRepository: ref.read(authRepositoryProvider),
          baseUrl: const String.fromEnvironment('DEVICES_API_BASE_URL'),
        ),
        go: (route) {
          if (!mounted) return;
          debugPrint('Navigasi ke route: $route');

          ref.read(routerProvider).go(route);
        },
      );

      try {
        await _pushService!.init();
      } catch (error) {
        debugPrint('Inisialisasi push gagal: ${error.runtimeType}');
      }
    });
  }

  @override
  void dispose() {
    final service = _pushService;
    if (service != null) unawaited(service.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Campus Notify',
      routerConfig: router,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
    );
  }
}
```

### lib/data/api_client.dart

```dart
import 'package:dio/dio.dart';

import 'auth_repository.dart';
import 'token_store.dart';

Dio buildDio({
  required TokenStore tokenStore,
  required AuthRepository authRepository,
  String baseUrl = 'https://jsonplaceholder.typicode.com',
}) {
  final dio = Dio(BaseOptions(baseUrl: baseUrl));

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final access = await tokenStore.readAccess();

        if (access != null) {
          options.headers['Authorization'] = 'Bearer $access';
        }

        handler.next(options);
      },

      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final refresh = await tokenStore.readRefresh();

          if (refresh == null) {
            return handler.next(error);
          }

          try {
            final newAccess = await authRepository.refresh(refresh);

            await tokenStore.save(access: newAccess, refresh: refresh);

            final request = error.requestOptions;

            request.headers['Authorization'] = 'Bearer $newAccess';

            final response = await dio.fetch(request);

            return handler.resolve(response);
          } catch (_) {
            await tokenStore.clear();
          }
        }

        handler.next(error);
      },
    ),
  );

  return dio;
}
```

### android/app/src/main/AndroidManifest.xml

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Android 13+: izin ini juga diminta saat runtime. -->
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="android.permission.INTERNET"/>
    <application
        android:label="campus_notify"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:taskAffinity=""
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <!-- Specifies an Android theme to apply to this Activity as soon as
                 the Android process has started. This theme is visible to the user
                 while the Flutter UI initializes. After that, this theme continues
                 to determine the Window background behind the Flutter UI. -->
            <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme"
              />
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        <!-- Don't delete the meta-data below.
             This is used by the Flutter tool to generate GeneratedPluginRegistrant.java -->
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
    <!-- Required to query activities that can process text, see:
         https://developer.android.com/training/package-visibility and
         https://developer.android.com/reference/android/content/Intent#ACTION_PROCESS_TEXT.

         In particular, this is used by the Flutter engine in io.flutter.plugin.text.ProcessTextPlugin. -->
    <queries>
        <intent>
            <action android:name="android.intent.action.PROCESS_TEXT"/>
            <data android:mimeType="text/plain"/>
        </intent>
    </queries>
</manifest>
```

