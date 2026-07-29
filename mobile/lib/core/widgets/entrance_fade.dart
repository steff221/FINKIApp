import 'dart:async';

import 'package:flutter/material.dart';

/// Fade + slide-up entrance used to stagger list items into view.
///
/// Pass a per-item [delayMs] (e.g. `(row * 70 + col * 45).clamp(0, 420)`) so a
/// list reveals in a gentle cascade rather than all at once.
class Entrance extends StatefulWidget {
  final int delayMs;
  final Widget child;
  const Entrance({super.key, required this.delayMs, required this.child});

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 320));
  late final Animation<double> _a = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
  Timer? _delay;

  @override
  void initState() {
    super.initState();
    _delay = Timer(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _delay?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      builder: (context, child) => Opacity(
        opacity: _a.value,
        child: Transform.translate(offset: Offset(0, 18 * (1 - _a.value)), child: child),
      ),
      child: widget.child,
    );
  }
}
