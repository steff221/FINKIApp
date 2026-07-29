import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_type.dart';
import '../../core/utils/mk_date.dart';
import '../../core/widgets/app_refresh.dart';
import '../../core/widgets/entrance_fade.dart';
import '../../core/widgets/exam_card.dart';
import '../../core/widgets/finki_loader.dart';
import '../../core/widgets/profile_menu.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/save_chip.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/subject_card.dart';
import '../../models/models.dart';
import '../schedule/schedule_providers.dart';
import 'exam_rows.dart';
import 'exams_providers.dart';

class ExamsScreen extends ConsumerStatefulWidget {
  const ExamsScreen({super.key});

  @override
  ConsumerState<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends ConsumerState<ExamsScreen> {
  final _search = TextEditingController();
  String _query = '';

  /// Exams already sat are folded away by default — a session keeps them for
  /// the whole term, and they push what is still ahead off the screen.
  bool _showPast = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Clears both the filter and the box the student typed into.
  void _clearSearch() {
    _search.clear();
    setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(examSessionsProvider);

    final sessions = sessionsAsync.valueOrNull ?? const <String>[];
    final selected =
        sessions.isEmpty ? null : (ref.watch(selectedSessionProvider) ?? sessions.first);
    final loaded = selected == null ? null : ref.watch(examsProvider(selected)).value;

    return Scaffold(
      body: Column(
        children: [
          ScreenHeader(
            title: 'Испити',
            subtitle: selected == null
                ? null
                : loaded == null
                    ? selected
                    : '$selected · ${mkExamCount(loaded.length)}',
            actions: const [ProfileMenu(), SizedBox(width: 4)],
          ),
          Expanded(
            child: sessionsAsync.when(
              loading: () => const Center(child: FinkiLoader()),
              error: (e, _) => ErrorStateView.from(
                e,
                onRetry: () => ref.invalidate(examSessionsProvider),
              ),
              data: (sessions) {
                if (sessions.isEmpty) {
                  return const EmptyStateView(
                    icon: Icons.assignment_outlined,
                    title: 'Сè уште нема распоред за испити',
                    subtitle: 'Штом факултетот го објави, ќе се појави тука.',
                  );
                }
                return Column(
                  children: [
                    if (sessions.length > 1) _sessionTabs(sessions, selected!),
                    _searchField(),
                    Expanded(child: _examsList(selected!)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _sessionTabs(List<String> sessions, String selected) {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        itemCount: sessions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final s = sessions[i];
          final active = s == selected;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(selectedSessionProvider.notifier).state = s;
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                // Unselected sessions sit in the page as recesses; the chosen
                // one lifts out of it in navy.
                color: active ? AppColors.navy : AppColors.field,
                borderRadius: BorderRadius.circular(AppRadius.control),
              ),
              child: Text(s,
                  style: TextStyle(
                      color: active ? Colors.white : AppColors.muted,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ),
          );
        },
      ),
    );
  }

  Widget _searchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        controller: _search,
        onChanged: (v) => setState(() => _query = v),
        decoration: InputDecoration(
          hintText: 'Пребарај по предмет или просторија…',
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  iconSize: 18,
                  color: AppColors.faint,
                  tooltip: 'Исчисти',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: _clearSearch,
                ),
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
        ),
      ),
    );
  }

  Widget _examsList(String session) {
    final examsAsync = ref.watch(examsProvider(session));
    return AppRefresh(
      onRefresh: () async {
        ref.invalidate(examsProvider(session));
        await ref.read(examsProvider(session).future);
      },
      child: examsAsync.when(
        loading: () => const Center(child: FinkiLoader()),
        error: (e, _) => ErrorStateView.from(
          e,
          onRetry: () => ref.invalidate(examsProvider(session)),
        ),
        data: (exams) {
          final q = _query.trim().toLowerCase();
          final filtered = q.isEmpty
              ? exams
              : exams
                  .where((e) =>
                      e.subjectName.toLowerCase().contains(q) ||
                      (e.rooms ?? '').toLowerCase().contains(q))
                  .toList();

          if (filtered.isEmpty) {
            return q.isEmpty
                ? const EmptyStateView(
                    icon: Icons.event_available_outlined,
                    title: 'Нема испити за оваа сесија',
                  )
                : EmptyStateView(
                    icon: Icons.search_off_rounded,
                    title: 'Нема резултати за „$_query“',
                    action: TextButton(
                      onPressed: _clearSearch,
                      child: const Text('Исчисти пребарување'),
                    ),
                  );
          }

          final rows = buildExamRows(filtered, today: todayIso(), showPast: _showPast);
          // Fading what is behind you only reads as "behind you" next to
          // something that is not. When the whole session is over, dimming
          // every card would just make the screen look disabled.
          final anyUpcoming = rows.any((r) => r is ExamCardRow && !r.past);

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: rows.length,
            itemBuilder: (context, i) => switch (rows[i]) {
              ExamDateRow(
                :final date,
                :final count,
                :final countdown,
                :final highlight,
                :final past
              ) =>
                _DateHeading(
                  date: date,
                  count: count,
                  countdown: countdown,
                  highlight: highlight,
                  past: past && anyUpcoming,
                ),
              ExamNoticeRow(:final text) => _Notice(text),
              ExamPastRow(:final count, :final expanded, :final toggleable) => _PastHeading(
                  count: count,
                  expanded: expanded,
                  onTap: toggleable
                      ? () {
                          HapticFeedback.selectionClick();
                          setState(() => _showPast = !_showPast);
                        }
                      : null,
                ),
              ExamCardRow(:final exam, :final highlight, :final past) => Entrance(
                  delayMs: (i * 35).clamp(0, 420),
                  child: _ExamCard(
                      exam: exam, highlight: highlight, past: past && anyUpcoming),
                ),
            },
          );
        },
      ),
    );
  }
}

// ── Headings ────────────────────────────────────────────────────────────────

class _DateHeading extends StatelessWidget {
  final String date;
  final int count;
  final String? countdown;
  final bool highlight;
  final bool past;

  const _DateHeading({
    required this.date,
    required this.count,
    required this.countdown,
    required this.highlight,
    required this.past,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(children: [
        Flexible(
          child: Text(
            formatMkDate(date),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: highlight
                  ? AppColors.examAccent
                  : past
                      ? AppColors.faint
                      : AppColors.navy,
            ),
          ),
        ),
        if (countdown != null) _DateTag(countdown!),
        const Spacer(),
        Text(mkExamCount(count),
            style: const TextStyle(fontSize: 12, color: AppColors.faint)),
      ]),
    );
  }
}

/// Small rose pill next to a date heading: how far off it is.
class _DateTag extends StatelessWidget {
  final String label;
  const _DateTag(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.examSurface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(label,
          style: const TextStyle(
              color: AppColors.examAccent, fontSize: 10.5, fontWeight: FontWeight.w700)),
    );
  }
}

