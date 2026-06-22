import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_controller.dart';
import '../providers.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/splash_screen.dart';
import '../../features/shell/home_shell.dart';
import '../../features/timetable/timetable_screen.dart';
import '../../features/schedule/schedule_screen.dart';
import '../../features/exams/exams_screen.dart';
import '../../features/consultations/consultations_screen.dart';
import '../../features/map/map_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Bridge Riverpod auth changes to go_router's refresh mechanism.
  final refresh = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final status = ref.read(authControllerProvider).status;
      final loc = state.matchedLocation;

      // Splash drives its own navigation — never redirect away from it.
      if (loc == '/splash') return null;

      if (status == AuthStatus.unknown) return '/splash';
      final authed = status == AuthStatus.authenticated;
      if (!authed) return loc == '/login' ? null : '/login';
      if (loc == '/login') return '/timetable';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/timetable', builder: (_, _) => const TimetableScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/consultations', builder: (_, _) => const ConsultationsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/exams', builder: (_, _) => const ExamsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/schedule', builder: (_, _) => const ScheduleScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/map', builder: (_, _) => const MapScreen()),
          ]),
        ],
      ),
    ],
  );
});
