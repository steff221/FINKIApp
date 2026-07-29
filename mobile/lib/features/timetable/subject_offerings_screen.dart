import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/lesson_type.dart';
import '../../core/utils/find_room.dart';
import '../../core/utils/mk_date.dart';
import '../../core/widgets/back_arrow.dart';
import '../../core/widgets/save_chip.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/subject_card.dart';
import '../../models/models.dart';
import '../schedule/widgets/day_header.dart';
import 'timetable_providers.dart';

/// Every time one subject is taught, so a student can pick the one that fits.
///
/// This is the second half of the subject-first flow: the list behind it answers
/// "which subjects are there", and this answers "when, where and with whom" —
/// then lets you claim one.
class SubjectOfferingsScreen extends ConsumerWidget {
  /// The subject as students name it, without the EduPage type suffix.
  final String baseName;

  /// Every slot of this subject for the type being browsed.
  final List<ScheduleSlot> slots;

  const SubjectOfferingsScreen({
    super.key,
    required this.baseName,
    required this.slots,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(savedSlotsProvider);

    // Grouped by day and ordered by the clock — the way a timetable is read.
    final byDay = <int, List<ScheduleSlot>>{};
    for (final slot in slots) {
      (byDay[slot.dayOfWeek] ??= []).add(slot);
    }
    final days = byDay.keys.toList()..sort();
    for (final list in byDay.values) {
      list.sort((a, b) => a.startTime.compareTo(b.startTime));
    }

    return Scaffold(
      body: Column(
        children: [
          ScreenHeader(
            title: baseName,
            subtitle: '${slots.length} ${slots.length == 1 ? 'термин' : 'термини'}',
            leading: const BackArrow(),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
              itemCount: days.length,
              itemBuilder: (context, i) {
                final day = days[i];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DayHeader(day: day),
                    for (final slot in byDay[day]!)
                      _OfferingCard(
                        slot: slot,
                        saved: saved.contains(slot.id),
                        onToggle: () {
                          HapticFeedback.lightImpact();
                          ref.read(savedSlotsProvider.notifier).toggle(slot.id);
                        },
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// One time this subject runs, in the card every list in the app uses — with
/// the two facts that decide which term you take: who teaches it, and which
/// groups it is for.
class _OfferingCard extends StatelessWidget {
  final ScheduleSlot slot;
  final bool saved;
  final VoidCallback onToggle;

  const _OfferingCard({required this.slot, required this.saved, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final type = slot.subject.lessonType;
    final room = slot.classroom?.name;
    final teachers =
        slot.teachers.map((t) => t.displayName).where((n) => n.isNotEmpty).join(', ');
    final groups =
        slot.studyClasses.map((c) => c.name).where((n) => n.isNotEmpty).join(', ');

    return SubjectCard(
      title: slot.subject.baseName,
      // The same quiet tint every class card in the app wears.
      surface: AppColors.panel,
      lead: SubjectLead(
        slot.start,
        secondary: slot.end,
        caption: mkDuration(slot.start, slot.end),
      ),
      meta: [
        SubjectMeta(SubjectIcons.type, lessonTypeLabel(type),
            asset: lessonTypeIconAsset(type)),
        if (room != null && room.isNotEmpty)
          SubjectMeta(SubjectIcons.room, room,
              onTap: () => findRoomOnMap(context, room)),
        if (teachers.isNotEmpty) SubjectMeta(SubjectIcons.teacher, teachers),
        if (groups.isNotEmpty) SubjectMeta(SubjectIcons.date, groups),
      ],
      trailing: SaveChip(saved: saved, onTap: onToggle),
    );
  }
}
