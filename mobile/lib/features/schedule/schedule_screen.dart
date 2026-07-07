import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/lesson_type.dart';
import '../../models/models.dart';
import '../timetable/timetable_providers.dart';
import 'schedule_providers.dart';
import '../../core/widgets/finki_loader.dart';

const _mkMonthsShort = [
  'јан', 'фев', 'мар', 'апр', 'мај', 'јун',
  'јул', 'авг', 'сеп', 'окт', 'ное', 'дек',
];
const _mkDaysLong = ['Недела', 'Понеделник', 'Вторник', 'Среда', 'Четврток', 'Петок', 'Сабота'];
const _mkDaysShort = ['Пон', 'Вто', 'Сре', 'Чет', 'Пет'];

String _formatExamDate(String iso) {
  final p = iso.split('-');
  if (p.length != 3) return iso;
  final d = DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
  return '${_mkDaysLong[d.weekday % 7]}, ${d.day} ${_mkMonthsShort[d.month - 1]}';
}

int _toMin(String hhmm) {
  final p = hhmm.split(':');
  return int.parse(p[0]) * 60 + int.parse(p[1]);
}

class _Item {
  final int dayOfWeek;
  final String start;
  final String end;
  final String title;
  final String type;
  final String? room;
  final String? professor;
  final int? customId; // null = saved slot, set = custom entry (deletable)
  _Item(this.dayOfWeek, this.start, this.end, this.title, this.type, this.room, this.professor,
      {this.customId});
}

