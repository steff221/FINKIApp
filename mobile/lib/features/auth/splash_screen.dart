import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Pixar-style bouncing logo splash screen
//
//  Physics:
//   • Gravity fall    → ease-in curve (accelerates downward)
//   • Bounce rise     → ease-out curve (decelerates upward)
//   • Squash on hit   → scaleY shrinks, scaleX grows (bottomCenter pivot)
//   • Stretch in air  → scaleY grows slightly, scaleX narrows
//   • Ground shadow   → ellipse grows wider/lighter when logo is high
//   • 3 diminishing bounces (damping ratio ≈ 0.38)
//   • After settle: title slides up, subtitle fades, dots appear
//
//  Hand-off:
//   • Brief anticipation (text fades, logo dips), then the logo's circle
//     expands into a portal that reveals the destination screen growing
//     out of it (circular reveal centered on the logo).
// ─────────────────────────────────────────────────────────────────────────────

const _logoSize = 100.0;

// Bounce heights (px above rest)
const _h0 = 380.0; // initial drop
const _h1 = 155.0; // first bounce  (~0.41 × h0)
const _h2 = 62.0;  // second bounce (~0.40 × h1)
const _h3 = 22.0;  // third micro-bounce

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  // Main bounce controller – drives posY, scaleX, scaleY
  late final AnimationController _bounce;
  late final Animation<double> _posY;
  late final Animation<double> _scaleX;
  late final Animation<double> _scaleY;

  // Shadow
  late final Animation<double> _shadowW;
  late final Animation<double> _shadowO;

  // Post-settle: text + dots
  late final AnimationController _text;
  late final Animation<double> _titleOpacity;
  late final Animation<double> _titleY;
  late final Animation<double> _subOpacity;

  late final AnimationController _dots;

  // Anticipation before the reveal (fades text, dips the logo)
  late final AnimationController _exit;

  // Measures the logo so the reveal originates exactly on it
  final GlobalKey _logoKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    // ── Timing weights (must sum to 100) ─────────────────────────────────────
    // Each weight = proportion of total 2100 ms
    //  w0  fall 0           28  →  588 ms
    //  w1  squash 1          4  →   84 ms
    //  w2  rise 1           12  →  252 ms
    //  w3  fall 1           12  →  252 ms
    //  w4  squash 2          3  →   63 ms
    //  w5  rise 2            8  →  168 ms
    //  w6  fall 2            8  →  168 ms
    //  w7  squash 3          2  →   42 ms
    //  w8  settle           23  →  483 ms
    // ─────────────────────────────────────────────────────────────────────────

    _bounce = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2100));

    // ── Vertical position (Y offset; 0 = resting on "floor") ────────────────
    _posY = TweenSequence<double>([
      // 0 – initial free-fall (ease-in = gravity)
      TweenSequenceItem(
          tween: Tween(begin: -_h0, end: 0.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 28),
      // 1 – first squash (stay at 0)
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.0), weight: 4),
      // 2 – rise after 1st bounce (ease-out = decelerates)
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: -_h1)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 12),
      // 3 – fall back (ease-in)
      TweenSequenceItem(
          tween: Tween(begin: -_h1, end: 0.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 12),
      // 4 – second squash
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.0), weight: 3),
      // 5 – rise after 2nd bounce
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: -_h2)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 8),
      // 6 – fall back
      TweenSequenceItem(
          tween: Tween(begin: -_h2, end: 0.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 8),
      // 7 – micro squash
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.0), weight: 2),
      // 8 – micro bounce + elastic settle
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: -_h3)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 8),
      TweenSequenceItem(
          tween: Tween(begin: -_h3, end: 0.0)
              .chain(CurveTween(curve: Curves.elasticOut)),
          weight: 15),
    ]).animate(_bounce);

    // ── Scale Y: squash on impact, stretch in air ────────────────────────────
    // Uses Alignment.bottomCenter so the logo's base stays grounded
    _scaleY = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.18), weight: 28), // fall stretch
      TweenSequenceItem(tween: Tween(begin: 0.58, end: 0.58), weight: 4),  // squash 1
      TweenSequenceItem(tween: Tween(begin: 1.22, end: 1.0),  weight: 12), // rise stretch
      TweenSequenceItem(tween: Tween(begin: 1.0,  end: 1.12), weight: 12), // fall stretch
      TweenSequenceItem(tween: Tween(begin: 0.74, end: 0.74), weight: 3),  // squash 2
      TweenSequenceItem(tween: Tween(begin: 1.14, end: 1.0),  weight: 8),  // rise
      TweenSequenceItem(tween: Tween(begin: 1.0,  end: 1.06), weight: 8),  // fall
      TweenSequenceItem(tween: Tween(begin: 0.88, end: 0.88), weight: 2),  // micro squash
      TweenSequenceItem(tween: Tween(begin: 1.06, end: 1.0),  weight: 8),  // micro rise
      TweenSequenceItem(
          tween: Tween(begin: 0.95, end: 1.0)
              .chain(CurveTween(curve: Curves.elasticOut)),
          weight: 15),
    ]).animate(_bounce);

    // ── Scale X: inverse of Y (conservation of volume) ───────────────────────
    _scaleX = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.96, end: 0.88), weight: 28),
      TweenSequenceItem(tween: Tween(begin: 1.52, end: 1.52), weight: 4),  // squash 1
      TweenSequenceItem(tween: Tween(begin: 0.84, end: 1.0),  weight: 12),
      TweenSequenceItem(tween: Tween(begin: 1.0,  end: 0.91), weight: 12),
      TweenSequenceItem(tween: Tween(begin: 1.30, end: 1.30), weight: 3),  // squash 2
      TweenSequenceItem(tween: Tween(begin: 0.90, end: 1.0),  weight: 8),
      TweenSequenceItem(tween: Tween(begin: 1.0,  end: 0.95), weight: 8),
      TweenSequenceItem(tween: Tween(begin: 1.10, end: 1.10), weight: 2),  // micro squash
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0),  weight: 8),
      TweenSequenceItem(
          tween: Tween(begin: 1.04, end: 1.0)
              .chain(CurveTween(curve: Curves.elasticOut)),
          weight: 15),
    ]).animate(_bounce);

    // ── Shadow width (grows when logo is far from ground) ────────────────────
    _shadowW = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 20.0, end: 64.0), weight: 28), // fall
      TweenSequenceItem(tween: Tween(begin: 64.0, end: 64.0), weight: 4),  // squash
      TweenSequenceItem(tween: Tween(begin: 64.0, end: 26.0), weight: 12),
      TweenSequenceItem(tween: Tween(begin: 26.0, end: 64.0), weight: 12),
      TweenSequenceItem(tween: Tween(begin: 64.0, end: 64.0), weight: 3),
      TweenSequenceItem(tween: Tween(begin: 64.0, end: 44.0), weight: 8),
      TweenSequenceItem(tween: Tween(begin: 44.0, end: 64.0), weight: 8),
      TweenSequenceItem(tween: Tween(begin: 64.0, end: 64.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 64.0, end: 56.0), weight: 8),
      TweenSequenceItem(tween: Tween(begin: 56.0, end: 64.0), weight: 15),
    ]).animate(_bounce);

    _shadowO = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0,  end: 0.55), weight: 28),
      TweenSequenceItem(tween: Tween(begin: 0.55, end: 0.55), weight: 4),
      TweenSequenceItem(tween: Tween(begin: 0.55, end: 0.15), weight: 12),
      TweenSequenceItem(tween: Tween(begin: 0.15, end: 0.55), weight: 12),
      TweenSequenceItem(tween: Tween(begin: 0.55, end: 0.55), weight: 3),
      TweenSequenceItem(tween: Tween(begin: 0.55, end: 0.28), weight: 8),
      TweenSequenceItem(tween: Tween(begin: 0.28, end: 0.55), weight: 8),
      TweenSequenceItem(tween: Tween(begin: 0.55, end: 0.55), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.55, end: 0.42), weight: 8),
      TweenSequenceItem(tween: Tween(begin: 0.42, end: 0.55), weight: 15),
    ]).animate(_bounce);

    // ── Text (slides up after bounce settles) ────────────────────────────────
    _text = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550));
    _titleOpacity = CurvedAnimation(parent: _text, curve: Curves.easeOut)
        .drive(Tween(begin: 0.0, end: 1.0));
    _titleY = CurvedAnimation(parent: _text, curve: Curves.easeOut)
        .drive(Tween(begin: 18.0, end: 0.0));
    _subOpacity = CurvedAnimation(
            parent: _text,
            curve: const Interval(0.4, 1.0, curve: Curves.easeOut))
        .drive(Tween(begin: 0.0, end: 1.0));

    // ── Dots ──────────────────────────────────────────────────────────────────
    _dots = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();

    // ── Anticipation (text fades out, logo dips ~15%) ────────────────────────
    _exit = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 260));

    // ── Sequence ──────────────────────────────────────────────────────────────
    _bounce.forward().then((_) async {
      await _text.forward().orCancel;
      // Brief hold so the dots are visible before we leave.
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      var status = ref.read(authControllerProvider).status;
      // If auth check is still in progress, wait up to 2 s more.
      if (status == AuthStatus.unknown) {
        await Future.delayed(const Duration(milliseconds: 2000));
      }
      if (!mounted) return;
      status = ref.read(authControllerProvider).status;
      final destination =
          status == AuthStatus.authenticated ? '/timetable' : '/login';

      // Anticipation, then the circular "O" reveal hands off to the app.
      await _exit.forward().orCancel;
      if (!mounted) return;
      _startReveal(destination);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });
  }

  /// Navigates to [destination] and overlays a circular reveal, centered on the
  /// logo, that wipes the splash away to expose the destination beneath it.
  void _startReveal(String destination) {
    final box = _logoKey.currentContext?.findRenderObject() as RenderBox?;
    final size = MediaQuery.of(context).size;
    final center = (box != null && box.hasSize)
        ? box.localToGlobal(box.size.center(Offset.zero))
        : size.center(Offset.zero);

    final overlay = Overlay.of(context, rootOverlay: true);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _RevealTransition(
        center: center,
        onDone: () => entry.remove(),
      ),
    );

    // Reveal the destination underneath, then play the wipe on top of it.
    context.go(destination);
    overlay.insert(entry);
  }

  @override
  void dispose() {
    _bounce.dispose();
    _text.dispose();
    _dots.dispose();
    _exit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Logo + shadow stacked ─────────────────────────────────────────
            SizedBox(
              height: _logoSize + _h0 + 24,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // Ground shadow (fades out during the anticipation)
                  Positioned(
                    bottom: 0,
                    child: AnimatedBuilder(
                      animation: Listenable.merge([_bounce, _exit]),
                      builder: (_, _) => Container(
                        width: _shadowW.value,
                        height: 10,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: Colors.black.withValues(
                              alpha: _shadowO.value * 0.45 * (1 - _exit.value)),
                        ),
                      ),
                    ),
                  ),
                  // Bouncing logo (bottomCenter pivot for proper squash)
                  Positioned(
                    bottom: 10, // sits just above the shadow
                    child: AnimatedBuilder(
                      animation: Listenable.merge([_bounce, _exit]),
                      builder: (_, _) {
                        final dip = 1.0 - 0.15 * _exit.value; // anticipation dip
                        return Transform.translate(
                          offset: Offset(0, _posY.value),
                          child: Transform(
                            alignment: Alignment.bottomCenter,
                            transform: Matrix4.diagonal3Values(
                                _scaleX.value * dip, _scaleY.value * dip, 1.0),
                            child: Image.asset(
                              'assets/finki_logo.png',
                              key: _logoKey,
                              width: _logoSize,
                              height: _logoSize,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Title ─────────────────────────────────────────────────────────
            AnimatedBuilder(
              animation: Listenable.merge([_text, _exit]),
              builder: (_, _) => Opacity(
                opacity: _titleOpacity.value * (1 - _exit.value),
                child: Transform.translate(
                  offset: Offset(0, _titleY.value),
                  child: const Text(
                    'ФИНКИ Распоред',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 6),

            // ── Subtitle ──────────────────────────────────────────────────────
            AnimatedBuilder(
              animation: Listenable.merge([_text, _exit]),
              builder: (_, _) => Opacity(
                opacity: _subOpacity.value * (1 - _exit.value),
                child: Text(
                  'Распоред за студенти на ФИНКИ',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13.5,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 64),

            // ── Bouncing dots (appear after logo settles, fade out on exit) ───
            AnimatedBuilder(
              animation: Listenable.merge([_bounce, _dots, _exit]),
              builder: (_, _) => AnimatedOpacity(
                opacity: _bounce.isCompleted ? (1.0 - _exit.value) : 0.0,
                duration: const Duration(milliseconds: 300),
                child: _BouncingDots(progress: _dots.value),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Circular reveal hand-off
//
//  A navy layer with a growing circular "hole" centred on the logo. As the hole
//  expands, the destination screen (already mounted beneath) is revealed; the
//  logo blooms and fades so it reads as the logo opening up into the app.
// ─────────────────────────────────────────────────────────────────────────────
class _RevealTransition extends StatefulWidget {
  final Offset center;
  final VoidCallback onDone;
  const _RevealTransition({required this.center, required this.onDone});

  @override
  State<_RevealTransition> createState() => _RevealTransitionState();
}

class _RevealTransitionState extends State<_RevealTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 720))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) widget.onDone();
      })
      ..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _maxRadius(Offset c, Size s) {
    final dx = math.max(c.dx, s.width - c.dx);
    final dy = math.max(c.dy, s.height - c.dy);
    return math.sqrt(dx * dx + dy * dy) + 8;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final maxR = _maxRadius(widget.center, size);
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) {
          final t = _c.value;
          final radius = Curves.easeInOutCubic.transform(t) * maxR;
          // Logo blooms + fades over the first ~45% of the wipe.
          final bloom = Curves.easeOut.transform((t / 0.45).clamp(0.0, 1.0));
          return Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _HolePainter(
                    center: widget.center,
                    radius: radius,
                    color: AppColors.navy,
                  ),
                ),
              ),
              Positioned(
                left: widget.center.dx - _logoSize / 2,
                top: widget.center.dy - _logoSize / 2,
                child: Opacity(
                  opacity: 1.0 - bloom,
                  child: Transform.scale(
                    scale: 0.85 + 0.95 * bloom,
                    child: Image.asset(
                      'assets/finki_logo.png',
                      width: _logoSize,
                      height: _logoSize,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HolePainter extends CustomPainter {
  final Offset center;
  final double radius;
  final Color color;
  _HolePainter(
      {required this.center, required this.radius, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRect(Offset.zero & size)
      ..addOval(Rect.fromCircle(center: center, radius: radius))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_HolePainter old) =>
      old.radius != radius || old.center != center || old.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
class _BouncingDots extends StatelessWidget {
  final double progress;
  const _BouncingDots({required this.progress});

  double _pulse(double t) => t < 0.5 ? t * 2 : (1.0 - t) * 2;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final phase = ((progress - i / 3.0) % 1.0 + 1.0) % 1.0;
        final p = _pulse(phase);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Opacity(
            opacity: 0.3 + 0.7 * p,
            child: Transform.translate(
              offset: Offset(0, -7 * p),
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
