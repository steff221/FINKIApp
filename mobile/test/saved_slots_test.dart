import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finki_scheduler/core/network/api.dart';
import 'package:finki_scheduler/core/providers.dart';
import 'package:finki_scheduler/features/schedule/schedule_providers.dart';
import 'package:finki_scheduler/features/timetable/timetable_providers.dart';
import 'package:finki_scheduler/models/models.dart';

ScheduleSlot slot(int id) => ScheduleSlot(
      id: id,
      subject: Subject(
        id: id,
        fullName: 'Предмет $id',
        baseName: 'Предмет $id',
        lessonType: 'LECTURE',
      ),
      classroom: null,
      teachers: const [],
      studyClasses: const [],
      dayOfWeek: 0,
      startTime: '08:00:00',
      endTime: '09:45:00',
      editionNumber: '1',
    );

/// Stands in for the server: the saved set is state, and `/schedule` reports
/// whatever has been added so far.
class FakeApi extends Api {
  final Set<int> saved;
  int scheduleFetches = 0;

  FakeApi({Set<int>? saved}) : saved = saved ?? <int>{}, super(Dio());

  @override
  Future<Set<int>> getScheduleSlotIds() async => {...saved};

  @override
  Future<List<ScheduleSlot>> getScheduleSlots() async {
    scheduleFetches++;
    return saved.map(slot).toList();
  }

  @override
  Future<void> addSlot(int slotId) async {
    saved.add(slotId);
  }

  @override
  Future<void> removeSlot(int slotId) async {
    saved.remove(slotId);
  }
}

void main() {
  late FakeApi api;
  late ProviderContainer container;

  setUp(() {
    api = FakeApi(saved: {1});
    container = ProviderContainer(overrides: [apiProvider.overrideWithValue(api)]);
    // The shell keeps the weekly views mounted for the whole session, so the
    // schedule provider always has a listener and never auto-disposes.
    container.listen(scheduleSlotsProvider, (_, _) {});
  });

  tearDown(() => container.dispose());

  test('saving a class puts it in the weekly schedule', () async {
    expect(await container.read(scheduleSlotsProvider.future), hasLength(1));

    await container.read(savedSlotsProvider.notifier).toggle(2);

    final slots = await container.read(scheduleSlotsProvider.future);
    expect(slots.map((s) => s.id), unorderedEquals([1, 2]));
    expect(api.scheduleFetches, 2, reason: 'the weekly list has to be refetched');
  });

  test('unsaving a class takes it back out', () async {
    await container.read(scheduleSlotsProvider.future);
    // The controller fetches the saved ids in its constructor; the chip cannot
    // show ✓ — and so cannot be tapped to unsave — until that has landed.
    container.read(savedSlotsProvider.notifier);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(savedSlotsProvider), contains(1));

    await container.read(savedSlotsProvider.notifier).toggle(1);

    expect(await container.read(scheduleSlotsProvider.future), isEmpty);
  });

  test('a failed save leaves both the chip and the schedule as they were', () async {
    final failing = _FailingApi();
    final c = ProviderContainer(overrides: [apiProvider.overrideWithValue(failing)]);
    addTearDown(c.dispose);
    c.listen(scheduleSlotsProvider, (_, _) {});
    await c.read(scheduleSlotsProvider.future);

    await c.read(savedSlotsProvider.notifier).toggle(2);

    expect(c.read(savedSlotsProvider), isNot(contains(2)));
    expect(await c.read(scheduleSlotsProvider.future), isEmpty);
  });
}

class _FailingApi extends FakeApi {
  @override
  Future<void> addSlot(int slotId) async => throw Exception('offline');
}
