import 'dart:math';

import '../../../models/models.dart';

/// One row of the personal weekly agenda — either a saved timetable slot or a
/// user-made custom entry, flattened into the shape both render as.
class AgendaItem {
  final int dayOfWeek;
  final String start;
  final String end;
  final String title;
  final String type;
  final String? room;
  final String? professor;
  final int? customId; // null = saved slot, set = custom entry (deletable)
  final int? slotId; // set = saved timetable slot, so the card can unsave it

  const AgendaItem(
    this.dayOfWeek,
    this.start,
    this.end,
    this.title,
    this.type,
    this.room,
    this.professor, {
    this.customId,
    this.slotId,
  });
}

/// An overlap between two agenda items, told from the perspective of one of
/// them — a conflict is a relationship, not an attribute, so the card that
/// carries it has to be able to name the other side.
class ClassConflict {
  /// The class this one collides with.
  final String otherTitle;
  final String otherStart;

  /// Minutes the two actually share.
  final int overlapMinutes;

  /// True when they share less than the shorter class's full duration. A
  /// 15-minute clash and a full collision are different problems.
  final bool partial;

  const ClassConflict({
    required this.otherTitle,
    required this.otherStart,
    required this.overlapMinutes,
    required this.partial,
  });
}

/// Pairwise overlap scan within each weekday.
///
/// Keyed by item identity — [AgendaItem] keeps Dart's default equality, so two
/// classes that happen to share a title and a start time can never smear each
/// other's conflict state (which a `day-start-title` string key would).
Map<AgendaItem, List<ClassConflict>> computeAgendaConflicts(Iterable<AgendaItem> items) {
  final byDay = <int, List<AgendaItem>>{};
  for (final i in items) {
    (byDay[i.dayOfWeek] ??= []).add(i);
  }

  final conflicts = <AgendaItem, List<ClassConflict>>{};
  for (final list in byDay.values) {
    for (var i = 0; i < list.length; i++) {
      for (var j = i + 1; j < list.length; j++) {
        final a = list[i];
        final b = list[j];
        final aStart = agendaMinutes(a.start);
        final aEnd = agendaMinutes(a.end);
        final bStart = agendaMinutes(b.start);
        final bEnd = agendaMinutes(b.end);

        final overlap = min<int>(aEnd, bEnd) - max<int>(aStart, bStart);
        if (overlap <= 0) continue;

        final partial = overlap < min<int>(aEnd - aStart, bEnd - bStart);
        (conflicts[a] ??= []).add(ClassConflict(
          otherTitle: b.title,
          otherStart: b.start,
          overlapMinutes: overlap,
          partial: partial,
        ));
        (conflicts[b] ??= []).add(ClassConflict(
          otherTitle: a.title,
          otherStart: a.start,
          overlapMinutes: overlap,
          partial: partial,
        ));
      }
    }
  }
  return conflicts;
}

/// "HH:mm" → minutes since midnight, for sorting and overlap checks.
int agendaMinutes(String hhmm) {
  final p = hhmm.split(':');
  return int.parse(p[0]) * 60 + int.parse(p[1]);
}

/// Merges the saved slots and the custom entries into one agenda list.
List<AgendaItem> buildAgendaItems(
  List<ScheduleSlot> slots,
  List<CustomEntry> customEntries,
) =>
    [
      ...slots.map((s) => AgendaItem(
            s.dayOfWeek,
            s.start,
            s.end,
            s.subject.baseName,
            s.subject.lessonType,
            s.classroom?.name,
            s.teachers.map((t) => t.displayName).where((n) => n.isNotEmpty).join(', '),
            slotId: s.id,
          )),
      ...customEntries.map((c) => AgendaItem(
            c.dayOfWeek,
            c.start,
            c.end,
            c.title,
            c.entryType,
            c.room,
            c.professor,
            customId: c.id,
          )),
    ];
