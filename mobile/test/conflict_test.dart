import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finki_scheduler/features/schedule/widgets/agenda_item.dart';
import 'package:finki_scheduler/features/schedule/widgets/class_card.dart';
import 'package:finki_scheduler/features/schedule/widgets/conflict_banner.dart';

AgendaItem item(String title, String start, String end, {int day = 0}) =>
    AgendaItem(day, start, end, title, 'lecture', null, null);

void main() {
  group('computeAgendaConflicts', () {
    test('both overlapping classes get a conflict naming the other', () {
      final a = item('Математика 2', '08:00', '09:45');
      final b = item('Веб програмирање', '09:00', '10:45');
      final conflicts = computeAgendaConflicts([a, b]);

      expect(conflicts[a]!.single.otherTitle, 'Веб програмирање');
      expect(conflicts[a]!.single.otherStart, '09:00');
      expect(conflicts[b]!.single.otherTitle, 'Математика 2');
      expect(conflicts[b]!.single.otherStart, '08:00');
    });

    test('a partial overlap reports the shared minutes', () {
      final a = item('Математика 2', '08:00', '09:45');
      final b = item('Веб програмирање', '09:30', '11:00');
      final c = computeAgendaConflicts([a, b])[a]!.single;

      expect(c.partial, isTrue);
      expect(c.overlapMinutes, 15);
    });

    test('a class fully inside another is not reported as partial', () {
      final a = item('Математика 2', '08:00', '10:45');
      final b = item('Веб програмирање', '09:00', '10:00');
      expect(computeAgendaConflicts([a, b])[a]!.single.partial, isFalse);
    });

    test('touching classes and different days do not conflict', () {
      final back2back = [item('А', '08:00', '09:45'), item('Б', '09:45', '11:00')];
      final otherDay = [item('А', '08:00', '09:45'), item('Б', '08:00', '09:45', day: 1)];

      expect(computeAgendaConflicts(back2back), isEmpty);
      expect(computeAgendaConflicts(otherDay), isEmpty);
    });

    test('same title and start on the same day does not smear onto a third class', () {
      // Two identical-looking lectures plus one that clashes with neither.
      final a = item('Математика 2', '08:00', '09:45');
      final b = item('Математика 2', '08:00', '09:45');
      final clean = item('Веб програмирање', '12:00', '13:45');

      final conflicts = computeAgendaConflicts([a, b, clean]);
      expect(conflicts.containsKey(clean), isFalse);
      expect(conflicts[a], hasLength(1));
    });
  });

  group('conflict presentation', () {
    test('copy names the other class', () {
      expect(
        conflictSentence(const ClassConflict(
            otherTitle: 'Математика 2', otherStart: '08:00', overlapMinutes: 105, partial: false)),
        'Се преклопува со Математика 2, 08:00',
      );
      expect(
        conflictSentence(const ClassConflict(
            otherTitle: 'Математика 2', otherStart: '09:30', overlapMinutes: 15, partial: true)),
        'Се преклопува 15 мин со Математика 2',
      );
    });

    Widget host(Widget child) => ProviderScope(
          child: MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child))),
        );

    testWidgets('a conflicting card shows the banner, a clean one shows nothing',
        (tester) async {
      final a = item('Математика 2', '08:00', '09:45');
      final b = item('Веб програмирање', '09:30', '11:00');
      final conflicts = computeAgendaConflicts([a, b]);

      await tester.pumpWidget(host(Column(children: [
        ClassCard(item: a, conflicts: conflicts[a]!),
        ClassCard(item: item('Анализа', '12:00', '13:45')),
      ])));

      expect(find.byType(ConflictBanner), findsOneWidget);
      expect(find.text('Се преклопува 15 мин со Веб програмирање'), findsOneWidget);
      expect(find.text('Конфликт'), findsNothing);
    });

    testWidgets('the banner carries its own semantics label', (tester) async {
      final semantics = tester.ensureSemantics();
      // Веб програмирање sits entirely inside Математика 2 — a full collision.
      final a = item('Математика 2', '08:00', '10:45');
      final b = item('Веб програмирање', '09:00', '10:00');
      final conflicts = computeAgendaConflicts([a, b]);

      await tester.pumpWidget(host(ClassCard(item: a, conflicts: conflicts[a]!)));

      expect(
        find.bySemanticsLabel(
            'Конфликт во распоредот. Се преклопува со Веб програмирање, 09:00'),
        findsOneWidget,
      );
      semantics.dispose();
    });
  });
}
