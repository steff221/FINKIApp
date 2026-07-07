import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/finki_ball.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Pixar-opening splash, in three acts:
//   1. The «O» ball free-falls onto «Ф», hops once onto every letter of
//      «ФИНКИ» (squash & stretch all the way), then settles on the last «И»
//      with diminishing bounces, flattening it.
//   2. The letters collapse into the centre while the ball glides and grows
//      into the «O» of the FINKI logo — the word becomes the logo.
//   3. Once auth resolves, the camera zooms into the «O» to enter the app.
// ─────────────────────────────────────────────────────────────────────────────

const _letters = ['F', 'I', 'N', 'K', 'I'];
const _letterW = 42.0;
const _letterH = 54.0;
const _ballR = 13.0;
const _stageH = 300.0; // fall height above the letters
const _rowW = _letterW * 5;

// Logo geometry (finki_logo.png rendered at 100×100, bottom-centred on the
// stage): the «O» ring is on the right of the mark.
const _logoSize = 100.0;
const _logoLeft = _rowW / 2 - _logoSize / 2;
const _oCenterX = _logoLeft + _logoSize * 0.66;
const _oCenterY = _logoSize * 0.5; // measured from stage bottom
const _oRadius = 27.0;

// ── Intro timeline fractions (3600 ms) ──────────────────────────────────────
const _fallEnd = 0.14;
const _hopDur = 0.09;
const _hopsEnd = _fallEnd + 4 * _hopDur; // 0.50 — landed on the last «И»
const _pancakeDur = 0.06; // the «И» crushes under the ball's weight
const _settleBounces = [
  [0.56, 0.64, 18.0],
  [0.64, 0.70, 8.0],
  [0.70, 0.75, 3.5],
];
const _collapseStart = 0.80; // letters → logo

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _intro; // acts 1–2, plays once
  late final AnimationController _zoom; // act 3: dive into the «O»

  @override
  void initState() {
    super.initState();

    _intro = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3600));
    _zoom = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550));

    _intro.forward().then((_) => _leaveWhenReady());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });
  }

  Future<void> _leaveWhenReady() async {
    // Hold on the formed logo until the auth check resolves (max ~3 s).
    for (var waited = 0;
        waited < 3000 && ref.read(authControllerProvider).status == AuthStatus.unknown;
        waited += 100) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
    }
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    await _zoom.forward().orCancel;
    if (!mounted) return;
    final status = ref.read(authControllerProvider).status;
    context.go(status == AuthStatus.authenticated ? '/timetable' : '/login');
  }

  @override
  void dispose() {
    _intro.dispose();
    _zoom.dispose();
    super.dispose();
  }

  double _letterX(int i) => i * _letterW + _letterW / 2;

  /// Smooth squash pulse (0..1) peaking just after [land]: snaps in fast,
  /// recovers slow — reads springier than a symmetric sine.
  double _pulse(double t, double land, double width) {
    final d = t - land;
    if (d < 0 || d > width) return 0;
    final p = d / width;
    return p < 0.3 ? math.sin(math.pi * p / 0.6) : math.sin(math.pi * (0.5 + (p - 0.3) / 1.4));
  }

  double _landTime(int i) => i == 0 ? _fallEnd : _fallEnd + i * _hopDur;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([_intro, _zoom]),
          builder: (context, _) {
            final t = _intro.value;
            // Eased sub-progress for the collapse (act 2).
            final collapse = t < _collapseStart
                ? 0.0
                : Curves.easeInOutCubic
                    .transform((t - _collapseStart) / (1 - _collapseStart));

            // ── Act 1: ball position + squash & stretch ────────────────────
            double bx, by;
            double squash = 0; // >0 flattens, <0 stretches (airborne)

            if (t < _fallEnd) {
              final s = t / _fallEnd;
              bx = _letterX(0);
              by = _letterH + (_stageH - 60 - _letterH) * (1 - s * s);
              squash = -0.22 * s; // stretches as it speeds up
            } else if (t < _hopsEnd) {
              final hop = math.min(((t - _fallEnd) / _hopDur).floor(), 3);
              final s = (t - _fallEnd - hop * _hopDur) / _hopDur;
              bx = _letterX(hop) + (_letterX(hop + 1) - _letterX(hop)) * s;
              final arcH = 44.0 - hop * 3;
              by = _letterH + arcH * 4 * s * (1 - s);
              // Stretch follows vertical speed: max at takeoff/landing,
              // relaxed at the top of the arc.
              squash = -0.20 * (1 - 4 * s * (1 - s)).abs();
              for (var i = 0; i < 5; i++) {
                squash = math.max(squash, 0.9 * _pulse(t, _landTime(i), 0.06));
              }
            } else {
              bx = _letterX(4);
              // The «И» crushes under the ball's weight: the ball rides the
              // collapsing letter down instead of teleporting to the floor.
              final crush = Curves.easeOutCubic
                  .transform(((t - _hopsEnd) / _pancakeDur).clamp(0.0, 1.0));
              double bounce = 0;
              for (final b in _settleBounces) {
                if (t >= b[0] && t < b[1]) {
                  final p = (t - b[0]) / (b[1] - b[0]);
                  bounce = b[2] * 4 * p * (1 - p);
                }
                squash = math.max(squash, 0.8 * _pulse(t, b[1], 0.05));
              }
              // The big touchdown squish that flattens the letter.
              squash = math.max(squash, _pulse(t, _hopsEnd, 0.07));
              by = _letterH * (1 - 0.95 * crush) + bounce;
            }

            // ── Act 2: glide into the logo's «O» ───────────────────────────
            final ballR = _ballR + (_oRadius - _ballR) * collapse;
            if (collapse > 0) {
              bx = bx + (_oCenterX - bx) * collapse;
              final targetBottom = _oCenterY - _oRadius;
              by = by + (targetBottom - by) * collapse;
              squash *= (1 - collapse);
            }
            final ballOpacity = collapse < 0.75
                ? 1.0
                : 1.0 - Curves.easeIn.transform((collapse - 0.75) / 0.25);
            final logoOpacity = collapse < 0.6
                ? 0.0
                : Curves.easeOut.transform((collapse - 0.6) / 0.4);

            // Title fades in while the ball settles, out as the word morphs.
            final titleIn = ((t - 0.56) / 0.16).clamp(0.0, 1.0);
            final titleOut = 1 - collapse;
            final titleOpacity = titleIn * titleOut;

            // ── Act 3: zoom into the «O» ───────────────────────────────────
            final z = Curves.easeInCubic.transform(_zoom.value);
            final scale = 1 + 30 * z;
            final fade = z < 0.8 ? 1.0 : 1 - (z - 0.8) / 0.2;
            // Alignment of the «O» centre within the stage box.
            final oAlign = Alignment(
              (_oCenterX / _rowW) * 2 - 1,
              ((_stageH - _oCenterY) / _stageH) * 2 - 1,
            );

            // Ground shadow under the ball: wide and faint when the ball is
            // high, tight and dark when it lands — and when the ball squishes
            // it spreads sideways, so the shadow widens and deepens with it.
            final ballHeight = (by - _letterH * 0.5).clamp(0.0, _stageH - 60);
            final hf = 1 - (ballHeight / (_stageH - 60)); // 1 = grounded
            final contact = squash.clamp(0.0, 1.0);
            final shadowW = ballR * (3.4 - 1.6 * hf) * (1 + 0.5 * contact);
            final shadowOpacity =
                ((0.12 + 0.32 * hf) + 0.22 * contact) * (1 - collapse);

            return Opacity(
              opacity: fade,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: scale,
                    alignment: oAlign,
                    child: SizedBox(
                      width: _rowW,
                      height: _stageH,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.bottomLeft,
                        children: [
                          // Ball's ground shadow, cast on the baseline.
                          Positioned(
                            left: bx - shadowW / 2,
                            bottom: -7,
                            child: Container(
                              width: shadowW,
                              height: 7,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                color: Colors.black
                                    .withValues(alpha: shadowOpacity),
                              ),
                            ),
                          ),
                          // Letters — collapse toward the centre in act 2.
                          Positioned(
                            bottom: 0,
                            left: 0,
                            child: Row(
                              children: [
                                for (var i = 0; i < 5; i++)
                                  _letter(i, t, collapse),
                              ],
                            ),
                          ),
                          // The FINKI logo the word collapses into.
                          if (logoOpacity > 0)
                            Positioned(
                              left: _logoLeft,
                              bottom: 0,
                              child: Opacity(
                                opacity: logoOpacity,
                                child: Image.asset(
                                  'assets/finki_logo.png',
                                  width: _logoSize,
                                  height: _logoSize,
                                ),
                              ),
                            ),
                          // The ball.
                          if (ballOpacity > 0)
                            Positioned(
                              left: bx - ballR,
                              bottom: by,
                              child: Opacity(
                                opacity: ballOpacity,
                                child: Transform(
                                  alignment: Alignment.bottomCenter,
                                  // squash > 0 flattens (wide + short);
                                  // squash < 0 stretches (narrow + tall).
                                  transform: Matrix4.diagonal3Values(
                                      1 + 0.32 * contact +
                                          0.7 * math.min(squash, 0.0),
                                      1 - 0.38 * contact -
                                          0.7 * math.min(squash, 0.0),
                                      1),
                                  child: FinkiBall(
                                    radius: ballR,
                                    // Drop shadow separates in the air and
                                    // hugs the ball tight on contact.
                                    shadows: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                            alpha: 0.20 + 0.14 * hf),
                                        blurRadius: 5 + 11 * (1 - hf),
                                        offset: Offset(0, 3 + 6 * (1 - hf)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  // Title + subtitle live outside the zoomed stage and fade
                  // away before the dive.
                  if (_zoom.value == 0) ...[
                    const SizedBox(height: 26),
                    Opacity(
                      opacity: titleOpacity,
                      child: Transform.translate(
                        offset: Offset(0, 14 * (1 - titleIn)),
                        child: Text(
                          'ФИНКИ Распоред',
                          style: GoogleFonts.rubik(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Opacity(
                      opacity: titleOpacity * 0.8,
                      child: Text(
                        'Распоред за студенти на ФИНКИ',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _letter(int i, double t, double collapse) {
    // Landing dip, plus the last «И» crushes flat under the resting ball —
    // eased over _pancakeDur so it collapses instead of snapping.
    double squash = 0.35 * _pulse(t, _landTime(i), 0.07);
    if (i == 4 && t >= _hopsEnd) {
      final crush = Curves.easeOutCubic
          .transform(((t - _hopsEnd) / _pancakeDur).clamp(0.0, 1.0));
      squash = math.max(squash, 0.95 * crush);
    }

    // Act 2: converge on the centre of the word and vanish.
    final toCenter = (_rowW / 2 - _letterX(i)) * collapse;
    final scale = 1 - collapse;

    return SizedBox(
      width: _letterW,
      height: _letterH,
      child: Transform.translate(
        offset: Offset(toCenter, 0),
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.bottomCenter,
          child: Transform(
            alignment: Alignment.bottomCenter,
            transform: Matrix4.diagonal3Values(1 + 0.2 * squash, 1 - squash, 1),
            child: Opacity(
              opacity: 1 - collapse,
              child: Text(
                _letters[i],
                textAlign: TextAlign.center,
                style: GoogleFonts.rubik(
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  shadows: [
                    const Shadow(
                      color: Color(0x59000000),
                      blurRadius: 14,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
