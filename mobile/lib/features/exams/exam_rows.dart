import '../../core/utils/mk_date.dart';
import '../../models/models.dart';

/// What the Испити list renders, in order.
///
/// Kept apart from the screen so the grouping — what is still ahead, what is
/// behind, and what carries the countdown — can be reasoned about and tested on
/// its own, the way the agenda's conflict rules are.
sealed class ExamRow {
  const ExamRow();
}

/// Heading above one date's exams.
class ExamDateRow extends ExamRow {
  final String date;
  final int count;

  /// "Денес" / "Утре" / "за 3 дена" on the nearest date still ahead; null
  /// everywhere else.
  final String? countdown;

  /// The nearest date still ahead. Kept separate from [countdown] so the
  /// heading and its cards agree even if the date will not parse.
  final bool highlight;
  final bool past;

  const ExamDateRow({
    required this.date,
    required this.count,
    required this.countdown,
    required this.highlight,
    required this.past,
  });
}

class ExamCardRow extends ExamRow {
  final Exam exam;
  final bool highlight;
  final bool past;

  const ExamCardRow({required this.exam, required this.highlight, required this.past});
}

/// A plain line of explanation between sections.
class ExamNoticeRow extends ExamRow {
  final String text;
  const ExamNoticeRow(this.text);
}

/// The divider that folds the already-sat exams away.
class ExamPastRow extends ExamRow {
  final int count;
  final bool expanded;

  /// False once there is nothing ahead — the past is then all there is to
  /// show, so it stays open and the row is a plain heading.
  final bool toggleable;

  const ExamPastRow({
    required this.count,
    required this.expanded,
    required this.toggleable,
  });
}

/// Flattens a session into rows: what is still ahead, then — behind a toggle —
/// what has already been sat.
///
/// Exams already sat are folded away by default; a session keeps them for the
/// whole term and they would otherwise push what is still ahead off the screen.
/// A session whose exams are *all* behind us opens on them anyway, so browsing
/// an old session shows something rather than an empty screen.
///
/// [today] is an ISO "YYYY-MM-DD" date; [now] backs the countdown and defaults
/// to the wall clock.
List<ExamRow> buildExamRows(
  List<Exam> exams, {
  required String today,
  required bool showPast,
  DateTime? now,
}) {
  final upcoming = <String, List<Exam>>{};
  final past = <String, List<Exam>>{};
  for (final e in exams) {
    final bucket = e.date.compareTo(today) >= 0 ? upcoming : past;
    (bucket[e.date] ??= []).add(e);
  }
  for (final list in [...upcoming.values, ...past.values]) {
    list.sort(_byStartTime);
  }

  final upcomingDates = upcoming.keys.toList()..sort();
  // Most recently sat first — the ones just behind you are the ones you might
  // still be looking for.
  final pastDates = past.keys.toList()..sort((a, b) => b.compareTo(a));

  final rows = <ExamRow>[];
  for (final date in upcomingDates) {
    final dayExams = upcoming[date]!;
    // Only the nearest date carries the countdown; further ones would turn the
    // list into a wall of pills.
    final nearest = date == upcomingDates.first;
    rows.add(ExamDateRow(
      date: date,
      count: dayExams.length,
      countdown: nearest ? mkRelativeDays(date, from: now) : null,
      highlight: nearest,
      past: false,
    ));
    rows.addAll(
        dayExams.map((e) => ExamCardRow(exam: e, highlight: nearest, past: false)));
  }

  if (pastDates.isEmpty) return rows;

  final expanded = showPast || upcomingDates.isEmpty;
  if (upcomingDates.isEmpty) {
    // Say why the screen opens on old exams, rather than letting the student
    // work out that the session is over.
    rows.add(const ExamNoticeRow('Нема претстојни испити во оваа сесија'));
  }
  rows.add(ExamPastRow(
    count: past.values.fold(0, (sum, l) => sum + l.length),
    expanded: expanded,
    toggleable: upcomingDates.isNotEmpty,
  ));
  if (expanded) {
    for (final date in pastDates) {
      final dayExams = past[date]!;
      rows.add(ExamDateRow(
        date: date,
        count: dayExams.length,
        countdown: null,
        highlight: false,
        past: true,
      ));
      rows.addAll(
          dayExams.map((e) => ExamCardRow(exam: e, highlight: false, past: true)));
    }
  }
  return rows;
}

/// Chronological within a day; exams with no time on file sit at the end.
int _byStartTime(Exam a, Exam b) {
  final x = a.startTime;
  final y = b.startTime;
  if (x == null) return y == null ? 0 : 1;
  if (y == null) return -1;
  return x.compareTo(y);
}
