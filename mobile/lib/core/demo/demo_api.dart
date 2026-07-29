import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../models/models.dart';
import '../network/api.dart';
import 'demo.dart';

/// The API as far as a presentation build is concerned.
///
/// Reads the snapshot in `assets/demo/` instead of the network, and keeps
/// everything the student does in memory for the length of the session. Extends
/// [Api] so every screen keeps calling exactly what it already calls — nothing
/// above this class knows the difference.
class DemoApi extends Api {
  /// The inherited Dio is never used; every method here is overridden.
  DemoApi() : super(Dio());

  // ── The snapshot, parsed once ───────────────────────────────────────────────
  List<ScheduleSlot>? _slots;
  List<Exam>? _exams;
  List<String>? _sessions;
  List<TeacherWithSlots>? _consultations;
  TimetableFiltersData? _filters;

  Future<dynamic> _read(String name) async =>
      jsonDecode(await rootBundle.loadString('assets/demo/$name.json'));

  Future<List<ScheduleSlot>> _allSlots() async => _slots ??= ((await _read('slots')) as List)
      .map((e) => ScheduleSlot.fromJson(e as Map<String, dynamic>))
      .toList();

  Future<List<Exam>> _allExams() async => _exams ??= ((await _read('exams')) as List)
      .map((e) => Exam.fromJson(e as Map<String, dynamic>))
      .toList();

  Future<List<TeacherWithSlots>> _allConsultations() async =>
      _consultations ??= ((await _read('consultations')) as List)
          .map((e) => TeacherWithSlots.fromJson(e as Map<String, dynamic>))
          .toList();

  // ── What the student changes while presenting ──────────────────────────────
  /// Seeded so the personal schedule has something in it from the first tap.
  final Set<int> _savedSlotIds = {41, 48, 190};
  final Set<int> _savedExamIds = {};
  final List<CustomEntry> _customEntries = [];
  final Set<int> _bookings = {};
  int _nextCustomId = 1;

  // ── Auth ───────────────────────────────────────────────────────────────────
  @override
  Future<AuthResponse> login(String email, String password) async =>
      AuthResponse(token: 'demo', userId: 1, email: kDemoEmail, name: kDemoName);

  @override
  Future<AuthResponse> register(String email, String password, String name) async =>
      AuthResponse(token: 'demo', userId: 1, email: email, name: name);

  @override
  Future<({int userId, String email, String? name})> me() async =>
      (userId: 1, email: kDemoEmail, name: kDemoName);

  // ── Timetable ──────────────────────────────────────────────────────────────
  @override
  Future<TimetableFiltersData> getFilters() async => _filters ??=
      TimetableFiltersData.fromJson((await _read('filters')) as Map<String, dynamic>);

  /// The same narrowing the backend does, applied to the snapshot — so the
  /// filter sheet is live rather than decorative.
  @override
  Future<List<ScheduleSlot>> getSlots(TimetableFilters f) async {
    return (await _allSlots()).where((s) {
      if (f.dayOfWeek != null && s.dayOfWeek != f.dayOfWeek) return false;
      if (f.lessonType != null && s.subject.lessonType != f.lessonType) return false;
      if (f.subjectId != null && s.subject.id != f.subjectId) return false;
      if (f.classroomId != null && s.classroom?.id != f.classroomId) return false;
      if (f.teacherId != null && !s.teachers.any((t) => t.id == f.teacherId)) return false;
      if (f.year != null && !s.studyClasses.any((c) => c.year == f.year)) return false;
      if (f.programmeCode != null &&
          !s.studyClasses.any((c) => c.programmeCode == f.programmeCode)) {
        return false;
      }
      return true;
    }).toList();
  }

  // ── Personal schedule ──────────────────────────────────────────────────────
  @override
  Future<Set<int>> getScheduleSlotIds() async => {..._savedSlotIds};

  @override
  Future<void> addSlot(int slotId) async => _savedSlotIds.add(slotId);

  @override
  Future<void> removeSlot(int slotId) async => _savedSlotIds.remove(slotId);

  @override
  Future<List<ScheduleSlot>> getScheduleSlots() async =>
      (await _allSlots()).where((s) => _savedSlotIds.contains(s.id)).toList();

  @override
  Future<List<CustomEntry>> getCustomEntries() async => List.of(_customEntries);

  @override
  Future<CustomEntry> createCustomEntry({
    required String title,
    required String entryType,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    String? room,
    String? professor,
  }) async {
    final entry = CustomEntry(
      id: _nextCustomId++,
      title: title,
      professor: professor,
      entryType: entryType,
      dayOfWeek: dayOfWeek,
      startTime: startTime,
      endTime: endTime,
      room: room,
      color: null,
    );
    _customEntries.add(entry);
    return entry;
  }

  @override
  Future<void> deleteCustomEntry(int id) async =>
      _customEntries.removeWhere((e) => e.id == id);

  // ── Exams ──────────────────────────────────────────────────────────────────
  @override
  Future<List<String>> getExamSessions() async =>
      _sessions ??= ((await _read('exam_sessions')) as List).cast<String>();

  @override
  Future<List<Exam>> getExams({String? session, String? q}) async {
    final all = await _allExams();
    final needle = q?.trim().toLowerCase();
    return all.where((e) {
      if (session != null && e.session != session) return false;
      if (needle != null && needle.isNotEmpty) {
        return e.subjectName.toLowerCase().contains(needle) ||
            (e.rooms ?? '').toLowerCase().contains(needle);
      }
      return true;
    }).toList();
  }

  @override
  Future<List<Exam>> getSavedExams() async =>
      (await _allExams()).where((e) => _savedExamIds.contains(e.id)).toList();

  @override
  Future<void> addSavedExam(int examId) async => _savedExamIds.add(examId);

  @override
  Future<void> removeSavedExam(int examId) async => _savedExamIds.remove(examId);

  // ── Consultations ──────────────────────────────────────────────────────────
  @override
  Future<List<TeacherWithSlots>> getConsultations({String? q}) async {
    final all = await _allConsultations();
    final needle = q?.trim().toLowerCase();
    if (needle == null || needle.isEmpty) return all;
    return all
        .where((t) => t.teacher.displayName.toLowerCase().contains(needle))
        .toList();
  }

  @override
  Future<List<ConsultationSlot>> getConsultationsForTeacher(int teacherId) async {
    for (final t in await _allConsultations()) {
      if (t.teacher.id == teacherId) return t.slots;
    }
    return const [];
  }

  @override
  Future<Set<int>> getMyConsultationBookings() async => {..._bookings};

  @override
  Future<void> bookConsultation(int slotId, String reason) async => _bookings.add(slotId);

  @override
  Future<void> cancelConsultationBooking(int slotId) async => _bookings.remove(slotId);
}