class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slotsAsync = ref.watch(scheduleSlotsProvider);
    final customAsync = ref.watch(customEntriesProvider);
    final examsAsync = ref.watch(savedExamsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Мој Распоред')),
      floatingActionButton: _AddFab(
        onAdd: (type) => _showAddSheet(context, ref, type),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(scheduleSlotsProvider);
          ref.read(customEntriesProvider.notifier).reload();
          await ref.read(savedExamsProvider.notifier).load();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
          children: [
            _examsSection(context, ref, examsAsync),
            const SizedBox(height: 8),
            _legend(),
            const SizedBox(height: 8),
            _weekly(context, ref, slotsAsync, customAsync),
          ],
        ),
      ),
    );
  }

  // ── FAB add sheet ─────────────────────────────────────────────────────────
  void _showAddSheet(BuildContext context, WidgetRef ref, String entryType) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddEntrySheet(
        entryType: entryType,
        onSave: (data) async {
          await ref.read(customEntriesProvider.notifier).add(
                title: data['title']!,
                entryType: entryType,
                dayOfWeek: int.parse(data['dayOfWeek']!),
                startTime: data['startTime']!,
                endTime: data['endTime']!,
                room: data['room'],
                professor: data['professor'],
              );
        },
      ),
    );
  }

  // ── Pinned exams ──────────────────────────────────────────────────────────
  Widget _examsSection(BuildContext context, WidgetRef ref, AsyncValue<List<Exam>> async) {
    final exams = async.value ?? [];
    if (exams.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(children: [
              const Icon(Icons.assignment_outlined, size: 18, color: Color(0xFFE11D48)),
              const SizedBox(width: 8),
              const Text('Испити', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: const Color(0xFFFFE4E6), borderRadius: BorderRadius.circular(999)),
                child: Text('${exams.length}',
                    style: const TextStyle(
                        color: Color(0xFFE11D48), fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
          ...exams.map((e) => _examRow(ref, e)),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _examRow(WidgetRef ref, Exam e) {
    final time = e.start != null ? '${e.start}${e.end != null ? '–${e.end}' : ''}' : null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 5),
            width: 7, height: 7,
            decoration: const BoxDecoration(color: Color(0xFFE11D48), shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(e.subjectName,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
              const SizedBox(height: 2),
              Wrap(spacing: 10, children: [
                Text(_formatExamDate(e.date),
                    style: const TextStyle(color: AppColors.ink, fontSize: 12, fontWeight: FontWeight.w600)),
                if (time != null) Text(time, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                if (e.rooms != null) Text(e.rooms!, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
              ]),
            ]),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            iconSize: 18,
            color: AppColors.faint,
            icon: const Icon(Icons.close_rounded),
            onPressed: () => ref.read(savedExamsProvider.notifier).remove(e.id),
          ),
        ],
      ),
    );
  }

  // ── Legend ────────────────────────────────────────────────────────────────
  Widget _legend() {
    final items = {
      'Предавање': const Color(0xFF3B82F6),
      'Аудиториски вежби': const Color(0xFF8B5CF6),
      'Лабораториски вежби': const Color(0xFF10B981),
      'Комбинирано': const Color(0xFFF59E0B),
    };
    return Wrap(
      spacing: 8, runSpacing: 6,
      children: items.entries.map((e) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.hairline)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: e.value, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(e.key, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
        ]),
      )).toList(),
    );
  }

  // ── Weekly agenda ─────────────────────────────────────────────────────────
  Widget _weekly(BuildContext context, WidgetRef ref,
      AsyncValue<List<ScheduleSlot>> slotsAsync,
      AsyncValue<List<CustomEntry>> customAsync) {
    if (slotsAsync.isLoading || customAsync.isLoading) {
      return const Padding(
          padding: EdgeInsets.only(top: 60), child: Center(child: FinkiLoader()));
    }

    final items = <_Item>[
      ...(slotsAsync.value ?? []).map((s) => _Item(
            s.dayOfWeek, s.start, s.end,
            s.subject.baseName, s.subject.lessonType,
            s.classroom?.name,
            s.teachers.map((t) => t.displayName).where((n) => n.isNotEmpty).join(', '),
          )),
      ...(customAsync.value ?? []).map((c) => _Item(
            c.dayOfWeek, c.start, c.end, c.title, c.entryType, c.room, c.professor,
            customId: c.id,
          )),
    ];

    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 60),
        child: Column(children: [
          Icon(Icons.event_available_outlined, size: 44, color: AppColors.faint),
          SizedBox(height: 12),
          Text('Вашиот распоред е празен', style: TextStyle(color: AppColors.muted)),
          SizedBox(height: 4),
          Text('Додадете часови од Распоред', style: TextStyle(color: AppColors.faint, fontSize: 12)),
        ]),
      );
    }

    final totalMin = items.fold<int>(0, (sum, i) => sum + (_toMin(i.end) - _toMin(i.start)).clamp(0, 600));
    final hours = totalMin ~/ 60;
    final mins = totalMin % 60;

    final byDay = <int, List<_Item>>{};
    for (final i in items) {
      if (i.dayOfWeek >= 0 && i.dayOfWeek <= 4) (byDay[i.dayOfWeek] ??= []).add(i);
    }
    final conflictKeys = <String>{};
    for (final list in byDay.values) {
      list.sort((a, b) => _toMin(a.start).compareTo(_toMin(b.start)));
      for (var i = 0; i < list.length; i++) {
        for (var j = i + 1; j < list.length; j++) {
          if (_toMin(list[i].start) < _toMin(list[j].end) &&
              _toMin(list[j].start) < _toMin(list[i].end)) {
            conflictKeys.add('${list[i].dayOfWeek}-${list[i].start}-${list[i].title}');
            conflictKeys.add('${list[j].dayOfWeek}-${list[j].start}-${list[j].title}');
          }
        }
      }
    }

    final days = byDay.keys.toList()..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 4),
          child: Text(
            '${items.length} записи · ${hours}ч $mins мин неделно', // ignore: unnecessary_brace_in_string_interps
            style: const TextStyle(color: AppColors.muted, fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
        ),
        ...days.map((day) {
          final list = byDay[day]!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Row(children: [
                  Text(kDayNames[day],
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w800,
                          color: AppColors.navy, letterSpacing: 0.4)),
                  const SizedBox(width: 10),
                  const Expanded(child: Divider(color: AppColors.hairline, thickness: 1)),
                ]),
              ),
              ...list.map((i) {
                final conflict = conflictKeys.contains('${i.dayOfWeek}-${i.start}-${i.title}');
                return _entryCard(ref, i, conflict);
              }),
            ],
          );
        }),
      ],
    );
  }

  Widget _entryCard(WidgetRef ref, _Item i, bool conflict) {
    final style = lessonTypeStyle(i.type);
    return Dismissible(
      key: ValueKey('${i.customId ?? i.title}-${i.start}'),
      direction: i.customId != null ? DismissDirection.endToStart : DismissDirection.none,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) {
        if (i.customId != null) {
          ref.read(customEntriesProvider.notifier).delete(i.customId!);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border(
            left: BorderSide(color: conflict ? const Color(0xFFEF4444) : style.accent, width: 4),
          ),
          boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 4, offset: Offset(0, 1))],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(i.start, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                Text(i.end, style: const TextStyle(color: AppColors.faint, fontSize: 12)),
              ]),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(i.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.ink)),
                  const SizedBox(height: 5),
                  Wrap(spacing: 6, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: style.pillBg, borderRadius: BorderRadius.circular(999)),
                      child: Text(timetableTypeLabel(i.type),
                          style: TextStyle(
                              color: style.pillFg, fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                    if (conflict)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(999)),
                        child: const Text('Конфликт',
                            style: TextStyle(
                                color: Color(0xFFB91C1C), fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                    if (i.room != null && i.room!.isNotEmpty)
                      Text(i.room!, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                  ]),
                  if (i.professor != null && i.professor!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(i.professor!, style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
                  ],
                ]),
              ),
              if (i.customId != null)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  iconSize: 18,
                  color: AppColors.faint,
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: () => ref.read(customEntriesProvider.notifier).delete(i.customId!),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── FAB with two options ──────────────────────────────────────────────────────
class _AddFab extends StatefulWidget {
  final void Function(String type) onAdd;
  const _AddFab({required this.onAdd});

