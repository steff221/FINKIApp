import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_type.dart';
import '../../core/theme/lesson_type.dart';
import '../../core/widgets/app_refresh.dart';
import '../../core/widgets/finki_loader.dart';
import '../../core/widgets/page_background.dart';
import '../../core/widgets/profile_menu.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/state_views.dart';
import '../../models/models.dart';
import 'subject_offerings_screen.dart';
import 'timetable_providers.dart';
import 'widgets/filter_sheet.dart';

/// One subject on offer, and every time it runs.
typedef _Subject = ({String name, List<ScheduleSlot> slots});

/// Распоред — the faculty's offer, browsed the way a student thinks about it:
/// pick the kind of class, find the subject, then choose which of its terms to
/// take. The flat day-by-day list this replaced meant scrolling 234 cards to
/// find one subject's lectures.
class TimetableScreen extends ConsumerStatefulWidget {
  const TimetableScreen({super.key});

  @override
  ConsumerState<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends ConsumerState<TimetableScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _search.clear();
    setState(() => _query = '');
  }

  /// Gathers the slots into the subjects they belong to.
  ///
  /// A COMBINED class (`п+ав`) is both a lecture and an exercise, so it is
  /// listed under whichever of the two is being browsed rather than hidden from
  /// both.
  List<_Subject> _subjects(List<ScheduleSlot> slots, String type) {
    final needle = _query.trim().toLowerCase();
    final byName = <String, List<ScheduleSlot>>{};
    for (final slot in slots) {
      final slotType = slot.subject.lessonType;
      if (slotType != type && slotType != 'COMBINED') continue;
      final name = slot.subject.baseName;
      if (needle.isNotEmpty && !name.toLowerCase().contains(needle)) continue;
      (byName[name] ??= []).add(slot);
    }
    final names = byName.keys.toList()..sort();
    return [for (final name in names) (name: name, slots: byName[name]!)];
  }

  @override
  Widget build(BuildContext context) {
    final slotsAsync = ref.watch(slotsProvider);
    final filters = ref.watch(filtersProvider);
    final type = ref.watch(browseTypeProvider);

    return Scaffold(
      body: Column(
        children: [
          ScreenHeader(
            title: 'Распоред',
            subtitle: 'Целата понуда на факултетот',
            actions: [
              _FilterButton(
                active: filters.activeCount,
                onTap: () => showFilterSheet(context),
              ),
              const ProfileMenu(),
              const SizedBox(width: 4),
            ],
          ),
          const _TypeSegments(),
          _searchField(),
          // Sits above the list rather than in it, so the filters in force stay
          // visible while the subjects scroll.
          const _ActiveFilterBar(),
          Expanded(
            child: AppRefresh(
              onRefresh: () async {
                ref.invalidate(slotsProvider);
                await ref.read(slotsProvider.future);
              },
              child: slotsAsync.when(
                loading: () => const _LoadingState(),
                error: (e, _) => ErrorStateView.from(
                  e,
                  onRetry: () => ref.invalidate(slotsProvider),
                ),
                data: (slots) {
                  final subjects = _subjects(slots, type);
                  if (subjects.isEmpty) {
                    return _query.isEmpty
                        ? _EmptyResult(filters: filters)
                        : EmptyStateView(
                            icon: Icons.search_off_rounded,
                            title: 'Нема резултати за „$_query“',
                            action: TextButton(
                              onPressed: _clearSearch,
                              child: const Text('Исчисти пребарување'),
                            ),
                          );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: subjects.length,
                    itemBuilder: (context, i) => _SubjectRow(subject: subjects[i]),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: TextField(
        controller: _search,
        onChanged: (v) => setState(() => _query = v),
        decoration: InputDecoration(
          hintText: 'Пребарај предмет…',
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
}

/// Nothing matched. When filters are on, the way out is offered here rather
/// than leaving the student to work out which one is too narrow.
class _EmptyResult extends ConsumerWidget {
  final TimetableFilters filters;
  const _EmptyResult({required this.filters});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (filters.isEmpty) {
      return const EmptyStateView(
        icon: Icons.event_busy_outlined,
        title: 'Нема часови во распоредот',
      );
    }
    return EmptyStateView(
      icon: Icons.event_busy_outlined,
      title: 'Нема часови за избраните филтри',
      subtitle: 'Тргнете некој филтер за да видите повеќе часови',
      action: TextButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          ref.read(filtersProvider.notifier).state =
              TimetableFilters(editionNumber: filters.editionNumber);
        },
        child: const Text('Исчисти ги филтрите'),
      ),
    );
  }
}

// ── Kind of class ───────────────────────────────────────────────────────────

/// Предавање or Аудиториски вежби. Лабораториски вежби are not offered yet —
/// the faculty publishes none, so a third segment would always be empty.
class _TypeSegments extends ConsumerWidget {
  const _TypeSegments();

  static const _types = ['LECTURE', 'EXERCISE'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(browseTypeProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
      child: Row(
        children: [
          for (final type in _types) ...[
            if (type != _types.first) const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (type == selected) return;
                  HapticFeedback.selectionClick();
                  ref.read(browseTypeProvider.notifier).state = type;
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: type == selected ? AppColors.navy : AppColors.field,
                    borderRadius: BorderRadius.circular(AppRadius.control),
                  ),
                  child: Text(
                    kLessonTypeLabels[type]!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: type == selected ? Colors.white : AppColors.muted,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Subjects ────────────────────────────────────────────────────────────────

/// One subject in the browse list: its name, and how many times it runs.
class _SubjectRow extends StatelessWidget {
  final _Subject subject;
  const _SubjectRow({required this.subject});

  @override
  Widget build(BuildContext context) {
    final count = subject.slots.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      // The same card every list in the app uses — tinted, raised, no outline.
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        title: Text(subject.name, style: AppType.cardTitle),
        subtitle: Text(
          '$count ${count == 1 ? 'термин' : 'термини'}',
          style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.faint),
        onTap: () => Navigator.of(context).push(
          // Wrapped so the pushed page is opaque: the shared background lives
          // behind the router, and a see-through route would show this list
          // through it for the length of the transition.
          MaterialPageRoute(
            builder: (_) => PageBackground(
              child: SubjectOfferingsScreen(
                baseName: subject.name,
                slots: subject.slots,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Active filters ──────────────────────────────────────────────────────────

/// The filters in force, as chips that remove themselves when tapped.
///
/// The toolbar badge only says *how many* are on; this says which, and lets
/// them go one at a time without a trip through the sheet. The day filter is
/// left out — the strip above already carries it.
class _ActiveFilterBar extends ConsumerWidget {
  const _ActiveFilterBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(filtersProvider);
    // Names for the id-valued filters, and only for those — watching this
    // unconditionally would fetch the whole option set on every visit to the
    // screen. By the time one of them is set the sheet has been open, so the
    // options are already cached.
    final needsNames = filters.teacherId != null ||
        filters.subjectId != null ||
        filters.classroomId != null;
    final data = needsNames ? ref.watch(filtersDataProvider).value : null;

    void update(TimetableFilters next) =>
        ref.read(filtersProvider.notifier).state = next;

    final chips = <Widget>[];
    void add(String label, TimetableFilters cleared) => chips.add(
          _FilterChip(label: label, onRemove: () => update(cleared)),
        );

    if (filters.year != null) {
      add('${filters.year} година', filters.copyWith(year: () => null));
    }
    if (filters.programmeCode != null) {
      add(filters.programmeCode!, filters.copyWith(programmeCode: () => null));
    }
    if (filters.teacherId != null) {
      add(_nameOf(data?.teachers, filters.teacherId!, (t) => t.id, (t) => t.displayName) ??
          'Предавач',
          filters.copyWith(teacherId: () => null));
    }
    if (filters.subjectId != null) {
      add(_nameOf(data?.subjects, filters.subjectId!, (s) => s.id, (s) => s.baseName) ??
          'Предмет',
          filters.copyWith(subjectId: () => null));
    }
    if (filters.classroomId != null) {
      add(_nameOf(data?.classrooms, filters.classroomId!, (c) => c.id, (c) => c.name) ??
          'Просторија',
          filters.copyWith(classroomId: () => null));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 10, 8, 0),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  for (var i = 0; i < chips.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    chips[i],
                  ],
                ],
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              // The day strip is its own control; clearing the chips leaves the
              // selected day alone.
              update(TimetableFilters(
                dayOfWeek: filters.dayOfWeek,
                editionNumber: filters.editionNumber,
              ));
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.navy,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Исчисти',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

/// Looks up the display name for an id-valued filter, or null while the filter
/// options are still loading — the chip then names the field instead.
String? _nameOf<T>(
  List<T>? items,
  int id,
  int Function(T) idOf,
  String Function(T) nameOf,
) {
  if (items == null) return null;
  for (final item in items) {
    if (idOf(item) == id) return nameOf(item);
  }
  return null;
}

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _FilterChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: () {
          HapticFeedback.selectionClick();
          onRemove();
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 170),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.navy),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.close_rounded, size: 14, color: AppColors.faint),
            ],
          ),
        ),
      ),
    );
  }
}


class _FilterButton extends StatelessWidget {
  final int active;
  final VoidCallback onTap;
  const _FilterButton({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: onTap,
          tooltip: 'Филтри',
          icon: SvgPicture.asset(
            'assets/settings-sliders.svg',
            width: 22,
            height: 22,
            colorFilter: const ColorFilter.mode(AppColors.navy, BlendMode.srcIn),
          ),
        ),
        if (active > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: AppColors.bright, shape: BoxShape.circle),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text('$active',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
            ),
          ),
      ],
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();
  @override
  Widget build(BuildContext context) => const Center(child: FinkiLoader());
}
