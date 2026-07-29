import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../core/providers.dart';
import '../../core/theme/app_art.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_type.dart';
import '../../core/theme/lesson_type.dart';
import '../../core/utils/find_room.dart';
import '../../core/utils/mk_date.dart';
import '../../core/widgets/app_refresh.dart';
import '../../core/widgets/delete_button.dart';
import '../../core/widgets/exam_card.dart';
import '../../core/widgets/finki_loader.dart';
import '../../core/widgets/profile_menu.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/subject_card.dart';
import '../../models/models.dart';
import '../schedule/schedule_providers.dart';
import '../schedule/widgets/agenda_item.dart';
import '../schedule/widgets/weekly_agenda.dart';
import '../../core/theme/app_shape.dart';

/// The next class the user has coming up, resolved against a moment in time.
///
/// [minutesAway] is null when nothing is left today — [item] is then the first
/// class of the next day that has one, and the card reads as an empty state.
class _NextClass {
  final AgendaItem item;
  final int? minutesAway;

  const _NextClass(this.item, this.minutesAway);
}

/// Дома — the landing screen: what's next right now, then the full week.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scroll = ScrollController();
  Timer? _clock;
  DateTime _now = DateTime.now();
  bool _collapsed = false;
  bool _scrolled = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  /// The large title hands over to the toolbar title once the flexible space is
  /// (almost) fully collapsed; the 1px rule appears with it.
  void _onScroll() {
    final collapsed = _scroll.hasClients && _scroll.offset > _kCollapseOffset;
    final scrolled = _scroll.hasClients && _scroll.offset > 0;
    if (collapsed != _collapsed || scrolled != _scrolled) {
      setState(() {
        _collapsed = collapsed;
        _scrolled = scrolled;
      });
    }
  }

  // Room for the greeting and the date under it; the toolbar it collapses to is
  // the .large default of 64px.
  static const _kExpandedHeight = 168.0;
  static const _kCollapseOffset = _kExpandedHeight - 64.0 - 8;

  @override
  Widget build(BuildContext context) {
    final slotsAsync = ref.watch(scheduleSlotsProvider);
    final customAsync = ref.watch(customEntriesProvider);
    // Whichever half of the schedule failed is the one worth explaining.
    final loadError = slotsAsync.error ?? customAsync.error;
    final hasError = loadError != null;

    // Дома is the one screen that always has the whole timetable in hand, so it
    // is where the reminders are kept in step with it. `sync` compares against
    // what it last scheduled, so calling it on every build costs nothing.
    if (slotsAsync.hasValue && customAsync.hasValue) {
      unawaited(
        ref
            .read(remindersProvider.notifier)
            .sync(
              slots: slotsAsync.valueOrNull ?? const [],
              entries: customAsync.valueOrNull ?? const [],
              exams: ref.read(savedExamsProvider).valueOrNull ?? const [],
            ),
      );
    }
    // Only the first load leaves the hero with nothing to say; a refetch keeps
    // the card it already has rather than falling back to a spinner.
    final isLoading = !slotsAsync.hasValue || !customAsync.hasValue;

    final next = (hasError || isLoading)
        ? null
        : _resolveNextClass(
            buildAgendaItems(slotsAsync.valueOrNull ?? [], customAsync.valueOrNull ?? []),
            _now,
          );

    return Scaffold(
      body: AppRefresh(
        onRefresh: () async {
          ref.invalidate(scheduleSlotsProvider);
          ref.read(customEntriesProvider.notifier).reload();
          await ref.read(savedExamsProvider.notifier).load();
        },
        child: CustomScrollView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _titleBar(),
            SliverToBoxAdapter(child: _hero(loadError, isLoading, next)),
            SliverToBoxAdapter(child: _nextExam()),
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 100),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [SectionHeading('Оваа недела'), WeeklyAgenda()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Large title ───────────────────────────────────────────────────────────
  /// The greeting is the page's title — it is what the screen has to say. Дома
  /// is what it collapses to, so the tab still names itself once you scroll.
  Widget _titleBar() {
    return SliverAppBar.large(
      // Transparent at rest so the campus shows through; opaque the moment the
      // list starts moving, so content never scrolls under a see-through bar.
      // White rather than canvas — that is what the page is at its top.
      backgroundColor: _scrolled ? Colors.white : Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: AppColors.navy,
      centerTitle: true,
      expandedHeight: _kExpandedHeight,
      // Мој Распоред has no tab of its own any more — this is the way in.
      actions: [
        TextButton(
          onPressed: () => context.push('/schedule'),
          child: const Text(
            'Мој Распоред',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy),
          ),
        ),
        const ProfileMenu(),
        const SizedBox(width: 4),
      ],
      shape: _collapsed
          ? const Border(bottom: BorderSide(color: AppColors.border, width: 1))
          : null,
      title: _collapsed
          ? Text('Дома', style: AppType.toolbarTitle)
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        mkGreeting(_now, name: ref.watch(authControllerProvider).name),
                        style: AppType.greeting,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // The app's own drawn wave, tinted navy — not the system
                    // emoji, which renders in its own palette beside the serif.
                    SvgPicture.asset(
                      'assets/hand-wave.svg',
                      width: 21,
                      height: 21,
                      colorFilter: const ColorFilter.mode(AppColors.navy, BlendMode.srcIn),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(formatMkDate(todayIso()), style: AppType.subtitle),
              ],
            ),
    );
  }

  // ── Next saved exam ───────────────────────────────────────────────────────
  /// A compact strip for the soonest exam pinned on Мој Распоред, so Дома shows
  /// both classes and exams. Renders nothing when none are pinned or upcoming.
  Widget _nextExam() {
    final exams = ref.watch(savedExamsProvider).valueOrNull ?? [];
    final today = todayIso();
    final upcoming = exams.where((e) => e.date.compareTo(today) >= 0).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    if (upcoming.isEmpty) return const SizedBox.shrink();

    final exam = upcoming.first;
    final time = exam.start != null
        ? '${exam.start}${exam.end != null ? ' – ${exam.end}' : ''}'
        : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Text(
              'Следен испит',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.examAccent,
                letterSpacing: 0.4,
              ),
            ),
          ),
          ExamCard(
            title: exam.subjectName,
            border: AppColors.examAccent,
            margin: EdgeInsets.zero,
            facts: [
              ExamFact(
                SubjectIcons.date,
                formatMkDate(exam.date, longMonth: false),
                asset: SubjectIcons.dateAsset,
              ),
              if (time != null) ExamFact(SubjectIcons.time, time, strong: true),
              if (exam.rooms != null && exam.rooms!.isNotEmpty)
                ExamFact(SubjectIcons.room, exam.rooms!),
            ],
            trailing: CardDeleteButton(
              onTap: () => ref.read(savedExamsProvider.notifier).remove(exam.id),
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero card ─────────────────────────────────────────────────────────────
  Widget _hero(Object? error, bool isLoading, _NextClass? next) {
    if (error != null) {
      return ErrorStateView.from(
        error,
        scrollable: false,
        topGap: 24,
        onRetry: () {
          ref.invalidate(scheduleSlotsProvider);
          ref.read(customEntriesProvider.notifier).reload();
        },
      );
    }
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: 24, bottom: 24),
        child: Center(child: FinkiLoader()),
      );
    }
    if (next == null) return const SizedBox.shrink();

    final upcoming = next.minutesAway != null;
    final accent = upcoming ? lessonTypeStyle(next.item.type).accent : AppColors.faint;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.panel,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 14, 14, 14),
                    child: upcoming ? _heroUpcoming(next) : _heroNothingLeft(next.item),
                  ),
                ),
                // The day is done, and the art says the same thing the words
                // do: a dog with a coffee, resting.
                if (!upcoming)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Lottie.asset(AppArt.restingDog, width: 84, height: 84, repeat: true),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _heroUpcoming(_NextClass next) {
    final item = next.item;
    final room = item.room;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          mkRelativeTime(Duration(minutes: next.minutesAway!)),
          style: AppType.panelTitle.copyWith(fontSize: 27),
        ),
        const SizedBox(height: 10),
        Text(item.title, style: AppType.cardTitle),
        const SizedBox(height: 6),
        SubjectMetaRow(SubjectMeta(SubjectIcons.time, '${item.start} – ${item.end}')),
        const SizedBox(height: 4),
        SubjectMetaRow(
          SubjectMeta(
            SubjectIcons.type,
            lessonTypeLabel(item.type),
            asset: lessonTypeIconAsset(item.type),
          ),
        ),
        if (room != null && room.isNotEmpty) ...[
          const SizedBox(height: 4),
          SubjectMetaRow(
            SubjectMeta(SubjectIcons.room, room, onTap: () => findRoomOnMap(context, room)),
          ),
        ],
      ],
    );
  }

  Widget _heroNothingLeft(AgendaItem next) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Нема повеќе часови денес', style: AppType.panelTitle),
        const SizedBox(height: 4),
        Text(
          'Следен час во ${kDayNames[next.dayOfWeek].toLowerCase()}, ${next.start}',
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w400,
            color: AppColors.muted,
          ),
        ),
      ],
    );
  }
}

