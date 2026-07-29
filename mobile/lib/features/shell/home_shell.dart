import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/offline_banner.dart';

/// Scaffold hosting the 5 main tabs via a bottom NavigationBar.
///
/// Tabs live in an IndexedStack, so switching one in is otherwise an instant
/// cut. A short fade-and-rise gives the change somewhere to land without
/// costing the state each tab holds.
class HomeShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const HomeShell({super.key, required this.navigationShell});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with SingleTickerProviderStateMixin {
  late final AnimationController _swap = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    value: 1,
  );

  late int _index = widget.navigationShell.currentIndex;

  @override
  void didUpdateWidget(HomeShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final current = widget.navigationShell.currentIndex;
    if (current != _index) {
      _index = current;
      _swap.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _swap.dispose();
    super.dispose();
  }

  void _go(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: AnimatedBuilder(
              animation: _swap,
              // The shell is passed as `child` so the tabs are never rebuilt by
              // the animation — only the wrapper around them.
              child: widget.navigationShell,
              builder: (context, child) {
                // At rest, hand the tab straight through: no opacity layer, no
                // cost.
                if (_swap.isCompleted) return child!;
                final t = Curves.easeOut.transform(_swap.value);
                return Opacity(
                  opacity: t,
                  child: Transform.translate(
                      offset: Offset(0, 10 * (1 - t)), child: child),
                );
              },
            ),
          ),
          // Sits above the tab bar rather than under the title: it is a fact
          // about the whole app, not about the screen you happen to be on.
          const OfflineBanner(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.navigationShell.currentIndex,
        onDestinationSelected: _go,
        height: 64,
        destinations: const [
          _Dest('assets/home.svg', 'Дома'),
          _Dest('assets/invite-alt.svg', 'Консултации'),
          _Dest('assets/test.svg', 'Испити'),
          _Dest('assets/calendar-clock.svg', 'Распоред'),
          _Dest('assets/map-marker.svg', 'Карта'),
        ],
      ),
    );
  }
}

/// A bottom-nav destination whose SVG glyph tints navy when selected and grey
/// otherwise.
class _Dest extends StatelessWidget {
  final String asset;
  final String label;
  const _Dest(this.asset, this.label);

  @override
  Widget build(BuildContext context) {
    return NavigationDestination(
      icon: _NavIcon(asset, AppColors.muted),
      selectedIcon: _NavIcon(asset, AppColors.navy),
      label: label,
    );
  }
}

/// Bottom-nav icon rendered from a bundled SVG asset, tinted to [color].
class _NavIcon extends StatelessWidget {
  final String asset;
  final Color color;
  const _NavIcon(this.asset, this.color);

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      asset,
      width: 24,
      height: 24,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
