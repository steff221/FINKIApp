import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/models.dart';
import '../schedule/schedule_providers.dart';
import 'exams_providers.dart';

const _mkMonthsLong = [
  'Јануари', 'Февруари', 'Март', 'Април', 'Мај', 'Јуни',
  'Јули', 'Август', 'Септември', 'Октомври', 'Ноември', 'Декември',
];
const _mkDaysLong = ['Недела', 'Понеделник', 'Вторник', 'Среда', 'Четврток', 'Петок', 'Сабота'];

String _dateHeading(String iso) {
  final p = iso.split('-');
  if (p.length != 3) return iso;
  final d = DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
  return '${_mkDaysLong[d.weekday % 7]}, ${d.day} ${_mkMonthsLong[d.month - 1]} ${d.year}';
}

class ExamsScreen extends ConsumerStatefulWidget {
  const ExamsScreen({super.key});

  @override
  ConsumerState<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends ConsumerState<ExamsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(examSessionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Испити')),
      body: sessionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _centeredMessage('Не може да се вчитаат испитите'),
        data: (sessions) {
          if (sessions.isEmpty) {
            return _centeredMessage('Сè уште нема внесен распоред за испити.');
          }
          final selected = ref.watch(selectedSessionProvider) ?? sessions.first;
          return Column(
            children: [
              if (sessions.length > 1) _sessionTabs(sessions, selected),
              _searchField(),
              Expanded(child: _examsList(selected)),
            ],
          );
        },
      ),
    );
  }

  Widget _sessionTabs(List<String> sessions, String selected) {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
        itemCount: sessions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final s = sessions[i];
          final active = s == selected;
          return GestureDetector(
            onTap: () => ref.read(selectedSessionProvider.notifier).state = s,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? AppColors.navy : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: active ? AppColors.navy : AppColors.border),
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
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      child: TextField(
        onChanged: (v) => setState(() => _query = v),
        decoration: InputDecoration(
          hintText: 'Пребарај по предмет или просторија…',
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
        ),
      ),
    );
  }

  Widget _examsList(String session) {
    final examsAsync = ref.watch(examsProvider(session));
    return examsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _centeredMessage('Грешка при вчитување'),
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
          return _centeredMessage(q.isEmpty ? 'Нема испити' : 'Нема резултати за „$_query“');
        }

        // Group by date, sorted.
        final byDate = <String, List<Exam>>{};
        for (final e in filtered) {
          (byDate[e.date] ??= []).add(e);
        }
        final dates = byDate.keys.toList()..sort();

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 28),
          itemCount: dates.length,
          itemBuilder: (context, i) {
            final date = dates[i];
            final dayExams = byDate[date]!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: i == 0 ? 4 : 16, bottom: 8),
                  child: Row(children: [
                    Expanded(
                      child: Text(_dateHeading(date),
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.navy)),
                    ),
                    Text('${dayExams.length} ${dayExams.length == 1 ? 'испит' : 'испити'}',
                        style: const TextStyle(fontSize: 12, color: AppColors.faint)),
                  ]),
                ),
                ...dayExams.map((e) => _ExamCard(exam: e)),
              ],
            );
          },
        );
      },
    );
  }

  Widget _centeredMessage(String text) => ListView(children: [
        const SizedBox(height: 100),
        const Icon(Icons.assignment_outlined, size: 44, color: AppColors.faint),
        const SizedBox(height: 12),
        Center(child: Text(text, style: const TextStyle(color: AppColors.muted))),
      ]);
}

class _ExamCard extends ConsumerWidget {
  final Exam exam;
  const _ExamCard({required this.exam});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(savedExamIdsProvider).contains(exam.id);
    final time = exam.start != null ? '${exam.start}${exam.end != null ? '–${exam.end}' : ''}' : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(exam.subjectName,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, height: 1.25)),
                  const SizedBox(height: 6),
                  Wrap(spacing: 12, runSpacing: 4, children: [
                    if (time != null)
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.schedule_rounded, size: 13, color: AppColors.faint),
                        const SizedBox(width: 4),
                        Text(time,
                            style: const TextStyle(
                                fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.ink)),
                      ]),
                    if (exam.rooms != null)
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.place_outlined, size: 13, color: AppColors.faint),
                        const SizedBox(width: 4),
                        Text(exam.rooms!, style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
                      ]),
                  ]),
                  if (exam.note != null && exam.note!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(exam.note!, style: const TextStyle(fontSize: 11.5, color: AppColors.faint)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            _PinButton(
              saved: saved,
              onTap: () {
                final ctrl = ref.read(savedExamsProvider.notifier);
                saved ? ctrl.remove(exam.id) : ctrl.add(exam);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PinButton extends StatelessWidget {
  final bool saved;
  final VoidCallback onTap;
  const _PinButton({required this.saved, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: saved ? AppColors.navy : Colors.white,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: saved ? AppColors.navy : AppColors.border),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 160),
          transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
          child: Icon(
            saved ? Icons.check_rounded : Icons.add_rounded,
            key: ValueKey(saved),
            size: 17,
            color: saved ? Colors.white : AppColors.navy,
          ),
        ),
      ),
    );
  }
}