  @override
  State<_AddFab> createState() => _AddFabState();
}

class _AddFabState extends State<_AddFab> with SingleTickerProviderStateMixin {
  bool _open = false;
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _open = !_open);
    _open ? _ctrl.forward() : _ctrl.reverse();
  }

  void _pick(String type) {
    _toggle();
    widget.onAdd(type);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FadeTransition(
          opacity: _fade,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _miniBtn('Предавање', 'LECTURE', const Color(0xFF3B82F6)),
              const SizedBox(height: 10),
              _miniBtn('Аудиториски вежби', 'AUDITORY', const Color(0xFF8B5CF6)),
              const SizedBox(height: 10),
              _miniBtn('Лабораториски вежби', 'LAB', const Color(0xFF10B981)),
              const SizedBox(height: 16),
            ],
          ),
        ),
        FloatingActionButton(
          onPressed: _toggle,
          backgroundColor: AppColors.navy,
          child: AnimatedRotation(
            turns: _open ? 0.125 : 0,
            duration: const Duration(milliseconds: 220),
            child: const Icon(Icons.add_rounded, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _miniBtn(String label, String type, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 2))],
          ),
          child: Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: color)),
        ),
        const SizedBox(width: 10),
        FloatingActionButton.small(
          heroTag: type,
          onPressed: () => _pick(type),
          backgroundColor: color,
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
        ),
      ],
    );
  }
}

// ── Add entry bottom sheet ────────────────────────────────────────────────────
class _AddEntrySheet extends ConsumerStatefulWidget {
  final String entryType;
  final Future<void> Function(Map<String, String?> data) onSave;
  const _AddEntrySheet({required this.entryType, required this.onSave});

  @override
  ConsumerState<_AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends ConsumerState<_AddEntrySheet> {
  final _titleCtrl = TextEditingController();
  final _roomCtrl = TextEditingController();
  final _profCtrl = TextEditingController();
  String? _selectedSubject;
  String? _selectedTeacher;
  List<String> _subjectTeachers = [];
  bool _loadingTeachers = false;
  int _day = 0;
  TimeOfDay _start = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 9, minute: 30);
  bool _saving = false;
  String? _error;

