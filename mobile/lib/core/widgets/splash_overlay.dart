import 'package:flutter/material.dart';

import '../../features/auth/splash_screen.dart';

/// Holds the opening animation over the app while the app builds behind it.
///
/// The splash used to be a route: the dive into the «O» ended, the route
/// changed, and only *then* did Дома start building — a screen with a week's
/// agenda in it. The gap between the two was the navy field the animation left
/// behind, held for as long as the first real frame took. No transition can fix
/// that, because there is nothing to transition to yet.
///
/// Painting it over the app instead inverts the problem. Дома builds, fetches
/// and settles during the three seconds of animation, so when the dive finishes
/// the app is already there — the splash simply stops covering it.
class SplashOverlay extends StatefulWidget {
  final Widget child;

  const SplashOverlay({super.key, required this.child});

  @override
  State<SplashOverlay> createState() => _SplashOverlayState();
}

class _SplashOverlayState extends State<SplashOverlay> {
  /// False once the dive is over and the veil has finished lifting; the splash
  /// is dropped from the tree entirely at that point.
  bool _showSplash = true;
  bool _fading = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_showSplash)
          // The app underneath is live the whole time — the veil has to keep
          // taps off it until it is gone.
          Positioned.fill(
            child: IgnorePointer(
              ignoring: _fading,
              child: AnimatedOpacity(
                opacity: _fading ? 0 : 1,
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOut,
                onEnd: () {
                  if (mounted) setState(() => _showSplash = false);
                },
                child: SplashScreen(
                  onDone: () {
                    if (mounted) setState(() => _fading = true);
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}
