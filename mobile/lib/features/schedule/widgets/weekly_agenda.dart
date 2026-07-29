import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_art.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/entrance_fade.dart';
import '../../../core/widgets/finki_loader.dart';
import '../../../core/widgets/state_views.dart';
import '../schedule_providers.dart';
import 'agenda_item.dart';
import 'class_card.dart';
import 'day_header.dart';

/// The day-grouped personal schedule.
///
/// Rendered on both Мој Распоред and Дома.
///
/// The day of the week is read once per build. Left open across midnight the
/// "today" marker will sit on yesterday until something else rebuilds the
/// list — not worth a timer ticking all day to correct.
class WeeklyAgenda extends ConsumerWidget {
  const WeeklyAgenda({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slotsAsync = ref.watch(scheduleSlotsProvider);
    final customAsync = ref.watch(customEntriesProvider);

    if (slotsAsync.hasError || customAsync.hasError) {
      return ErrorStateView.from(
        slotsAsync.error ?? customAsync.error,
        scrollable: false,
        topGap: 60,
        onRetry: () {
          ref.invalidate(scheduleSlotsProvider);
          ref.read(customEntriesProvider.notifier).reload();
        },
      );
    }

    // Only the first load has nothing to show. A refetch — saving a class, say —
    // keeps the current agenda on screen rather than blanking it to a spinner.
    if (!slotsAsync.hasValue || !customAsync.hasValue) {
      return const Padding(
          padding: EdgeInsets.only(top: 60), child: Center(child: FinkiLoader()));
    }

    final items = buildAgendaItems(slotsAsync.valueOrNull ?? [], customAsync.valueOrNull ?? []);

    if (items.isEmpty) {
      return const EmptyStateView(
        scrollable: false,
        topGap: 20,
        animation: AppArt.programmer,
        icon: Icons.event_available_outlined,
        title: 'Вашиот распоред е празен',
        subtitle: 'Додадете часови од Распоред',
      );
    }

    final totalMin = items.fold<int>(
        0, (sum, i) => sum + (agendaMinutes(i.end) - agendaMinutes(i.start)).clamp(0, 600));
    final hours = totalMin ~/ 60;
    final mins = totalMin % 60;

    final byDay = <int, List<AgendaItem>>{};
    for (final i in items) {
      if (i.dayOfWeek >= 0 && i.dayOfWeek <= 4) (byDay[i.dayOfWeek] ??= []).add(i);
    }
    for (final list in byDay.values) {
      list.sort((a, b) => agendaMinutes(a.start).compareTo(agendaMinutes(b.start)));
    }
    final conflicts = computeAgendaConflicts(items);

    final days = byDay.keys.toList()..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 4),
          child: Text(
            '${items.length} записи · ${hours}ч $mins мин неделно', // ignore: unnecessary_brace_in_string_interps
            style: const TextStyle(
                color: AppColors.muted, fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
        ),
        for (var d = 0; d < days.length; d++) ...[
          _daySection(days[d], byDay[days[d]]!, conflicts, d),
        ],
      ],
    );
  }

  Widget _daySection(
      int day,
      List<AgendaItem> list,
      Map<AgendaItem, List<ClassConflict>> conflicts,
      int dayIdx) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DayHeader(day: day),
        for (var j = 0; j < list.length; j++)
          Entrance(
            delayMs: (dayIdx * 70 + j * 45).clamp(0, 420),
            child: ClassCard(
              item: list[j],
              conflicts: conflicts[list[j]] ?? const [],
            ),
          ),
      ],
    );
  }
}