/// Picks what the hero card shows: the next class still to come today, or —
/// failing that — the first class of the next weekday that has one.
///
/// Returns null when the week holds no classes at all; the agenda below then
/// carries the empty state on its own.
_NextClass? _resolveNextClass(List<AgendaItem> items, DateTime now) {
  final onWeekdays = items.where((i) => i.dayOfWeek >= 0 && i.dayOfWeek <= 4).toList();
  if (onWeekdays.isEmpty) return null;

  final today = now.weekday - 1; // 0=Mon … 6=Sun
  final nowMinutes = now.hour * 60 + now.minute;

  AgendaItem? earliestOn(int day, {int after = -1}) {
    final list =
        onWeekdays.where((i) => i.dayOfWeek == day && agendaMinutes(i.start) > after).toList()
          ..sort((a, b) => agendaMinutes(a.start).compareTo(agendaMinutes(b.start)));
    return list.isEmpty ? null : list.first;
  }

  final laterToday = earliestOn(today, after: nowMinutes);
  if (laterToday != null) {
    return _NextClass(laterToday, agendaMinutes(laterToday.start) - nowMinutes);
  }

  // Nothing left today — look ahead a full week for the next day that has one.
  for (var offset = 1; offset <= 7; offset++) {
    final next = earliestOn((today + offset) % 7);
    if (next != null) return _NextClass(next, null);
  }
  return null;
}
