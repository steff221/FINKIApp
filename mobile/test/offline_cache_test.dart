import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:finki_scheduler/core/network/api.dart';
import 'package:finki_scheduler/core/network/app_error.dart';
import 'package:finki_scheduler/core/storage/json_cache.dart';

/// A Dio that answers from a script instead of a network: either canned JSON or
/// the failure of your choice.
class _ScriptedAdapter implements HttpClientAdapter {
  Object? failWith;
  dynamic body;
  int calls = 0;

  _ScriptedAdapter({this.body});

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<List<int>>? requestStream,
      Future<void>? cancelFuture) async {
    calls++;
    if (failWith != null) throw failWith!;
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// One slot as the backend sends it.
Map<String, dynamic> slotJson({int id = 41, String name = 'Веб програмирање'}) => {
      'id': id,
      'subject': {
        'id': 1,
        'fullName': name,
        'baseName': name,
        'lessonType': 'LECTURE',
      },
      'teachers': [],
      'studyClasses': [],
      'classroom': {'id': 2, 'name': 'Барака 3.2'},
      'dayOfWeek': 0,
      'startTime': '08:00:00',
      'endTime': '09:45:00',
      'editionNumber': '1',
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _ScriptedAdapter adapter;
  late JsonCache cache;
  late Api api;
  late List<bool> freshnessReports;

  Future<void> build() async {
    SharedPreferences.setMockInitialValues({});
    cache = await JsonCache.open();
    adapter = _ScriptedAdapter(body: {
      'slots': [slotJson()],
    });
    freshnessReports = [];
    final dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'))
      ..httpClientAdapter = adapter;
    api = Api(dio,
        cache: cache,
        freshness: ({required fromCache}) => freshnessReports.add(fromCache));
  }

  setUp(build);

  test('a successful read is served fresh and remembered', () async {
    final slots = await api.getScheduleSlots();

    expect(slots.single.subject.baseName, 'Веб програмирање');
    expect(freshnessReports, [false]);
    expect(cache.has('schedule'), isTrue);
  });

  test('a dead network is answered from the last good response', () async {
    await api.getScheduleSlots(); // warm the cache
    adapter.failWith = DioException.connectionError(
      requestOptions: RequestOptions(path: '/schedule'),
      reason: 'no route to host',
    );

    final slots = await api.getScheduleSlots();

    expect(slots.single.subject.baseName, 'Веб програмирање',
        reason: 'the cached timetable is still the right answer');
    expect(freshnessReports.last, isTrue, reason: 'and the app is told it is stale');
  });

  test('with nothing cached, the failure surfaces as an offline AppError', () async {
    adapter.failWith = DioException.connectionError(
      requestOptions: RequestOptions(path: '/schedule'),
      reason: 'no route to host',
    );

    await expectLater(
      api.getScheduleSlots(),
      throwsA(isA<AppError>().having((e) => e.kind, 'kind', AppErrorKind.offline)),
    );
  });

  test('an expired session is never papered over with cached data', () async {
    await api.getScheduleSlots();
    adapter.failWith = DioException.badResponse(
      statusCode: 401,
      requestOptions: RequestOptions(path: '/schedule'),
      response: Response(requestOptions: RequestOptions(path: '/schedule'), statusCode: 401),
    );

    await expectLater(
      api.getScheduleSlots(),
      throwsA(isA<AppError>().having((e) => e.kind, 'kind', AppErrorKind.auth)),
    );
  });

  test('a fresh answer clears the stale flag again', () async {
    await api.getScheduleSlots();
    adapter.failWith = DioException.connectionError(
      requestOptions: RequestOptions(path: '/schedule'),
      reason: 'offline',
    );
    await api.getScheduleSlots();
    expect(freshnessReports.last, isTrue);

    adapter.failWith = null;
    await api.getScheduleSlots();
    expect(freshnessReports.last, isFalse);
  });

  test('a search is deliberately not cached', () async {
    adapter.body = [];
    await api.getExams(session: 'Јануари', q: 'бази');
    expect(cache.has('exams?session=Јануари'), isFalse);

    // …while the plain session listing is.
    await api.getExams(session: 'Јануари');
    expect(cache.has('exams?session=Јануари'), isTrue);
  });

  test('signing out empties the store', () async {
    await api.getScheduleSlots();
    expect(cache.has('schedule'), isTrue);

    await cache.clear();

    expect(cache.has('schedule'), isFalse);
    expect(cache.read('schedule'), isNull);
  });

  test('the cache stamps when it was written', () async {
    await api.getScheduleSlots();
    final at = cache.writtenAt('schedule');

    expect(at, isNotNull);
    expect(DateTime.now().difference(at!).inSeconds, lessThan(5));
  });
}
