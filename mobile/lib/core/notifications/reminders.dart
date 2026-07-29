import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../models/models.dart';

/// How long before a class starts the phone should say something.
///
/// Fifteen minutes is the walk from the bus stop to Барака 3 — enough to make
/// the reminder actionable, short enough that it is still about *this* class.
const _kClassLeadMinutes = 15;

/// An exam is worth knowing about the evening before, not fifteen minutes
/// before — nobody revises in the corridor.
const _kExamLeadHours = 18;

/// Everything is scheduled a week out and rebuilt whenever the timetable
/// changes; iOS caps pending notifications at 64, and a week of classes plus
/// pinned exams sits comfortably under that.
const _kHorizonDays = 7;

/// The campus is in Skopje, and so is every class in it.
const _kTimeZone = 'Europe/Skopje';

/// Class and exam reminders, on the phone alone.
///
/// The schedule is already local — the server has nothing to add and no reason
/// to know when a student wants to be nudged — so this never talks to the
/// backend. It re-reads the saved timetable whenever it changes and rewrites
/// the whole set of pending notifications; there is no incremental state to get
/// out of step.
class RemindersController extends StateNotifier<bool> {
  static const _prefsKey = 'reminders_enabled';
  static const _classChannelId = 'classes';
  static const _examChannelId = 'exams';

  final Ref ref;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;

  /// What was last scheduled, so an identical timetable does not cause the
  /// whole set to be torn down and rebuilt on every rebuild of Дома.
  String? _lastSignature;

