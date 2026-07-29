import 'package:dio/dio.dart';

import '../storage/json_cache.dart';
import '../../models/models.dart';
import 'app_error.dart';

/// Told after every read whether the answer came off the wire or out of the
/// cache, so the UI can say "офлајн" without every screen having to ask.
typedef FreshnessSink = void Function({required bool fromCache});

/// Typed wrapper over the FINKI REST API. Mirrors frontend/src/lib/api.ts.
///
/// Every read goes through [_get], which does three things beyond fetching:
/// stores the raw response, falls back to that store when the network fails,
/// and turns whatever Dio threw into an [AppError] the UI can speak. Writes go
/// through [_send], which only does the last of the three — there is nothing
/// sensible to serve from cache when a booking fails to save.
class Api {
  final Dio _dio;

  /// Absent in tests and in the demo build; the API then simply has no memory.
  final JsonCache? _cache;
  final FreshnessSink? _freshness;

  Api(this._dio, {JsonCache? cache, FreshnessSink? freshness})
      : _cache = cache,
        _freshness = freshness;

  /// A read, with the last good answer as a safety net.
  ///
  /// [cacheKey] null means "do not remember this one" — searches and other
  /// queries whose answer is worthless five minutes later.
  Future<T> _get<T>(
    String path, {
    Map<String, dynamic>? query,
    String? cacheKey,
    required T Function(dynamic json) decode,
  }) async {
    try {
      final res = await _dio.get(path, queryParameters: query);
      if (cacheKey != null) await _cache?.write(cacheKey, res.data);
      _freshness?.call(fromCache: false);
      return decode(res.data);
    } catch (e) {
      final error = AppError.from(e);
      // An expired session is not something a stale copy can paper over — the
      // app is about to sign out, and showing yesterday's timetable on the way
      // would be a lie about being signed in.
      if (cacheKey != null && error.kind != AppErrorKind.auth) {
        final cached = _cache?.read(cacheKey);
        if (cached != null) {
          _freshness?.call(fromCache: true);
          return decode(cached);
        }
      }
      throw error;
    }
  }

  /// A write. Nothing to fall back on — just a failure the UI can read.
  Future<T> _send<T>(Future<T> Function() request) async {
    try {
      return await request();
    } catch (e) {
      throw AppError.from(e);
    }
  }

  // ── Auth ──────────────────────────────────────────────────────────────────
  Future<AuthResponse> login(String email, String password) => _send(() async {
        final res = await _dio
            .post('/auth/login', data: {'email': email, 'password': password});
        return AuthResponse.fromJson(res.data as Map<String, dynamic>);
      });

  Future<AuthResponse> register(String email, String password, String name) =>
      _send(() async {
        final res = await _dio.post('/auth/register',
            data: {'email': email, 'password': password, 'name': name});
        return AuthResponse.fromJson(res.data as Map<String, dynamic>);
      });

  /// The signed-in account as the server sees it now.
  ///
  /// A token carries no details, so a session that started before a field
  /// existed learns about it here rather than by signing in again.
  Future<({int userId, String email, String? name})> me() => _send(() async {
        final res = await _dio.get('/auth/me');
        final j = res.data as Map<String, dynamic>;
        return (
          userId: (j['userId'] as num).toInt(),
          email: j['email'] as String? ?? '',
          name: j['name'] as String?,
        );
      });

  // ── Timetable ───────────────────────────────────────────────────────────────
  Future<TimetableFiltersData> getFilters() => _get(
        '/timetable/filters',
        cacheKey: 'timetable/filters',
        decode: (j) =>
            TimetableFiltersData.fromJson(j as Map<String, dynamic>),
      );

