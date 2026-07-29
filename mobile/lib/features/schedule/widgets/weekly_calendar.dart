import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

import '../../../core/theme/app_art.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shape.dart';
import '../../../core/theme/lesson_type.dart';
import '../../../core/utils/find_room.dart';
import '../../../core/widgets/finki_loader.dart';
import '../../../core/widgets/state_views.dart';
import '../../../models/models.dart';
import '../schedule_providers.dart';
import 'agenda_item.dart';

/// Initials for the week strip, in the order the timetable counts days.
const _dayInitials = ['ПОН', 'ВТО', 'СРЕ', 'ЧЕТ', 'ПЕТ'];

/// One hour of the day, in pixels.
const _hourHeight = 68.0;

/// The clock down the left edge.
const _gutterWidth = 52.0;

/// Under this, a block has room for its title and nothing else.
const _compactBlockHeight = 44.0;

/// The day as a timeline, one day at a time.
///
/// A five-column week on a phone gives each class about 35 points of width —
/// enough to know something is there, not enough to read what. The calendar
/// people already know works this way round: pick the day at the top, and the
/// day itself gets the whole screen, so a class is a block you can actually
/// read rather than a coloured sliver.
class WeeklyCalendar extends ConsumerStatefulWidget {
  const WeeklyCalendar({super.key});

  @override
  ConsumerState<WeeklyCalendar> createState() => _WeeklyCalendarState();
}

class _WeeklyCalendarState extends ConsumerState<WeeklyCalendar> {
  /// 0 = Monday … 4 = Friday. Opens on today, or on Monday over the weekend —
  /// which is the next day that has anything on it.
  late int _day = _todayIndex() ?? 0;

  static int? _todayIndex() {
    // DateTime counts Monday as 1; the timetable counts it as 0.
    final i = DateTime.now().weekday - 1;
    return i >= 0 && i <= 4 ? i : null;
  }

  /// The Monday of the week being shown, so the strip can carry real dates.
  static DateTime _mondayOfThisWeek() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
  }

  @override
  Widget build(BuildContext context) {
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

    if (!slotsAsync.hasValue || !customAsync.hasValue) {
      return const Padding(
        padding: EdgeInsets.only(top: 60),
        child: Center(child: FinkiLoader()),
      );
    }

    final all = buildAgendaItems(slotsAsync.value ?? [], customAsync.value ?? [])
        .where((i) => i.dayOfWeek >= 0 && i.dayOfWeek <= 4)
        .toList();

    if (all.isEmpty) {
      return const EmptyStateView(
        scrollable: false,
        topGap: 20,
        animation: AppArt.programmer,
        icon: Icons.calendar_view_week_outlined,
        title: 'Вашиот распоред е празен',
        subtitle: 'Додадете часови од Распоред',
      );
    }

    final monday = _mondayOfThisWeek();
    final today = _todayIndex();
    final perDay = <int, int>{
      for (var d = 0; d < 5; d++) d: all.where((i) => i.dayOfWeek == d).length,
    };

    final items = all.where((i) => i.dayOfWeek == _day).toList()
      ..sort((a, b) => agendaMinutes(a.start).compareTo(agendaMinutes(b.start)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _WeekStrip(
          selected: _day,
          today: today,
          monday: monday,
          counts: perDay,
          onSelect: (d) {
            if (d == _day) return;
            HapticFeedback.selectionClick();
            setState(() => _day = d);
          },
        ),
        const SizedBox(height: 14),
        if (items.isEmpty)
          const _FreeDay()
        else
          _DayTimeline(
            items: items,
            conflicts: computeAgendaConflicts(all),
            isToday: today == _day,
          ),
      ],
    );
  }
}

/// The week across the top: which day you are looking at, which day it is, and
/// which days have anything on them at all.
class _WeekStrip extends StatelessWidget {
  final int selected;
  final int? today;
  final DateTime monday;
  final Map<int, int> counts;
  final ValueChanged<int> onSelect;

