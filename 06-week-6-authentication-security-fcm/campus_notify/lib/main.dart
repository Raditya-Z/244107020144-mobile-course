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
