import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_refresh.dart';
import '../../core/widgets/back_arrow.dart';
import '../../core/widgets/app_dropdown.dart';
import '../../core/theme/lesson_type.dart';
import '../../core/utils/mk_date.dart';
import '../../core/widgets/delete_button.dart';
import '../../core/widgets/exam_card.dart';
import '../../core/widgets/labeled_field.dart';
import '../../core/widgets/profile_menu.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/subject_card.dart';
import '../../models/models.dart';
import 'schedule_providers.dart';
import 'widgets/weekly_agenda.dart';
import 'widgets/weekly_calendar.dart';
import '../../core/theme/app_shape.dart';

class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examsAsync = ref.watch(savedExamsProvider);

    return Scaffold(
      floatingActionButton: _AddFab(onAdd: (type) => _showAddSheet(context, ref, type)),
      body: Column(
        children: [
          const ScreenHeader(
            title: 'Мој Распоред',
            subtitle: 'Часовите и испитите што ги следите',
            leading: BackArrow(),
            actions: [ProfileMenu(), SizedBox(width: 4)],
          ),
          Expanded(
            child: AppRefresh(
              onRefresh: () async {
                ref.invalidate(scheduleSlotsProvider);
                ref.read(customEntriesProvider.notifier).reload();
                await ref.read(savedExamsProvider.notifier).load();
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                children: [
                  _examsSection(context, ref, examsAsync),
                  const SizedBox(height: 8),
                  const _ViewToggle(),
                  const SizedBox(height: 10),
                  if (ref.watch(scheduleViewProvider) == ScheduleView.calendar)
                    const WeeklyCalendar()
                  else
                    const WeeklyAgenda(),
                ],
              ),
            ),
          ),
        ],
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
          await ref
              .read(customEntriesProvider.notifier)
              .add(
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
    if (async.hasError) return _examsErrorRow(ref);
    final exams = async.valueOrNull ?? [];
    if (exams.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                SvgPicture.asset(
                  'assets/test.svg',
                  width: 18,
                  height: 18,
                  colorFilter: const ColorFilter.mode(AppColors.examAccent, BlendMode.srcIn),
                ),
                const SizedBox(width: 8),
                const Text('Испити', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.examSurface,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    '${exams.length}',
                    style: const TextStyle(
                      color: AppColors.examAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...exams.map((e) => _examRow(ref, e)),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _examsErrorRow(WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, size: 18, color: AppColors.faint),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Не може да се вчитаат зачуваните испити',
              style: TextStyle(color: AppColors.muted, fontSize: 12.5),
            ),
          ),
          TextButton(
            onPressed: () => ref.read(savedExamsProvider.notifier).load(),
            child: const Text('Обиди се повторно'),
          ),
        ],
      ),
    );
  }

  Widget _examRow(WidgetRef ref, Exam e) {
    final time = e.start != null ? '${e.start}${e.end != null ? '–${e.end}' : ''}' : null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: ExamCard(
        title: e.subjectName,
        border: AppColors.examAccent,
        margin: EdgeInsets.zero,
        facts: [
          ExamFact(
            SubjectIcons.date,
            formatMkDate(e.date, longMonth: false),
            asset: SubjectIcons.dateAsset,
          ),
          if (time != null) ExamFact(SubjectIcons.time, time, strong: true),
          if (e.rooms != null && e.rooms!.isNotEmpty) ExamFact(SubjectIcons.room, e.rooms!),
        ],
        trailing: CardDeleteButton(
          onTap: () {
            HapticFeedback.selectionClick();
            ref.read(savedExamsProvider.notifier).remove(e.id);
          },
        ),
      ),
    );
  }
}

/// Grid or list — the same week, read two ways.
///
/// Not a setting buried in a menu: which one you want depends on what you are
/// doing right now (planning vs. checking), so it sits on the screen it changes.
class _ViewToggle extends ConsumerWidget {
  const _ViewToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(scheduleViewProvider);

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Row(
        children: [
          _option(ref, view, ScheduleView.calendar, Icons.calendar_view_week_rounded, 'Календар'),
          _option(ref, view, ScheduleView.list, Icons.view_agenda_outlined, 'Список'),
        ],
      ),
    );
  }

  Widget _option(
    WidgetRef ref,
    ScheduleView current,
    ScheduleView value,
    IconData icon,
    String label,
  ) {
    final selected = current == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (selected) return;
          HapticFeedback.selectionClick();
          ref.read(scheduleViewProvider.notifier).state = value;
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.chip),
            boxShadow: selected
                ? const [BoxShadow(color: Color(0x14000000), blurRadius: 3, offset: Offset(0, 1))]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: selected ? AppColors.navy : AppColors.muted),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColors.navy : AppColors.muted,
                ),
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
    HapticFeedback.lightImpact();
    setState(() => _open = !_open);
    _open ? _ctrl.forward() : _ctrl.reverse();
  }

  void _pick(String type) {
    HapticFeedback.selectionClick();
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
              _miniBtn(kLessonTypeLabels['LAB']!, 'LAB', lessonTypeStyle('LAB').accent),
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
            borderRadius: BorderRadius.circular(AppRadius.pill),
            boxShadow: const [
              BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: color),
          ),
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
/// A plain form: type what the class is called, when it runs and where, and it
/// lands on Мој Распоред. Nothing is looked up and nothing is locked.
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
  int _day = 0;
  TimeOfDay _start = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 9, minute: 30);
  bool _saving = false;
  String? _error;

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  int _minutes(TimeOfDay t) => t.hour * 60 + t.minute;

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _start : _end,
      builder: (ctx, child) =>
          MediaQuery(data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true), child: child!),
    );
    if (picked != null) setState(() => isStart ? _start = picked : _end = picked);
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Внесете назив на предметот');
      return;
    }
    if (_minutes(_end) <= _minutes(_start)) {
      setState(() => _error = 'Крајот мора да биде по почетокот');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final room = _roomCtrl.text.trim();
      await widget.onSave({
        'title': title,
        'dayOfWeek': '$_day',
        'startTime': _fmt(_start),
        'endTime': _fmt(_end),
        'room': room.isEmpty ? null : room,
      });
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      setState(() {
        _saving = false;
        _error = 'Не успеа зачувувањето';
      });
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _roomCtrl.dispose();
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.hairline,
                  borderRadius: BorderRadius.circular(AppRadius.grabber),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Додај ${lessonTypeLabel(widget.entryType)}',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 18),
            LabeledField(
              label: 'Предмет *',
              child: TextField(
                controller: _titleCtrl,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
              ),
            ),
            const SizedBox(height: 14),
            AppDropdown<int>(
              label: 'Ден',
              value: _day,
              options: [for (var i = 0; i < 5; i++) (i, kDayNames[i])],
              onChanged: (v) => setState(() => _day = v ?? _day),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _pickTime(true),
                    borderRadius: BorderRadius.circular(AppRadius.control),
                    child: LabeledField(
                      label: 'Почеток',
                      child: InputDecorator(
                        decoration: const InputDecoration(),
                        child: Text(
                          _fmt(_start),
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _pickTime(false),
                    borderRadius: BorderRadius.circular(AppRadius.control),
                    child: LabeledField(
                      label: 'Крај',
                      child: InputDecorator(
                        decoration: const InputDecoration(),
                        child: Text(
                          _fmt(_end),
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            LabeledField(
              label: 'Просторија (опционално)',
              child: TextField(
                controller: _roomCtrl,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _save(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: AppColors.dangerInk, fontSize: 13)),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                      )
                    : const Text('Зачувај'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
