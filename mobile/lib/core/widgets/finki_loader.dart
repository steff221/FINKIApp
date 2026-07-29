import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../theme/app_colors.dart';

/// The in-app loading indicator: shown wherever a screen is genuinely waiting
/// on data — a first load, a retry, a pull-to-refresh.
///
/// The animation is a Lottie composition, so it belongs to the design file and
/// can be replaced without touching Dart.
class FinkiLoader extends StatelessWidget {
  final String caption;

  /// Edge of the animation's box — the composition is square.
  final double size;

  const FinkiLoader({super.key, this.caption = 'Се вчитува…', this.size = 130});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Lottie.asset(
          'assets/animations/loading.json',
          width: size,
          height: size,
          fit: BoxFit.contain,
          // Nothing waits on the composition finishing and the loader dies with
          // the screen, so it needs no controller of its own.
          repeat: true,
        ),
        const SizedBox(height: 10),
        Text(caption,
            style: const TextStyle(color: AppColors.faint, fontSize: 13)),
      ],
    );
  }
}
