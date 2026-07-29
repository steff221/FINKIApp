import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finki_scheduler/core/network/api.dart';
import 'package:finki_scheduler/core/widgets/app_dropdown.dart';
import 'package:finki_scheduler/core/widgets/labeled_field.dart';
import 'package:finki_scheduler/core/providers.dart';
import 'package:finki_scheduler/features/schedule/schedule_screen.dart';
import 'package:finki_scheduler/models/models.dart';

class _FakeApi extends Api {
  _FakeApi() : super(Dio());

  bool askedForSlots = false;
  Map<String, dynamic>? savedEntry;

  @override
  Future<List<ScheduleSlot>> getSlots(TimetableFilters filters) async {
    askedForSlots = true;
    return [];
  }

  @override
  Future<List<ScheduleSlot>> getScheduleSlots() async => [];

  @override
  Future<Set<int>> getScheduleSlotIds() async => <int>{};

  @override
  Future<List<CustomEntry>> getCustomEntries() async => [];

  @override
  Future<List<Exam>> getSavedExams() async => [];

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
    savedEntry = {
      'title': title,
      'entryType': entryType,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      'room': room,
      'professor': professor,
    };
    return CustomEntry(
      id: 1,
      title: title,
      professor: professor,
      entryType: entryType,
      dayOfWeek: dayOfWeek,
      startTime: '$startTime:00',
      endTime: '$endTime:00',
      room: room,
      color: null,
    );
  }
}

/// Pumps until the UI has caught up.
///
/// Мој Распоред shows a looping animation when the timetable is empty, which is
/// exactly the state these tests start in — `pumpAndSettle` waits for an
/// animation that never ends, so pump a fixed slice instead.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  late _FakeApi api;

  /// Opens the FAB's sheet — Лабораториски вежби is the only kind entered here.
  Future<void> openSheet(WidgetTester tester) async {
    api = _FakeApi();
    await tester.pumpWidget(ProviderScope(
      overrides: [apiProvider.overrideWithValue(api)],
      child: const MaterialApp(home: ScheduleScreen()),
    ));
    await settle(tester);

    await tester.tap(find.byType(FloatingActionButton).last); // open the FAB
    await settle(tester);
    // Mini buttons come first in the column, lectures at the top.
    await tester.tap(find.byType(FloatingActionButton).first);
    await settle(tester);
  }

  /// Types into the field under [label]. The label sits above the field rather
  /// than inside it, so it is reached through the [LabeledField] that owns both.
  Future<void> type(WidgetTester tester, String label, String value) async {
    await tester.enterText(
      find.descendant(
        of: find.widgetWithText(LabeledField, label),
        matching: find.byType(TextField),
      ),
      value,
    );
    await tester.pump();
  }

  testWidgets('every field is typed — nothing is looked up', (tester) async {
    await openSheet(tester);

    expect(find.text('Предмет *'), findsOneWidget);
    expect(find.text('Просторија (опционално)'), findsOneWidget);
    expect(find.text('Ден'), findsOneWidget);
    expect(find.text('Предавач (опционално)'), findsNothing,
        reason: 'the sheet asks for the name, the time and the place, nothing else');
    expect(find.text('Почеток'), findsOneWidget);
    expect(find.text('Крај'), findsOneWidget);
    expect(api.askedForSlots, isFalse, reason: 'the sheet must not query the timetable');
  });

  testWidgets('what was typed is what gets saved', (tester) async {
    await openSheet(tester);

    await type(tester, 'Предмет *', 'Веб програмирање');
    await type(tester, 'Просторија (опционално)', 'ТМФ 315');
    await tester.tap(find.text('Зачувај'));
    await settle(tester);

    expect(api.savedEntry, {
      'title': 'Веб програмирање',
      'entryType': 'LAB',
      'dayOfWeek': 0,
      'startTime': '08:00',
      'endTime': '09:30',
      'room': 'ТМФ 315',
      'professor': null,
    });
  });

  testWidgets('the room is optional', (tester) async {
    await openSheet(tester);

    await type(tester, 'Предмет *', 'Веб програмирање');
    await tester.tap(find.text('Зачувај'));
    await settle(tester);

    expect(api.savedEntry!['room'], isNull);
  });

  testWidgets('the subject name is required', (tester) async {
    await openSheet(tester);

    await tester.tap(find.text('Зачувај'));
    await settle(tester);

    expect(find.text('Внесете назив на предметот'), findsOneWidget);
    expect(api.savedEntry, isNull);
  });

  testWidgets('the one option saves a type the backend accepts', (tester) async {
    // Lectures and exercises are claimed from Распоред; only lab classes, which
    // the faculty does not publish, are entered here. entry_type is
    // CHECK-constrained, so anything outside the four is rejected by Postgres
    // rather than by the app — 'AUDITORY' used to be sent and always failed.
    await openSheet(tester);
    await type(tester, 'Предмет *', 'Веб програмирање');
    await tester.tap(find.text('Зачувај'));
    await settle(tester);

    expect(api.savedEntry!['entryType'], 'LAB');
    expect(find.byType(FloatingActionButton), findsNWidgets(2),
        reason: 'the menu offers one kind of class, plus the FAB itself');
  });

  testWidgets('the day picked is the day saved', (tester) async {
    await openSheet(tester);
    await type(tester, 'Предмет *', 'Веб програмирање');

    // The control, not the label above it.
    await tester.tap(find.descendant(
      of: find.byType(AppDropdown<int>),
      matching: find.byType(DropdownButtonFormField<int?>),
    ));
    await settle(tester);
    await tester.tap(find.text('Четврток').last);
    await settle(tester);

    await tester.tap(find.text('Зачувај'));
    await settle(tester);

    expect(api.savedEntry!['dayOfWeek'], 3);
  });
}
