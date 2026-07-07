import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'finki_ball.dart';

/// Quiet in-app loading indicator: the splash ball in miniature, bouncing on
/// its own shadow. One seamless sine loop — squash on contact, stretch in the
/// air — subtle enough to run forever without re-telling the splash gag.
class FinkiLoader extends StatefulWidget {
  final String caption;
  const FinkiLoader({super.key, this.caption = 'Се вчитува…'});

  @override
  State<FinkiLoader> createState() => _FinkiLoaderState();
}

class _FinkiLoaderState extends State<FinkiLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1050))
    ..repeat();

  static const _ballR = 7.0;
  static const _jump = 26.0;
  static const _air = 0.82; // fraction of the loop spent airborne

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 64,
          height: _jump + _ballR * 2 + 12,
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final t = _c.value;
              double y; // height above the floor
              double squash; // >0 flattens (contact), <0 stretches (airborne)
              if (t < _air) {
                final u = t / _air;
                y = _jump * 4 * u * (1 - u);
                // Stretch follows vertical speed: max at takeoff/landing,
                // relaxed at the top of the arc.
                squash = -0.16 * (1 - 4 * u * (1 - u)).abs();
              } else {
                // Contact: one sine squash pulse, zero at both ends so the
                // loop closes without a seam.
                y = 0;
                squash = 0.55 * math.sin(math.pi * (t - _air) / (1 - _air));
              }

              final hf = 1 - y / _jump; // 1 = grounded
              final contact = squash.clamp(0.0, 1.0);
              // Shadow: tight and dark on the ground, wide and faint in the
              // air — and it spreads with the ball when it squishes.
              final shadowW = _ballR * (3.2 - 1.4 * hf) * (1 + 0.5 * contact);
              final shadowO = 0.10 + 0.20 * hf + 0.14 * contact;

              return Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Positioned(
                    bottom: 0,
                    child: Container(
                      width: shadowW,
                      height: 5,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: Colors.black.withValues(alpha: shadowO),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 6 + y,
                    child: Transform(
                      alignment: Alignment.bottomCenter,
                      transform: Matrix4.diagonal3Values(
                          1 + 0.35 * contact + 0.8 * math.min(squash, 0.0),
                          1 - 0.40 * contact - 0.8 * math.min(squash, 0.0),
                          1),
                      child: FinkiBall(
                        radius: _ballR,
                        shadows: [
                          BoxShadow(
                            color: Colors.black
                                .withValues(alpha: 0.12 + 0.12 * hf),
                            blurRadius: 4 + 6 * (1 - hf),
                            offset: Offset(0, 2 + 3 * (1 - hf)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Text(widget.caption,
            style: const TextStyle(color: AppColors.faint, fontSize: 13)),
      ],
    );
  }
}
