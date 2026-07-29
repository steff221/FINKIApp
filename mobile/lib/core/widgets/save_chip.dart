import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_shape.dart';

/// The +/✓ affordance on browse cards — the one control that says "this is
/// mine". Shared by the timetable slots and the exam list so claiming looks
/// the same wherever it happens.
class SaveChip extends StatelessWidget {
  final bool saved;
  final VoidCallback onTap;

  /// Edge of the visible chip. Class cards carry a slightly smaller one than
  /// exam cards, matching the design.
  final double size;

  const SaveChip({
    super.key,
    required this.saved,
    required this.onTap,
    this.size = 28,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: saved,
      label: saved ? 'Отстрани од распоред' : 'Додај во распоред',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          // Pad the visible chip out to a comfortable tap target.
          padding: const EdgeInsets.all(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: saved ? AppColors.navy : Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.chip),
              // Navy either way: the outline states this is an action, not a
              // disabled slot.
              border: Border.all(color: AppColors.navy),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
              child: Icon(
                saved ? Icons.check_rounded : Icons.add_rounded,
                key: ValueKey(saved),
                size: 16,
                color: saved ? Colors.white : AppColors.navy,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
