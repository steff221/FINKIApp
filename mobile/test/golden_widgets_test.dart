import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:finki_scheduler/core/network/app_error.dart';
import 'package:finki_scheduler/core/theme/app_colors.dart';
import 'package:finki_scheduler/core/theme/app_theme.dart';
import 'package:finki_scheduler/core/widgets/screen_header.dart';
import 'package:finki_scheduler/core/widgets/state_views.dart';
import 'package:finki_scheduler/core/widgets/subject_card.dart';
import 'package:finki_scheduler/features/schedule/widgets/agenda_item.dart';
import 'package:finki_scheduler/features/schedule/widgets/conflict_banner.dart';

/// Pins the look of the pieces every screen is built from.
///
/// These are the parts that changed most often by hand — a card, a header, the
/// strip that calls out a clash — and the parts whose regressions are invisible
/// to a behavioural test: nothing throws when a colour goes wrong. Run with
/// `flutter test --update-goldens` after an intentional design change, and read
/// the diff as the review of that change.
Widget _harness(Widget child, {double width = 390}) => MaterialApp(
      theme: buildAppTheme(),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        // Top-aligned so each golden is the size of the thing under test
        // rather than the size of the phone it would sit on.
        body: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(width: width, child: child),
        ),
      ),
    );

void main() {
  // Goldens must not depend on what a font server feels like returning: the
  // typography falls back to the bundled default, identically on every machine.
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('subject card — the shape every list shares', (tester) async {
    await tester.pumpWidget(_harness(
      const Padding(
        padding: EdgeInsets.all(16),
        child: SubjectCard(
          title: 'Објектно-ориентирано програмирање',
          surface: AppColors.panel,
          lead: SubjectLead('08:00', secondary: '09:45', caption: '1ч 45мин'),
          meta: [
            SubjectMeta(SubjectIcons.type, 'Предавање'),
            SubjectMeta(SubjectIcons.room, 'Амфитеатар ФИНКИ (А1)'),
            SubjectMeta(SubjectIcons.teacher, 'Иван Чорбев, Бобан Јоксимоски'),
          ],
        ),
      ),
    ));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(SubjectCard),
      matchesGoldenFile('goldens/subject_card.png'),
    );
  });

  testWidgets('conflict banner — how a clash is called out', (tester) async {
    await tester.pumpWidget(_harness(
      const ConflictBanner(conflicts: [
        ClassConflict(
          otherTitle: 'Анализа на софтверските барања',
          otherStart: '08:00',
          partial: false,
          overlapMinutes: 105,
        ),
      ]),
    ));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(ConflictBanner),
      matchesGoldenFile('goldens/conflict_banner.png'),
    );
  });

  testWidgets('screen header — a screen saying what it is', (tester) async {
    await tester.pumpWidget(_harness(
      const ScreenHeader(
        title: 'Мој Распоред',
        subtitle: 'Часовите и испитите што ги следите',
      ),
    ));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(ScreenHeader),
      matchesGoldenFile('goldens/screen_header.png'),
    );
  });

  testWidgets('offline error state — the one students see most', (tester) async {
    await tester.pumpWidget(_harness(
      SizedBox(
        height: 420,
        child: ErrorStateView.from(
          const AppError(AppErrorKind.offline),
          scrollable: false,
          topGap: 24,
          onRetry: () {},
        ),
      ),
    ));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(ErrorStateView),
      matchesGoldenFile('goldens/error_offline.png'),
    );
  });
}
