import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';

/// One faintly printed mark on the page.
class _Mark {
  final String asset;

  /// Position of the mark's centre, as a fraction of the page.
  final double fx;
  final double fy;

  final double size;
  final double alpha;

  const _Mark(this.asset,
      {required this.fx, required this.fy, required this.size, required this.alpha});
}

/// The tools of the trade, scattered down the page.
///
/// They grow and firm up toward the bottom, which is what stops the pattern
/// reading as a tiled texture — the eye follows it down rather than across.
const _marks = <_Mark>[
  _Mark('assets/excercice.svg', fx: 0.70, fy: 0.47, size: 22, alpha: 0.05),
  _Mark('assets/swift.svg', fx: 0.26, fy: 0.53, size: 21, alpha: 0.05),
  _Mark('assets/postgre.svg', fx: 0.97, fy: 0.57, size: 28, alpha: 0.06),
  _Mark('assets/atom.svg', fx: 0.58, fy: 0.62, size: 24, alpha: 0.06),
  _Mark('assets/database-management.svg', fx: 0.15, fy: 0.72, size: 34, alpha: 0.08),
  _Mark('assets/atom.svg', fx: 0.94, fy: 0.76, size: 31, alpha: 0.08),
  _Mark('assets/swift.svg', fx: 0.45, fy: 0.83, size: 34, alpha: 0.09),
  _Mark('assets/postgre.svg', fx: 0.13, fy: 0.89, size: 48, alpha: 0.10),
  _Mark('assets/excercice.svg', fx: 0.84, fy: 0.95, size: 42, alpha: 0.10),
];

const _campusAsset = 'assets/images/campus_header_overlay.png';

/// Decodes everything the background paints, so the first screen after the
/// splash does not pay for it on the frame it appears.
///
/// The campus PNG is the expensive one — decoding it while a transition is
/// running is enough to drop frames on the arrival.
Future<void> precachePageBackground(BuildContext context) async {
  await precacheImage(const AssetImage(_campusAsset), context);
  for (final asset in {for (final mark in _marks) mark.asset}) {
    final loader = SvgAssetLoader(asset);
    await svg.cache.putIfAbsent(loader.cacheKey(null), () => loader.loadBytes(null));
  }
}

/// The page every screen is drawn on: the campus at the top, fading out into a
/// wash that deepens toward the bottom, with the marks scattered through it.
///
/// Wrapped around the whole router rather than applied screen by screen, so the
/// background is continuous — it does not restart when you change tab.
class PageBackground extends StatelessWidget {
  final Widget child;

  const PageBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, AppColors.canvas, AppColors.wash],
          stops: [0.0, 0.42, 1.0],
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: _Campus()),
          const Positioned.fill(child: _Marks()),
          child,
        ],
      ),
    );
  }
}

/// The campus photo across the top. The PNG carries both its intensity and its
/// vertical fade in the alpha channel, so it needs no scrim and no extra
/// dimming — srcIn only swaps the slate RGB for the app's grey. Anything less
/// than full strength here and the building disappears entirely.
class _Campus extends StatelessWidget {
  const _Campus();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: Alignment.topCenter,
        child: Image.asset(
          _campusAsset,
          height: MediaQuery.of(context).padding.top + 300,
          width: double.infinity,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          filterQuality: FilterQuality.medium,
          excludeFromSemantics: true,
          color: AppColors.muted,
          colorBlendMode: BlendMode.srcIn,
        ),
      ),
    );
  }
}

class _Marks extends StatelessWidget {
  const _Marks();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) => ClipRect(
          child: Stack(
            children: [
              for (final mark in _marks)
                Positioned(
                  left: constraints.maxWidth * mark.fx - mark.size / 2,
                  top: constraints.maxHeight * mark.fy - mark.size / 2,
                  child: SvgPicture.asset(
                    mark.asset,
                    width: mark.size,
                    height: mark.size,
                    excludeFromSemantics: true,
                    // The alpha rides on the tint rather than on an Opacity
                    // layer, so the pattern costs no extra compositing.
                    colorFilter: ColorFilter.mode(
                      AppColors.navy.withValues(alpha: mark.alpha),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
