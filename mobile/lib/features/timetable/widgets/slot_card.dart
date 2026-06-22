import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/lesson_type.dart';
import '../../../models/models.dart';
import '../timetable_providers.dart';

class SlotCard extends ConsumerWidget {
  final ScheduleSlot slot;
  const SlotCard({super.key, required this.slot});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = lessonTypeStyle(slot.subject.lessonType);
    final saved = ref.watch(savedSlotsProvider).contains(slot.id);

    final teachers = slot.teachers.map((t) => t.displayName).where((n) => n.isNotEmpty).join(', ');
    final groups = slot.studyClasses.map((c) => c.name).join(', ');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: style.accent, width: 4)),
        boxShadow: const [
          BoxShadow(color: Color(0x12000000), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time column
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(slot.start,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                Container(width: 1, height: 8, color: AppColors.border, margin: const EdgeInsets.symmetric(vertical: 2)),
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
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14.5, height: 1.2, color: AppColors.ink),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _pill(timetableTypeLabel(slot.subject.lessonType), style.pillBg, style.pillFg),
                      if (slot.classroom != null) _chip(Icons.place_outlined, slot.classroom!.name),
                      if (groups.isNotEmpty) _chip(Icons.group_outlined, groups),
                    ],
                  ),
                  if (teachers.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(teachers,
                        style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 6),
            _AddButton(
              saved: saved,
              onTap: () => ref.read(savedSlotsProvider.notifier).toggle(slot.id),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String text, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
        child: Text(text, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
      );

  Widget _chip(IconData icon, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.faint),
          const SizedBox(width: 3),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Text(text,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          ),
        ],
      );
}

class _AddButton extends StatelessWidget {
  final bool saved;
  final VoidCallback onTap;
  const _AddButton({required this.saved, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: saved ? AppColors.navy : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: saved ? AppColors.navy : AppColors.border),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
          child: saved
              ? const Row(
                  key: ValueKey('saved'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_rounded, size: 16, color: Colors.white),
                    SizedBox(width: 4),
                    Text('Додадено',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                )
              : const Row(
                  key: ValueKey('add'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, size: 16, color: AppColors.navy),
                    SizedBox(width: 4),
                    Text('Додај',
                        style: TextStyle(color: AppColors.navy, fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ),
        ),
      ),
    );
  }
}
