import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'providers/auth_provider.dart';
import 'pages/announcement_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',

    redirect: (context, state) {
      if (auth.isLoading) {
        return null;
      }

      final loggedIn = auth.value ?? false;
      final atLogin = state.matchedLocation == '/login';

      if (!loggedIn && !atLogin) {
        return '/login';
      }

      if (loggedIn && atLogin) {
        return '/';
      }

      return null;
    },

    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) {
          return const LoginPage();
        },
      ),

      GoRoute(
        path: '/',
        builder: (context, state) {
          return const HomePage();
        },
      ),

      GoRoute(
        path: '/pengumuman/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;

          return AnnouncementPage(
            id: id,
          );
        },
      ),
    ],
  );
});