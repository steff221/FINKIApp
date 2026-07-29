import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Pull-to-refresh, wearing the brand instead of Material's default blue.
///
/// A wrapper rather than a theme: this Flutter has no `RefreshIndicatorTheme`,
/// and one widget still beats four call sites drifting apart.
class AppRefresh extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;

  const AppRefresh({super.key, required this.onRefresh, required this.child});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.navy,
      backgroundColor: Colors.white,
      strokeWidth: 2.5,
      // Closer to the thumb than the 40pt default: every list here starts just
      // under a header, so the spinner has less room to fall into.
      displacement: 28,
      child: child,
    );
  }
}