  const _WeekStrip({
    required this.selected,
    required this.today,
    required this.monday,
    required this.counts,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var d = 0; d < 5; d++)
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onSelect(d),
              child: Column(
                children: [
                  Text(
                    _dayInitials[d],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                      color: d == today ? AppColors.navy : AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // The date in a filled disc when picked, an outline when it is
                  // today but you are looking elsewhere — the same two states
                  // every calendar on the phone uses.
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOut,
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: d == selected ? AppColors.navy : Colors.transparent,
                      border: d == today && d != selected
                          ? Border.all(color: AppColors.navy, width: 1.5)
                          : null,
                    ),
                    child: Text(
                      '${monday.add(Duration(days: d)).day}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: d == selected ? Colors.white : AppColors.ink,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  // A dot for "there is something here", so an empty day is
                  // visible before you tap it.
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (counts[d] ?? 0) > 0
                          ? (d == selected ? AppColors.navy : AppColors.faint)
                          : Colors.transparent,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// The chosen day, hour by hour.
class _DayTimeline extends StatelessWidget {
  final List<AgendaItem> items;
  final Map<AgendaItem, List<ClassConflict>> conflicts;
  final bool isToday;

  const _DayTimeline({
    required this.items,
    required this.conflicts,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    // Spans the day the student actually has, rounded out to whole hours, with
    // half an hour of air under the last class so a block never sits on the
    // very edge of the grid.
    final firstMin = items.map((i) => agendaMinutes(i.start)).reduce((a, b) => a < b ? a : b);
    final lastMin = items.map((i) => agendaMinutes(i.end)).reduce((a, b) => a > b ? a : b);
    final startHour = (firstMin ~/ 60).clamp(0, 23);
    final endHour = ((lastMin + 89) ~/ 60).clamp(startHour + 1, 24);
    final now = DateTime.now();
    final nowMin = now.hour * 60 + now.minute;

    return LayoutBuilder(
      builder: (context, constraints) {
        final laneWidth = constraints.maxWidth - _gutterWidth;

        return SizedBox(
          height: (endHour - startHour) * _hourHeight,
          child: Stack(
            children: [
              _HourLines(startHour: startHour, endHour: endHour),
              for (final placed in _layOut(items, laneWidth))
                Positioned(
                  left: _gutterWidth + placed.left,
                  width: placed.width,
                  top: (agendaMinutes(placed.item.start) - startHour * 60) /
                      60 *
                      _hourHeight,
                  height: ((agendaMinutes(placed.item.end) -
                              agendaMinutes(placed.item.start)) /
                          60 *
                          _hourHeight)
                      .clamp(26.0, double.infinity),
                  child: _ClassBlock(
                    item: placed.item,
                    clashes: (conflicts[placed.item] ?? const []).isNotEmpty,
                    narrow: placed.width < laneWidth * 0.7,
                  ),
                ),
              // The red line every calendar draws through now — only on today,
              // and only while it is inside the hours on screen.
              if (isToday && nowMin >= startHour * 60 && nowMin <= endHour * 60)
                Positioned(
                  left: _gutterWidth - 5,
                  right: 0,
                  top: (nowMin - startHour * 60) / 60 * _hourHeight,
                  child: const _NowLine(),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// A class and the horizontal slice of the day it was given.
class _Placed {
  final AgendaItem item;
  final double left;
  final double width;

  const _Placed(this.item, this.left, this.width);
}

/// Splits the lane between classes that overlap in time.
///
/// Two classes at 08:00 are the timetable's problem, not the layout's — drawing
/// one over the other would hide exactly the clash the student needs to see, so
/// they share the width instead.
List<_Placed> _layOut(List<AgendaItem> items, double laneWidth) {
  const gap = 6.0;
  final out = <_Placed>[];

  var i = 0;
  while (i < items.length) {
    var clusterEnd = agendaMinutes(items[i].end);
    var j = i + 1;
    while (j < items.length && agendaMinutes(items[j].start) < clusterEnd) {
      final end = agendaMinutes(items[j].end);
      if (end > clusterEnd) clusterEnd = end;
      j++;
    }

    final cluster = items.sublist(i, j);
    final slice = (laneWidth - gap * (cluster.length - 1)) / cluster.length;
    for (var k = 0; k < cluster.length; k++) {
      out.add(_Placed(cluster[k], k * (slice + gap), slice));
    }
    i = j;
  }
  return out;
}

/// A day with nothing on it — said plainly, in the space the grid would fill.
class _FreeDay extends StatelessWidget {
  const _FreeDay();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        children: [
          Lottie.asset(AppArt.programmer, width: 150, height: 150, repeat: true),
          const SizedBox(height: 4),
          const Text(
            'Слободен ден',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

/// The hour rules and the clock beside them.
class _HourLines extends StatelessWidget {
  final int startHour;
  final int endHour;

  const _HourLines({required this.startHour, required this.endHour});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var h = startHour; h < endHour; h++)
          SizedBox(
            height: _hourHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: _gutterWidth,
                  child: Transform.translate(
                    // Sat on the rule it labels rather than under it.
                    offset: const Offset(0, -6),
                    child: Text(
                      '${h.toString().padLeft(2, '0')}:00',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.faint,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
                const Expanded(
                  child: Divider(height: 1, thickness: 1, color: AppColors.border),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// The line through the current moment.
class _NowLine extends StatelessWidget {
  const _NowLine();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: const BoxDecoration(
            color: AppColors.danger,
            shape: BoxShape.circle,
          ),
        ),
        const Expanded(child: ColoredBox(color: AppColors.danger, child: SizedBox(height: 1.5))),
      ],
    );
  }
}

/// One class, drawn where it sits in the day.
class _ClassBlock extends StatelessWidget {
  final AgendaItem item;
  final bool clashes;

  /// True when the block is sharing the lane, and so has to say less.
  final bool narrow;

  const _ClassBlock({
    required this.item,
    required this.clashes,
    required this.narrow,
  });

  @override
  Widget build(BuildContext context) {
    final style = lessonTypeStyle(item.type);

    return Padding(
      padding: const EdgeInsets.only(bottom: 3, right: 2),
      child: Material(
        color: style.pillBg,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => showClassDetails(context, item),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  // A clash is called out on the edge of the block, where two
                  // classes sharing the lane already draw the eye.
                  color: clashes ? AppColors.danger : style.accent,
                  width: 4,
                ),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(9, 5, 8, 5),
            child: LayoutBuilder(
              builder: (context, c) {
                final compact = c.maxHeight < _compactBlockHeight;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        item.title,
                        maxLines: compact ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.2,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    if (!compact) ...[
                      const SizedBox(height: 2),
                      Text(
                        narrow
                            ? item.start
                            : '${item.start} – ${item.end}'
                                '${item.room != null && item.room!.isNotEmpty ? ' · ${item.room}' : ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: style.pillFg,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Everything the block was too small to say.
///
/// The grid trades detail for shape; this is where the detail went, one tap
/// away — including the way to the room, which is the reason most people open a
/// class in the first place.
void showClassDetails(BuildContext context, AgendaItem item) {
  final style = lessonTypeStyle(item.type);

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Fact(
                  Icons.schedule_rounded,
                  '${item.start} – ${item.end}',
                  bg: AppColors.panel,
                ),
                _Fact(
                  Icons.event_outlined,
                  kDayNames[item.dayOfWeek],
                  bg: AppColors.panel,
                ),
                _Fact(
                  Icons.label_outline_rounded,
                  lessonTypeLabel(item.type),
                  bg: style.pillBg,
                  fg: style.pillFg,
                ),
              ],
            ),
            if (item.professor != null && item.professor!.isNotEmpty) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.person_outline_rounded,
                      size: 16, color: AppColors.faint),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(item.professor!,
                        style: const TextStyle(fontSize: 13.5, color: AppColors.ink)),
                  ),
                ],
              ),
            ],
            if (item.room != null && item.room!.isNotEmpty) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    findRoomOnMap(context, item.room!);
                  },
                  icon: const Icon(Icons.place_outlined, size: 18),
                  label: Text('Најди ${item.room!} на картата'),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _Fact extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color bg;
  final Color? fg;

  const _Fact(this.icon, this.text, {required this.bg, this.fg});

  @override
  Widget build(BuildContext context) {
    final color = fg ?? AppColors.ink;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}