  String get _typeLabel {
    switch (widget.entryType) {
      case 'LECTURE': return 'Предавање';
      case 'LAB': return 'Лабораториски вежби';
      case 'AUDITORY': return 'Аудиториски вежби';
      default: return widget.entryType;
    }
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  TimeOfDay? _parseTime(String hhmm) {
    final p = hhmm.split(':');
    if (p.length < 2) return null;
    final h = int.tryParse(p[0]);
    final m = int.tryParse(p[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _start : _end,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) setState(() => isStart ? _start = picked : _end = picked);
  }

  Future<void> _loadTeachersForSubject(String subjectName) async {
    final subjects = ref.read(filtersDataProvider).value?.subjects ?? [];
    final subject = subjects.firstWhere(
      (s) => s.baseName == subjectName,
      orElse: () => subjects.isNotEmpty ? subjects.first : Subject(id: 0, fullName: '', baseName: '', lessonType: ''),
    );
    if (subject.id == 0) return;
    setState(() { _loadingTeachers = true; _subjectTeachers = []; _selectedTeacher = null; _profCtrl.clear(); });
    try {
      final slots = await ref.read(apiProvider).getSlots(TimetableFilters(subjectId: subject.id));
      final names = slots
          .expand((s) => s.teachers)
          .map((t) => t.displayName)
          .where((n) => n.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
      // Auto-fill day, time, room and teacher from the subject's first real session.
      final sorted = [...slots]..sort((a, b) => a.dayOfWeek != b.dayOfWeek
          ? a.dayOfWeek.compareTo(b.dayOfWeek)
          : a.start.compareTo(b.start));
      final first = sorted.isEmpty ? null : sorted.first;
      if (mounted) {
        setState(() {
          _subjectTeachers = names;
          _loadingTeachers = false;
          if (first != null) {
            if (first.dayOfWeek >= 0 && first.dayOfWeek <= 4) _day = first.dayOfWeek;
            final s = _parseTime(first.start);
            final e = _parseTime(first.end);
            if (s != null) _start = s;
            if (e != null) _end = e;
            final room = first.classroom?.name;
            if (room != null && room.isNotEmpty) _roomCtrl.text = room;
            final teacher = first.teachers
                .map((t) => t.displayName)
                .firstWhere((n) => n.isNotEmpty, orElse: () => '');
            if (teacher.isNotEmpty) _selectedTeacher = teacher;
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingTeachers = false);
    }
  }

  Widget _subjectPicker() {
    final filtersAsync = ref.watch(filtersDataProvider);
    final subjects = filtersAsync.value?.subjects ?? [];
    final names = subjects
        .map((s) => s.baseName)
        .toSet()
        .toList()
      ..sort();

    if (names.isEmpty) {
      return TextField(
        controller: _titleCtrl,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Назив на предметот *'),
      );
    }

    return Autocomplete<String>(
      optionsBuilder: (text) {
        final q = text.text.toLowerCase();
        if (q.isEmpty) return names;
        return names.where((n) => n.toLowerCase().contains(q));
      },
      onSelected: (val) {
        setState(() => _selectedSubject = val);
        _loadTeachersForSubject(val);
      },
      fieldViewBuilder: (ctx, ctrl, focusNode, onSubmit) => TextField(
        controller: ctrl,
        focusNode: focusNode,
        autofocus: true,
        decoration: InputDecoration(
          labelText: 'Предмет *',
          suffixIcon: _selectedSubject != null
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () {
                    ctrl.clear();
                    setState(() => _selectedSubject = null);
                  },
                )
              : const Icon(Icons.arrow_drop_down_rounded),
        ),
      ),
      optionsViewBuilder: (ctx, onSelected, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (_, i) {
                final opt = options.elementAt(i);
                return ListTile(
                  dense: true,
                  title: Text(opt, style: const TextStyle(fontSize: 13)),
                  onTap: () => onSelected(opt),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _teacherPicker() {
    if (_loadingTeachers) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Row(children: [
          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
          SizedBox(width: 10),
          Text('Вчитување на предавачи…', style: TextStyle(color: AppColors.muted, fontSize: 13)),
        ]),
      );
    }

    // All teachers fallback if no subject selected yet
    final allTeachers = ref.read(filtersDataProvider).value?.teachers
            .map((t) => t.displayName)
            .where((n) => n.isNotEmpty)
            .toList() ??
        [];
    final options = _subjectTeachers.isNotEmpty ? _subjectTeachers : allTeachers;

    if (options.isEmpty) {
      return TextField(
        controller: _profCtrl,
        decoration: const InputDecoration(labelText: 'Предавач (опционално)'),
      );
    }

    return Autocomplete<String>(
      // Rebuild with the auto-filled teacher when subject/teacher changes
      key: ValueKey('teacher-$_selectedSubject-$_selectedTeacher'),
      initialValue:
          _selectedTeacher != null ? TextEditingValue(text: _selectedTeacher!) : null,
      optionsBuilder: (text) {
        final q = text.text.toLowerCase();
        if (q.isEmpty) return options;
        return options.where((n) => n.toLowerCase().contains(q));
      },
      onSelected: (val) => setState(() => _selectedTeacher = val),
      fieldViewBuilder: (ctx, ctrl, focusNode, _) => TextField(
        controller: ctrl,
        focusNode: focusNode,
        decoration: InputDecoration(
          labelText: 'Предавач (опционално)',
          suffixIcon: _selectedTeacher != null
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () {
                    ctrl.clear();
                    setState(() => _selectedTeacher = null);
                  },
                )
              : const Icon(Icons.arrow_drop_down_rounded),
        ),
      ),
      optionsViewBuilder: (ctx, onSelected, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (_, i) {
                final opt = options.elementAt(i);
                return ListTile(
                  dense: true,
                  title: Text(opt, style: const TextStyle(fontSize: 13)),
                  onTap: () => onSelected(opt),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final title = _selectedSubject ?? _titleCtrl.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Изберете или внесете назив');
      return;
    }
    setState(() { _saving = true; _error = null; });
    try {
      await widget.onSave({
        'title': title,
        'dayOfWeek': '$_day',
        'startTime': _fmt(_start),
        'endTime': _fmt(_end),
        'room': _roomCtrl.text.trim().isEmpty ? null : _roomCtrl.text.trim(),
        'professor': _selectedTeacher ?? (_profCtrl.text.trim().isEmpty ? null : _profCtrl.text.trim()),
      });
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      setState(() { _saving = false; _error = 'Не успеа зачувувањето'; });
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _roomCtrl.dispose();
    _profCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.hairline, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text('Додај $_typeLabel',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.navy)),
          const SizedBox(height: 18),
          _subjectPicker(),
          const SizedBox(height: 14),
          // Day picker
          DropdownButtonFormField<int>(
            initialValue: _day,
            decoration: const InputDecoration(labelText: 'Ден'),
            items: List.generate(5, (i) => DropdownMenuItem(value: i, child: Text(_mkDaysShort[i]))),
            onChanged: (v) => setState(() => _day = v!),
          ),
          const SizedBox(height: 14),
          // Time row
          Row(children: [
            Expanded(
              child: InkWell(
                onTap: () => _pickTime(true),
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Почеток'),
                  child: Text(_fmt(_start),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () => _pickTime(false),
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Крај'),
                  child: Text(_fmt(_end),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 14),
          TextField(
            controller: _roomCtrl,
            decoration: const InputDecoration(labelText: 'Просторија (опционално)'),
          ),
          const SizedBox(height: 14),
          _teacherPicker(),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 13)),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                  : const Text('Зачувај'),
            ),
          ),
        ],
      ),
    );
  }
}
