import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_controller.dart';
import '../widgets/page_background.dart';
import '../demo/demo.dart';
import '../providers.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/shell/home_shell.dart';
import '../../features/timetable/timetable_screen.dart';
import '../../features/schedule/schedule_screen.dart';
import '../../features/exams/exams_screen.dart';
import '../../features/consultations/consultations_screen.dart';
import '../../features/map/map_screen.dart';

/// Hands over to a screen by dissolving into it rather than sliding it in.
///
/// The splash ends by diving into the «O» of the logo; a sideways push would
/// show the two screens side by side for the length of the slide, which reads
/// as a glitch rather than as an arrival.
CustomTransitionPage<T> _fadePage<T>(GoRouterState state, Widget child) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  // Bridge Riverpod auth changes to go_router's refresh mechanism.
  final refresh = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    // The app opens on Дома and builds it immediately; the opening animation is
    // painted over the top (see SplashOverlay), so this is what is being made
    // ready while the logo plays.
    initialLocation: '/home',
    refreshListenable: refresh,
    redirect: (context, state) {
      // Presentation build: there is nothing to guard.
      if (kDemoMode) return null;

      final status = ref.read(authControllerProvider).status;
      final loc = state.matchedLocation;

      // Nothing to decide until the token has been read: the splash is still
      // covering the screen, and moving anyone now would only be undone.
      if (status == AuthStatus.unknown) return null;
      final authed = status == AuthStatus.authenticated;
      // Both auth screens are reachable while signed out.
      if (!authed) {
        return (loc == '/login' || loc == '/register') ? null : '/login';
      }
      if (loc == '/login' || loc == '/register') return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        pageBuilder: (_, state) => _fadePage(state, const LoginScreen()),
      ),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      // Мој Распоред lost its tab to Дома, which now shows the same agenda —
      // the screen stays routable and is pushed over the shell.
      // Wrapped for the same reason as the professor page: a route pushed over
      // another one has to be opaque, or both show at once while it slides.
      GoRoute(
        path: '/schedule',
        builder: (_, _) => const PageBackground(child: ScheduleScreen()),
      ),
      StatefulShellRoute.indexedStack(
        pageBuilder: (context, state, navigationShell) =>
            _fadePage(state, HomeShell(navigationShell: navigationShell)),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/consultations',
                builder: (_, _) => const ConsultationsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/exams', builder: (_, _) => const ExamsScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/timetable',
                builder: (_, _) => const TimetableScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/map', builder: (_, _) => const MapScreen()),
            ],
          ),
        ],
      ),
    ],
  );
});
