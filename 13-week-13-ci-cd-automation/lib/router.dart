import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/announcement_page.dart';
import 'features/notes/presentation/pages/notes_page.dart';
import 'features/ai/presentation/pages/ai_assistant_page.dart';
import 'features/ai/presentation/pages/ai_settings_screen.dart';
import 'providers/auth_provider.dart';
import 'routes.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);

  return GoRouter(
    initialLocation: AppRoutes.login,

    redirect: (context, state) {
      if (auth.isLoading) {
        return null;
      }

      final loggedIn = auth.value ?? false;

      final atLogin = state.matchedLocation == AppRoutes.login;

      if (!loggedIn && !atLogin) {
        return AppRoutes.login;
      }

      if (loggedIn && atLogin) {
        return AppRoutes.home;
      }

      return null;
    },

    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) {
          return const LoginPage();
        },
      ),

      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) {
          return const HomePage();
        },
      ),

      GoRoute(
        path: AppRoutes.notes,
        builder: (context, state) {
          return const NotesPage();
        },
      ),

      GoRoute(
        path: AppRoutes.ai,
        builder: (context, state) {
          return const AiAssistantPage();
        },
      ),

      GoRoute(
        path: AppRoutes.aiSettings,
        builder: (context, state) {
          return const AiSettingsPage();
        },
      ),

      GoRoute(
        path: AppRoutes.announcementPattern,
        builder: (context, state) {
          final id = state.pathParameters['id']!;

          return AnnouncementPage(id: id);
        },
      ),
    ],
  );
});