  RemindersController(this.ref) : super(false) {
    _restore();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_prefsKey) ?? false;
    if (state) await _ensureReady();
  }

  /// Initialises the plugin and the timezone database. Idempotent — every entry
  /// point calls it and only the first one does the work.
  Future<void> _ensureReady() async {
    if (_ready) return;
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(_kTimeZone));
    await _plugin.initialize(
      settings: const InitializationSettings(
        iOS: DarwinInitializationSettings(
          // Asked for explicitly in [enable] instead, so the prompt appears
          // when the student turns reminders on rather than at first launch.
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    _ready = true;
  }

  /// Turns reminders on, asking iOS for permission the first time.
  ///
  /// Returns false when the student declines — the switch then stays off, which
  /// is the truth: we cannot deliver anything.
  Future<bool> enable() async {
    await _ensureReady();
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final granted = await ios?.requestPermissions(alert: true, badge: true, sound: true) ??
        true;
    if (!granted) return false;

    state = true;
    (await SharedPreferences.getInstance()).setBool(_prefsKey, true);
    return true;
  }

  Future<void> disable() async {
    state = false;
    _lastSignature = null;
    (await SharedPreferences.getInstance()).setBool(_prefsKey, false);
    if (_ready) await _plugin.cancelAll();
  }

  /// Returns whether reminders are on afterwards.
  Future<bool> toggle(bool on) async {
    if (on) return enable();
    await disable();
    return false;
  }

  /// Rewrites every pending reminder from the timetable as it now stands.
  ///
  /// Safe to call on every data change: identical input is a no-op.
  Future<void> sync({
    required List<ScheduleSlot> slots,
    required List<CustomEntry> entries,
    required List<Exam> exams,
    DateTime? now,
  }) async {
    if (!state) return;
    await _ensureReady();

    final signature = _signature(slots, entries, exams);
    if (signature == _lastSignature) return;

    final occurrences = _plan(
      slots: slots,
      entries: entries,
      exams: exams,
      now: now ?? DateTime.now(),
    );

    await _plugin.cancelAll();
    for (final o in occurrences) {
      await _schedule(o);
    }
    _lastSignature = signature;
  }

  Future<void> _schedule(_Reminder r) async {
    final details = NotificationDetails(
      iOS: const DarwinNotificationDetails(presentAlert: true, presentSound: true),
      android: AndroidNotificationDetails(
        r.isExam ? _examChannelId : _classChannelId,
        r.isExam ? 'Испити' : 'Часови',
        channelDescription: r.isExam
            ? 'Потсетник пред испит'
            : 'Потсетник пред час од твојот распоред',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );

    try {
      await _plugin.zonedSchedule(
        id: r.id,
        title: r.title,
        body: r.body,
        // Built in the campus timezone, so a phone that travels still fires at
        // the hour the class actually starts.
        scheduledDate: tz.TZDateTime.from(r.at, tz.local),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (_) {
      // One reminder that will not schedule must not cost the rest of them.
    }
  }
}

/// One scheduled nudge.
class _Reminder {
  final int id;
  final String title;
  final String body;
  final DateTime at;
  final bool isExam;

  const _Reminder({
    required this.id,
    required this.title,
    required this.body,
    required this.at,
    required this.isExam,
  });
}

/// What the timetable amounts to, as one comparable string.
String _signature(
        List<ScheduleSlot> slots, List<CustomEntry> entries, List<Exam> exams) =>
    [
      for (final s in slots) 's${s.id}:${s.dayOfWeek}:${s.startTime}',
      for (final e in entries) 'c${e.id}:${e.dayOfWeek}:${e.startTime}',
      for (final e in exams) 'e${e.id}:${e.date}:${e.startTime}',
    ].join('|');

/// Turns the timetable into the concrete moments a notification should fire.
///
/// Pure and side-effect free so it can be tested without a phone: given a
/// timetable and a "now", it says exactly what should be pending.
List<_Reminder> _plan({
  required List<ScheduleSlot> slots,
  required List<CustomEntry> entries,
  required List<Exam> exams,
  required DateTime now,
}) {
  final out = <_Reminder>[];

  // ── Weekly classes, expanded over the horizon ─────────────────────────────
  for (var dayOffset = 0; dayOffset < _kHorizonDays; dayOffset++) {
    final day = DateTime(now.year, now.month, now.day).add(Duration(days: dayOffset));
    // The models count Monday as 0; DateTime counts it as 1.
    final dayOfWeek = day.weekday - 1;

    for (final slot in slots.where((s) => s.dayOfWeek == dayOfWeek)) {
      final at = _atTime(day, slot.startTime)
          ?.subtract(const Duration(minutes: _kClassLeadMinutes));
      if (at == null || !at.isAfter(now)) continue;
      final room = slot.classroom?.name;
      out.add(_Reminder(
        id: _idFor('slot', slot.id, day),
        title: slot.subject.baseName,
        body: room == null || room.isEmpty
            ? 'Почнува во ${slot.start}'
            : 'Почнува во ${slot.start} · $room',
        at: at,
        isExam: false,
      ));
    }

    for (final entry in entries.where((e) => e.dayOfWeek == dayOfWeek)) {
      final at = _atTime(day, entry.startTime)
          ?.subtract(const Duration(minutes: _kClassLeadMinutes));
      if (at == null || !at.isAfter(now)) continue;
      final room = entry.room;
      out.add(_Reminder(
        id: _idFor('custom', entry.id, day),
        title: entry.title,
        body: room == null || room.isEmpty
            ? 'Почнува во ${_hhmm(entry.startTime)}'
            : 'Почнува во ${_hhmm(entry.startTime)} · $room',
        at: at,
        isExam: false,
      ));
    }
  }

  // ── Pinned exams ──────────────────────────────────────────────────────────
  for (final exam in exams) {
    final date = DateTime.tryParse(exam.date);
    if (date == null) continue;
    final start = _atTime(date, exam.startTime ?? '09:00:00');
    if (start == null) continue;
    final at = start.subtract(const Duration(hours: _kExamLeadHours));
    if (!at.isAfter(now)) continue;
    // Only what the horizon can hold; the rest is scheduled on a later sync.
    if (at.difference(now).inDays > 30) continue;
    final rooms = exam.rooms;
    out.add(_Reminder(
      id: _idFor('exam', exam.id, date),
      title: 'Испит утре: ${exam.subjectName}',
      body: [
        if (exam.start != null) 'Почнува во ${exam.start}',
        if (rooms != null && rooms.isNotEmpty) rooms,
      ].join(' · '),
      at: at,
      isExam: true,
    ));
  }

  out.sort((a, b) => a.at.compareTo(b.at));
  // iOS keeps the first 64 pending notifications and drops the rest, so decide
  // here which ones those are: the soonest.
  return out.take(60).toList();
}

/// "HH:mm[:ss]" on [day], or null when the string is not a time.
DateTime? _atTime(DateTime day, String hhmmss) {
  final parts = hhmmss.split(':');
  if (parts.length < 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return null;
  return DateTime(day.year, day.month, day.day, h, m);
}

String _hhmm(String t) => t.length >= 5 ? t.substring(0, 5) : t;

/// A stable id per (kind, entity, day) so re-scheduling replaces rather than
/// duplicates. Kept inside 32 bits, which is all the platforms accept.
int _idFor(String kind, int entityId, DateTime day) {
  final key = '$kind:$entityId:${day.year}-${day.month}-${day.day}';
  var hash = 0;
  for (final unit in key.codeUnits) {
    hash = (hash * 31 + unit) & 0x3FFFFFFF;
  }
  return hash;
}

/// Exposed for tests — the planner is the part with the logic in it.
List<({int id, String title, String body, DateTime at, bool isExam})> planReminders({
  required List<ScheduleSlot> slots,
  required List<CustomEntry> entries,
  required List<Exam> exams,
  required DateTime now,
}) =>
    _plan(slots: slots, entries: entries, exams: exams, now: now)
        .map((r) => (id: r.id, title: r.title, body: r.body, at: r.at, isExam: r.isExam))
        .toList();
