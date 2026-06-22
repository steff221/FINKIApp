import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Scaffold hosting the 5 main tabs via a bottom NavigationBar.
class HomeShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const HomeShell({super.key, required this.navigationShell});

  void _go(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _go,
        height: 64,
        destinations: const [
          NavigationDestination(icon: _NavIcon('assets/nav_schedule.png'),      label: 'Распоред'),
          NavigationDestination(icon: _NavIcon('assets/nav_consultations.png'), label: 'Консултации'),
          NavigationDestination(icon: _NavIcon('assets/nav_exams.png'),         label: 'Испити'),
          NavigationDestination(icon: _NavIcon('assets/nav_myschedule.png'),    label: 'Мој Распоред'),
          NavigationDestination(icon: _NavIcon('assets/nav_map.png'),           label: 'Карта'),
        ],
      ),
    );
  }
}

/// Bottom-nav icon rendered from a bundled PNG asset.
class _NavIcon extends StatelessWidget {
  final String asset;
  const _NavIcon(this.asset);

  @override
  Widget build(BuildContext context) {
    return Image.asset(asset, width: 24, height: 24, fit: BoxFit.contain);
  }
}