class _Notice extends StatelessWidget {
  final String text;
  const _Notice(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 2),
      child: Text(text,
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted)),
    );
  }
}

/// Divider row that folds the already-sat exams away.
class _PastHeading extends StatelessWidget {
  final int count;
  final bool expanded;

  /// Null when the past is all there is — the row is then a plain label.
  final VoidCallback? onTap;

  const _PastHeading({required this.count, required this.expanded, this.onTap});

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Row(children: [
        Text('Поминати', style: AppType.section),
        const SizedBox(width: 8),
        Text(mkExamCount(count),
            style: const TextStyle(fontSize: 12.5, color: AppColors.faint)),
        const Spacer(),
        if (onTap != null)
          Icon(expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
              size: 22, color: AppColors.muted),
      ]),
    );

    if (onTap == null) return row;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.chip),
      child: row,
    );
  }
}

// ── Card ────────────────────────────────────────────────────────────────────

class _ExamCard extends ConsumerWidget {
  final Exam exam;

  /// On the nearest date still ahead — carries the rose accent.
  final bool highlight;

  /// Already sat: dimmed, so it reads as reference rather than as something to
  /// prepare for.
  final bool past;

  const _ExamCard({required this.exam, this.highlight = false, this.past = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(savedExamIdsProvider).contains(exam.id);
    final time =
        exam.start != null ? '${exam.start}${exam.end != null ? '–${exam.end}' : ''}' : null;

    final card = ExamCard(
      title: exam.subjectName,
      border: highlight ? AppColors.examAccent : AppColors.border,
      facts: [
        if (time != null) ExamFact(SubjectIcons.time, time, strong: true),
        if (exam.rooms != null && exam.rooms!.isNotEmpty)
          ExamFact(SubjectIcons.room, exam.rooms!),
      ],
      note: exam.note,
      // The chip both pins and unpins, so the card needs no second control to
      // undo it.
      trailing: SaveChip(
        size: 30,
        saved: saved,
        onTap: () {
          HapticFeedback.lightImpact();
          final ctrl = ref.read(savedExamsProvider.notifier);
          saved ? ctrl.remove(exam.id) : ctrl.add(exam);
        },
      ),
    );

    return past ? Opacity(opacity: 0.6, child: card) : card;
  }
}
