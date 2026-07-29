import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/lesson_type.dart';
import '../../../core/utils/find_room.dart';
import '../../../core/utils/mk_date.dart';
import '../../../core/widgets/delete_button.dart';
import '../../../core/widgets/subject_card.dart';
import '../../timetable/timetable_providers.dart';
import '../schedule_providers.dart';
import 'agenda_item.dart';
import 'conflict_banner.dart';

/// One class in the personal weekly agenda, rendered in the shared subject
/// layout: title over stacked time / type / room / teacher rows.
///
/// Custom entries (those with a `customId`) also get a delete affordance.
/// Shared by Мој Распоред and Дома.
class ClassCard extends ConsumerWidget {
  final AgendaItem item;

  /// Overlaps this class is part of. Empty on the cards that have none — the
  /// red accent and the banner both key off this list, so neither can leak onto
  /// a clean card.
  final List<ClassConflict> conflicts;

  const ClassCard({super.key, required this.item, this.conflicts = const []});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final room = item.room;
    final professor = item.professor;
    final conflict = conflicts.isNotEmpty;

    return SubjectCard(
      title: item.title,
      // Every card the same quiet tint. A clash is called out by the banner
      // underneath, which has the icon and the sentence — washing the whole
      // card red as well shouts about it twice.
      surface: AppColors.panel,
      lead: SubjectLead(
        item.start,
        secondary: item.end,
        caption: mkDuration(item.start, item.end),
      ),
      meta: [
        SubjectMeta(SubjectIcons.type, lessonTypeLabel(item.type),
            asset: lessonTypeIconAsset(item.type)),
        if (room != null && room.isNotEmpty)
          SubjectMeta(SubjectIcons.room, room,
              onTap: () => findRoomOnMap(context, room)),
        if (professor != null && professor.isNotEmpty)
          SubjectMeta(SubjectIcons.teacher, professor),
      ],
      footer: conflict ? ConflictBanner(conflicts: conflicts) : null,
      trailing: CardDeleteButton(
        onTap: item.customId != null
            ? () => _confirmDelete(context, ref, item.customId!, item.title)
            : item.slotId != null
                ? () {
                    HapticFeedback.mediumImpact();
                    ref.read(savedSlotsProvider.notifier).toggle(item.slotId!);
                  }
                : null,
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, int customId, String title) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Избриши запис'),
        content: Text('Дали да се избрише „$title"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Откажи'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Избриши'),
          ),
        ],
      ),
    );
    if (ok == true) {
      HapticFeedback.mediumImpact();
      ref.read(customEntriesProvider.notifier).delete(customId);
    }
  }
}
