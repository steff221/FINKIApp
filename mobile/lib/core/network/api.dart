import 'package:dio/dio.dart';
import '../../models/models.dart';

/// Typed wrapper over the FINKI REST API. Mirrors frontend/src/lib/api.ts.
class Api {
  final Dio _dio;
  Api(this._dio);

  // ── Auth ──────────────────────────────────────────────────────────────────
  Future<AuthResponse> login(String email, String password) async {
    final res = await _dio.post('/auth/login', data: {'email': email, 'password': password});
    return AuthResponse.fromJson(res.data as Map<String, dynamic>);
  }

  // ── Timetable ───────────────────────────────────────────────────────────────
  Future<TimetableFiltersData> getFilters() async {
    final res = await _dio.get('/timetable/filters');
    return TimetableFiltersData.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<ScheduleSlot>> getSlots(TimetableFilters filters) async {
    final res = await _dio.get('/timetable/slots', queryParameters: filters.toQuery());
    return (res.data as List)
        .map((e) => ScheduleSlot.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Personal schedule ─────────────────────────────────────────────────────
  /// Returns the set of slot ids the user has saved (for the +/✓ toggle).
  Future<Set<int>> getScheduleSlotIds() async {
    final res = await _dio.get('/schedule');
    final slots = (res.data['slots'] as List?) ?? [];
    return slots.map((e) => (e['id'] as num).toInt()).toSet();
  }

  Future<void> addSlot(int slotId) => _dio.post('/schedule/slots/$slotId');
  Future<void> removeSlot(int slotId) => _dio.delete('/schedule/slots/$slotId');

  /// Full saved timetable slots (for the weekly view), not just ids.
  Future<List<ScheduleSlot>> getScheduleSlots() async {
    final res = await _dio.get('/schedule');
    final slots = (res.data['slots'] as List?) ?? [];
    return slots.map((e) => ScheduleSlot.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── Custom entries ──────────────────────────────────────────────────────────
  Future<List<CustomEntry>> getCustomEntries() async {
    final res = await _dio.get('/schedule/custom');
    return (res.data as List)
        .map((e) => CustomEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CustomEntry> createCustomEntry({
    required String title,
    required String entryType,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    String? room,
    String? professor,
  }) async {
    final res = await _dio.post('/schedule/custom', data: {
      'title': title,
      'entryType': entryType,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      if (room != null && room.isNotEmpty) 'room': room,
      if (professor != null && professor.isNotEmpty) 'professor': professor,
    });
    return CustomEntry.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteCustomEntry(int id) => _dio.delete('/schedule/custom/$id');

  // ── Exams (sessions catalogue) ──────────────────────────────────────────────
  Future<List<String>> getExamSessions() async {
    final res = await _dio.get('/exams/sessions');
    return (res.data as List).map((e) => e as String).toList();
  }

  Future<List<Exam>> getExams({String? session, String? q}) async {
    final res = await _dio.get('/exams', queryParameters: {
      if (session != null && session.isNotEmpty) 'session': session,
      if (q != null && q.isNotEmpty) 'q': q,
    });
    return (res.data as List).map((e) => Exam.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── Saved exams (pinned to Мој Распоред) ────────────────────────────────────
  Future<List<Exam>> getSavedExams() async {
    final res = await _dio.get('/schedule/exams');
    return (res.data as List).map((e) => Exam.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> addSavedExam(int examId) => _dio.post('/schedule/exams/$examId');
  Future<void> removeSavedExam(int examId) => _dio.delete('/schedule/exams/$examId');

  // ── Consultations ───────────────────────────────────────────────────────────
  Future<List<TeacherWithSlots>> getConsultations({String? q}) async {
    final res = await _dio.get('/consultations',
        queryParameters: {if (q != null && q.isNotEmpty) 'q': q});
    return (res.data as List)
        .map((e) => TeacherWithSlots.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ConsultationSlot>> getConsultationsForTeacher(int teacherId) async {
    final res = await _dio.get('/consultations/teacher/$teacherId');
    return (res.data as List)
        .map((e) => ConsultationSlot.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Set<int>> getMyConsultationBookings() async {
    final res = await _dio.get('/consultations/bookings/mine');
    return (res.data as List).map((e) => (e as num).toInt()).toSet();
  }

  Future<void> bookConsultation(int slotId, String reason) =>
      _dio.post('/consultations/$slotId/book', data: {'reason': reason});

  Future<void> cancelConsultationBooking(int slotId) =>
      _dio.delete('/consultations/$slotId/book');
}
