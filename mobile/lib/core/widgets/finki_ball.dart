import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The FINKI bouncing ball, shaded like a glossy 3-D sphere:
///  • strong key light from the top-left (lit crown → deep occluded rim)
///  • a soft specular hot-spot where the light hits
///  • a faint ground-bounce fill along the bottom edge
/// Shared by the splash intro and [FinkiLoader] so the ball always matches.
class FinkiBall extends StatelessWidget {
  final double radius;
  final List<BoxShadow>? shadows;
  const FinkiBall({super.key, required this.radius, this.shadows});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.38, -0.52),
          radius: 1.3,
          colors: [
            Color(0xFFE8F3FF), // lit crown
            Color(0xFF8CC2FF),
            AppColors.bright, // mid tone
            Color(0xFF0B57C2),
            Color(0xFF063577), // occluded rim
          ],
          stops: [0.0, 0.24, 0.5, 0.78, 1.0],
        ),
        boxShadow: shadows,
      ),
      child: ClipOval(
        child: Stack(
          children: [
            // Specular hot-spot.
            Align(
              alignment: const Alignment(-0.52, -0.62),
              child: Container(
                width: radius * 0.7,
                height: radius * 0.7,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0xD9FFFFFF), Color(0x00FFFFFF)],
                  ),
                ),
              ),
            ),
            // Ground-bounce fill: light reflected up off the floor.
            Positioned(
              left: radius * 0.35,
              right: radius * 0.35,
              bottom: -radius * 0.45,
              height: radius * 0.9,
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0x552F8BFF), Color(0x002F8BFF)],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
