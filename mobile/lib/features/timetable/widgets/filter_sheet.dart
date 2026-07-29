import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../models/models.dart';
import '../timetable_providers.dart';
import '../../../core/theme/app_shape.dart';

Future<void> showFilterSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _FilterSheet(),
  );
}

class _FilterSheet extends ConsumerWidget {
  const _FilterSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(filtersProvider);
    final dataAsync = ref.watch(filtersDataProvider);

    void update(TimetableFilters f) => ref.read(filtersProvider.notifier).state = f;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.92,
      builder: (context, scrollController) => Column(
        children: [
          const SizedBox(height: 10),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(AppRadius.grabber))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
            child: Row(
              children: [
                const Icon(Icons.tune_rounded, size: 18, color: AppColors.navy),
                const SizedBox(width: 8),
                const Text('Филтри', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const Spacer(),
                TextButton(
                  onPressed: () => update(const TimetableFilters()),
                  child: const Text('Ресетирај'),
                ),
              ],
            ),
          ),
          Expanded(
            child: dataAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Грешка: $e')),
              data: (d) => ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                children: [
                  _dropdown<int>(
                    label: 'Година',
                    value: filters.year,
                    options: d.years.map((y) => (y, '$y година')).toList(),
                    onChanged: (v) => update(filters.copyWith(year: () => v)),
                  ),
                  _dropdown<String>(
                    label: 'Насока',
                    value: filters.programmeCode,
                    options: d.programmes.map((p) => (p, p)).toList(),
                    onChanged: (v) => update(filters.copyWith(programmeCode: () => v)),
                  ),
                  _dropdown<int>(
                    label: 'Ден',
                    value: filters.dayOfWeek,
                    options: [
                      for (var i = 0; i < kDayNames.length; i++) (i, kDayNames[i]),
                    ],
                    onChanged: (v) => update(filters.copyWith(dayOfWeek: () => v)),
                  ),
                  _dropdown<int>(
                    label: 'Предавач',
                    value: filters.teacherId,
                    options: d.teachers
                        .where((t) => t.displayName.isNotEmpty)
                        .map((t) => (t.id, t.displayName))
                        .toList(),
                    onChanged: (v) => update(filters.copyWith(teacherId: () => v)),
                  ),
                  _dropdown<int>(
                    label: 'Предмет',
                    value: filters.subjectId,
                    options: _uniqueSubjects(d.subjects).map((s) => (s.id, s.baseName)).toList(),
                    onChanged: (v) => update(filters.copyWith(subjectId: () => v)),
                  ),
                  _dropdown<int>(
                    label: 'Просторија',
                    value: filters.classroomId,
                    options: d.classrooms.map((c) => (c.id, c.name)).toList(),
                    onChanged: (v) => update(filters.copyWith(classroomId: () => v)),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Прикажи резултати'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // De-duplicate subjects by baseName so the same subject isn't listed per type.
  List<Subject> _uniqueSubjects(List<Subject> subjects) {
    final seen = <String>{};
    final out = <Subject>[];
    for (final s in subjects) {
      if (seen.add(s.baseName)) out.add(s);
    }
    return out;
  }

  Widget _dropdown<T>({
    required String label,
    required T? value,
    required List<(T, String)> options,
    required ValueChanged<T?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AppDropdown<T>(
        label: label,
        value: value,
        options: options,
        emptyLabel: 'Сите',
        onChanged: onChanged,
      ),
    );
  }
}
