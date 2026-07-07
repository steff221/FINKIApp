import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/lesson_type.dart';
import '../../../models/models.dart';
import '../timetable_providers.dart';

Future<void> showSlotDetailsSheet(BuildContext context, ScheduleSlot slot) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _SlotDetailsSheet(slot: slot),
  );
}

class _SlotDetailsSheet extends ConsumerWidget {
  final ScheduleSlot slot;
  const _SlotDetailsSheet({required this.slot});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = lessonTypeStyle(slot.subject.lessonType);
    final saved = ref.watch(savedSlotsProvider).contains(slot.id);

    final teachers = slot.teachers.map((t) => t.displayName).where((n) => n.isNotEmpty).join(', ');
    final groups = slot.studyClasses.map((c) => c.name).join(', ');
    final day = slot.dayOfWeek >= 0 && slot.dayOfWeek < kDayNames.length
        ? kDayNames[slot.dayOfWeek]
        : '';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: style.pillBg, borderRadius: BorderRadius.circular(999)),
              child: Text(
                timetableTypeLabel(slot.subject.lessonType),
                style: TextStyle(color: style.pillFg, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              slot.subject.baseName,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800, height: 1.25, color: AppColors.ink),
            ),
            const SizedBox(height: 18),
            _detailRow(Icons.schedule_rounded, '$day · ${slot.start}–${slot.end}'),
            if (slot.classroom != null)
              _detailRow(Icons.place_outlined, slot.classroom!.name),
            if (teachers.isNotEmpty) _detailRow(Icons.school_outlined, teachers),
            if (groups.isNotEmpty) _detailRow(Icons.group_outlined, groups),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => ref.read(savedSlotsProvider.notifier).toggle(slot.id),
                style: saved
                    ? FilledButton.styleFrom(
                        backgroundColor: AppColors.hairline,
                        foregroundColor: AppColors.ink,
                      )
                    : null,
                icon: Icon(saved ? Icons.check_rounded : Icons.add_rounded, size: 20),
                label: Text(saved ? 'Во мојот распоред' : 'Додади во мојот распоред'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: AppColors.faint),
            const SizedBox(width: 12),
            Expanded(
              child: Text(text,
                  style: const TextStyle(color: AppColors.ink, fontSize: 14.5, height: 1.35)),
            ),
          ],
        ),
      );
}
