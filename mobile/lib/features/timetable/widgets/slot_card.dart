import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/lesson_type.dart';
import '../../../models/models.dart';
import '../timetable_providers.dart';
import 'slot_details_sheet.dart';

/// Compact, scannable card: time, title, type + room. Everything else
/// (teachers, groups) lives in the tap-through details sheet.
class SlotCard extends ConsumerStatefulWidget {
  final ScheduleSlot slot;
  const SlotCard({super.key, required this.slot});

  @override
  ConsumerState<SlotCard> createState() => _SlotCardState();
}

class _SlotCardState extends ConsumerState<SlotCard> {
  bool _pressed = false;

  ScheduleSlot get slot => widget.slot;

  @override
  Widget build(BuildContext context) {
    final style = lessonTypeStyle(slot.subject.lessonType);
    final saved = ref.watch(savedSlotsProvider).contains(slot.id);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        HapticFeedback.selectionClick();
        showSlotDetailsSheet(context, slot);
      },
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border(left: BorderSide(color: style.accent, width: 4)),
          // Card sits lower (tighter shadow) while pressed.
          boxShadow: _pressed
              ? const [
                  BoxShadow(
                      color: Color(0x1400265C),
                      blurRadius: 3,
                      offset: Offset(0, 1)),
                ]
              : const [
                  BoxShadow(
                      color: Color(0x1400265C),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                      spreadRadius: -2),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 2, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time column
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(slot.start,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(slot.end, style: const TextStyle(color: AppColors.faint, fontSize: 12)),
                ],
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      slot.subject.baseName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                          height: 1.2,
                          color: AppColors.ink),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration:
                              BoxDecoration(color: style.accent, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            slot.classroom == null
                                ? timetableTypeLabel(slot.subject.lessonType)
                                : '${timetableTypeLabel(slot.subject.lessonType)}  ·  ${slot.classroom!.name}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _AddButton(
                saved: saved,
                onTap: () {
                  HapticFeedback.lightImpact();
                  ref.read(savedSlotsProvider.notifier).toggle(slot.id);
                },
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final bool saved;
  final VoidCallback onTap;
  const _AddButton({required this.saved, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        // Visible chip is 26x26; pad out to a 44x44 tap target.
        padding: const EdgeInsets.all(9),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: saved ? AppColors.navy : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: saved ? AppColors.navy : AppColors.border),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
            child: saved
                ? const Icon(Icons.check_rounded,
                    key: ValueKey('saved'), size: 16, color: Colors.white)
                : const Icon(Icons.add_rounded,
                    key: ValueKey('add'), size: 16, color: AppColors.navy),
          ),
        ),
      ),
    );
  }
}
