// Macedonian (Cyrillic) date formatting helpers.
//
// Single source of truth for calendar-date labels, replacing the per-screen
// month/weekday arrays that previously lived in exams_screen.dart and
// schedule_screen.dart.

const List<String> mkWeekdayNames = [
  'Недела', 'Понеделник', 'Вторник', 'Среда', 'Четврток', 'Петок', 'Сабота',
];

const List<String> mkMonthNamesLong = [
  'Јануари', 'Февруари', 'Март', 'Април', 'Мај', 'Јуни',
  'Јули', 'Август', 'Септември', 'Октомври', 'Ноември', 'Декември',
];

const List<String> mkMonthNamesShort = [
  'јан', 'фев', 'мар', 'апр', 'мај', 'јун',
  'јул', 'авг', 'сеп', 'окт', 'ное', 'дек',
];

/// Parses an ISO "YYYY-MM-DD" date, or null when the string isn't one.
///
/// Every date helper here goes through this, so a malformed date fails the same
/// way everywhere — the caller falls back to showing the raw string.
DateTime? parseIsoDate(String iso) {
  final p = iso.split('-');
  if (p.length != 3) return null;
  final y = int.tryParse(p[0]);
  final m = int.tryParse(p[1]);
  final d = int.tryParse(p[2]);
  if (y == null || m == null || d == null || m < 1 || m > 12) return null;
  return DateTime(y, m, d);
}

/// Formats an ISO date ("YYYY-MM-DD") as e.g. "Понеделник, 3 Февруари 2026".
///
/// - [longMonth] chooses between full ("Февруари") and short ("фев") month names.
/// - [year] appends the year when true.
/// Returns the raw input unchanged if it isn't a valid YYYY-MM-DD string.
String formatMkDate(String iso, {bool longMonth = true, bool year = false}) {
  final date = parseIsoDate(iso);
  if (date == null) return iso;
  final month =
      longMonth ? mkMonthNamesLong[date.month - 1] : mkMonthNamesShort[date.month - 1];
  final base = '${mkWeekdayNames[date.weekday % 7]}, ${date.day} $month';
  return year ? '$base ${date.year}' : base;
}

/// Macedonian counted form: "1 минута" / "2 минути", "1 час" / "3 часа".
///
/// Numbers ending in 1 (but not 11) take the singular form; everything else
/// takes the counted plural.
String _mkCounted(int n, String one, String many) =>
    (n % 10 == 1 && n % 100 != 11) ? one : many;

/// How far off something is, in Macedonian — e.g. "за 1 минута", "за 20 минути",
/// "за 1 час", "за 3 часа". Anything at or past due reads "сега".
///
/// Under an hour counts whole minutes; from an hour up it counts whole hours.
String mkRelativeTime(Duration d) {
  final minutes = d.inMinutes;
  if (minutes <= 0) return 'сега';
  if (minutes < 60) return 'за $minutes ${_mkCounted(minutes, 'минута', 'минути')}';
  final hours = d.inHours;
  return 'за $hours ${_mkCounted(hours, 'час', 'часа')}';
}

/// How far off a calendar date is, in Macedonian: "Денес", "Утре", "за 3 дена".
///
/// Null once the date is behind us — there is nothing left to count down to,
/// and the caller shows the plain date instead.
String? mkRelativeDays(String iso, {DateTime? from}) {
  final date = parseIsoDate(iso);
  if (date == null) return null;
  final now = from ?? DateTime.now();
  final days = date.difference(DateTime(now.year, now.month, now.day)).inDays;
  if (days < 0) return null;
  return switch (days) {
    0 => 'Денес',
    1 => 'Утре',
    // "дена" is the counted form for every number above one, so this needs no
    // singular case.
    _ => 'за $days дена',
  };
}

/// A count of exams: "1 испит" / "3 испити".
String mkExamCount(int n) => '$n ${_mkCounted(n, 'испит', 'испити')}';

/// Time-of-day greeting in Macedonian: "Добро утро" before 11, "Добар ден"
/// until 18, "Добра вечер" after.
String mkGreeting(DateTime now, {String? name}) {
  final greeting = switch (now.hour) {
    < 11 => 'Добро утро',
    < 18 => 'Добар ден',
    _ => 'Добра вечер',
  };
  final first = firstName(name);
  return first == null ? greeting : '$greeting, $first';
}

/// First word of a display name, so "Стефан Перовски" greets as "Стефан".
/// Null when there is no usable name on file.
String? firstName(String? name) {
  final trimmed = name?.trim() ?? '';
  if (trimmed.isEmpty) return null;
  return trimmed.split(RegExp(r'\s+')).first;
}

/// Today's date as an ISO "YYYY-MM-DD" string (local time).
String todayIso() {
  final n = DateTime.now();
  return '${n.year.toString().padLeft(4, '0')}-'
      '${n.month.toString().padLeft(2, '0')}-'
      '${n.day.toString().padLeft(2, '0')}';
}

/// Compact class length for the card gutter: "45мин", "2ч", "1ч 45мин".
///
/// Kept tight on purpose — it has one line of a 50pt column to live in.
///
/// Takes "HH:mm" bounds; returns null when either fails to parse or the class
/// has no length, so the caption simply disappears rather than reading "0 мин".
String? mkDuration(String start, String end) {
  int? minutes(String hhmm) {
    final p = hhmm.split(':');
    if (p.length < 2) return null;
    final h = int.tryParse(p[0]);
    final m = int.tryParse(p[1]);
    return (h == null || m == null) ? null : h * 60 + m;
  }

  final from = minutes(start);
  final to = minutes(end);
  if (from == null || to == null) return null;

  final total = to - from;
  if (total <= 0) return null;

  final h = total ~/ 60;
  final m = total % 60;
  if (h == 0) return '$m' 'мин';
  return m == 0 ? '$h' 'ч' : '$h' 'ч ' '$m' 'мин';
}

/// Day-over-month for an exam card's gutter: ("15", "јан") from "2026-01-15".
/// Falls back to the raw string when the date will not parse.
(String, String?) mkDayMonth(String iso) {
  final date = parseIsoDate(iso);
  if (date == null) return (iso, null);
  return ('${date.day}', mkMonthNamesShort[date.month - 1]);
}