  Future<List<ScheduleSlot>> getSlots(TimetableFilters filters) {
    final query = filters.toQuery();
    return _get(
      '/timetable/slots',
      query: query,
      // Keyed by the filter, so browsing offline still answers for the views
      // that have been opened before.
      cacheKey: 'timetable/slots?${_stableQuery(query)}',
      decode: (j) => (j as List)
          .map((e) => ScheduleSlot.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  // ── Personal schedule ─────────────────────────────────────────────────────
  /// Returns the set of slot ids the user has saved (for the +/✓ toggle).
  Future<Set<int>> getScheduleSlotIds() => _get(
        '/schedule',
        cacheKey: 'schedule',
        decode: (j) => (((j as Map)['slots'] as List?) ?? [])
            .map((e) => ((e as Map)['id'] as num).toInt())
            .toSet(),
      );

  Future<void> addSlot(int slotId) =>
      _send(() => _dio.post('/schedule/slots/$slotId'));

  Future<void> removeSlot(int slotId) =>
      _send(() => _dio.delete('/schedule/slots/$slotId'));

  /// Full saved timetable slots (for the weekly view), not just ids.
  ///
  /// This is the one the whole app leans on — Дома, Мој Распоред and the class
  /// reminders all read it — so it is the one that most needs to survive a
  /// dead network.
  Future<List<ScheduleSlot>> getScheduleSlots() => _get(
        '/schedule',
        cacheKey: 'schedule',
        decode: (j) => (((j as Map)['slots'] as List?) ?? [])
            .map((e) => ScheduleSlot.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  // ── Custom entries ──────────────────────────────────────────────────────────
  Future<List<CustomEntry>> getCustomEntries() => _get(
        '/schedule/custom',
        cacheKey: 'schedule/custom',
        decode: (j) => (j as List)
            .map((e) => CustomEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Future<CustomEntry> createCustomEntry({
    required String title,
    required String entryType,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    String? room,
    String? professor,
  }) =>
      _send(() async {
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
      });

  Future<void> deleteCustomEntry(int id) =>
      _send(() => _dio.delete('/schedule/custom/$id'));

  // ── Exams (sessions catalogue) ──────────────────────────────────────────────
  Future<List<String>> getExamSessions() => _get(
        '/exams/sessions',
        cacheKey: 'exams/sessions',
        decode: (j) => (j as List).map((e) => e as String).toList(),
      );

  Future<List<Exam>> getExams({String? session, String? q}) {
    final query = {
      if (session != null && session.isNotEmpty) 'session': session,
      if (q != null && q.isNotEmpty) 'q': q,
    };
    return _get(
      '/exams',
      query: query,
      // A search is a question about right now; only the plain session listing
      // is worth keeping.
      cacheKey: (q == null || q.isEmpty) ? 'exams?${_stableQuery(query)}' : null,
      decode: (j) =>
          (j as List).map((e) => Exam.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  // ── Saved exams (pinned to Мој Распоред) ────────────────────────────────────
  Future<List<Exam>> getSavedExams() => _get(
        '/schedule/exams',
        cacheKey: 'schedule/exams',
        decode: (j) =>
            (j as List).map((e) => Exam.fromJson(e as Map<String, dynamic>)).toList(),
      );

  Future<void> addSavedExam(int examId) =>
      _send(() => _dio.post('/schedule/exams/$examId'));

  Future<void> removeSavedExam(int examId) =>
      _send(() => _dio.delete('/schedule/exams/$examId'));

  // ── Consultations ───────────────────────────────────────────────────────────
  Future<List<TeacherWithSlots>> getConsultations({String? q}) => _get(
        '/consultations',
        query: {if (q != null && q.isNotEmpty) 'q': q},
        cacheKey: (q == null || q.isEmpty) ? 'consultations' : null,
        decode: (j) => (j as List)
            .map((e) => TeacherWithSlots.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Future<List<ConsultationSlot>> getConsultationsForTeacher(int teacherId) => _get(
        '/consultations/teacher/$teacherId',
        cacheKey: 'consultations/teacher/$teacherId',
        decode: (j) => (j as List)
            .map((e) => ConsultationSlot.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Future<Set<int>> getMyConsultationBookings() => _get(
        '/consultations/bookings/mine',
        cacheKey: 'consultations/bookings/mine',
        decode: (j) => (j as List).map((e) => (e as num).toInt()).toSet(),
      );

  Future<void> bookConsultation(int slotId, String reason) => _send(
      () => _dio.post('/consultations/$slotId/book', data: {'reason': reason}));

  Future<void> cancelConsultationBooking(int slotId) =>
      _send(() => _dio.delete('/consultations/$slotId/book'));
}

/// `a=1&b=2` with the keys in a fixed order, so the same filter always lands on
/// the same cache entry regardless of how the map was built.
String _stableQuery(Map<String, dynamic> query) {
  final keys = query.keys.toList()..sort();
  return [for (final k in keys) '$k=${query[k]}'].join('&');
}
