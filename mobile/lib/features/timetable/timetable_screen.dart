import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/finki_loader.dart';
import '../../models/models.dart';
import 'timetable_providers.dart';
import 'widgets/filter_sheet.dart';
import 'widgets/slot_card.dart';

class TimetableScreen extends ConsumerWidget {
  const TimetableScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slotsAsync = ref.watch(slotsProvider);
    final filters = ref.watch(filtersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Распоред'),
        actions: [
          _FilterButton(
            active: filters.activeCount,
            onTap: () => showFilterSheet(context),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle_outlined),
            onSelected: (v) {
              if (v == 'logout') ref.read(authControllerProvider.notifier).logout();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: Text(ref.read(authControllerProvider).email ?? '',
                    style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              ),
              const PopupMenuItem(value: 'logout', child: Text('Одјави се')),
            ],
          ),
          const SizedBox(width: 4),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(52),
          child: _DayStrip(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(slotsProvider);
          await ref.read(slotsProvider.future);
        },
        child: slotsAsync.when(
          loading: () => const _LoadingState(),
          error: (e, _) => _ErrorState(onRetry: () => ref.invalidate(slotsProvider)),
          data: (slots) => slots.isEmpty
              ? const _EmptyState()
              : _SlotList(key: ValueKey(filters.hashCode), slots: slots),
        ),
      ),
    );
  }
}

const List<String> _kDayShortNames = ['Пон', 'Вто', 'Сре', 'Чет', 'Пет'];

class _DayStrip extends ConsumerWidget {
  const _DayStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDay = ref.watch(filtersProvider.select((f) => f.dayOfWeek));
    final todayIndex = DateTime.now().weekday - 1; // 0=Mon … 6=Sun

    return SizedBox(
      height: 52,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
        child: Row(
          children: [
            for (var day = 0; day < _kDayShortNames.length; day++) ...[
              _DayChip(
                label: _kDayShortNames[day],
                selected: selectedDay == day,
                isToday: todayIndex == day,
                onTap: () => ref.read(filtersProvider.notifier).update(
                      (f) => f.copyWith(dayOfWeek: () => selectedDay == day ? null : day),
                    ),
              ),
              if (day < _kDayShortNames.length - 1) const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isToday;
  final VoidCallback onTap;
  const _DayChip({
    required this.label,
    required this.selected,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedScale(
        scale: selected ? 1.08 : 1.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? Colors.white
                  : isToday
                      ? Colors.white38
                      : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.navy : Colors.white70,
              fontSize: 13,
              fontWeight: selected || isToday ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _SlotList extends ConsumerStatefulWidget {
  final List<ScheduleSlot> slots;
  const _SlotList({super.key, required this.slots});

  @override
  ConsumerState<_SlotList> createState() => _SlotListState();
}

class _SlotListState extends ConsumerState<_SlotList> {
  Timer? _clock;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Group by day, sorted by day then start time.
    final byDay = <int, List<ScheduleSlot>>{};
    for (final s in widget.slots) {
      (byDay[s.dayOfWeek] ??= []).add(s);
    }
    final days = byDay.keys.toList()..sort();
    for (final d in days) {
      byDay[d]!.sort((a, b) => a.startTime.compareTo(b.startTime));
    }

    final todayIndex = _now.weekday - 1;
    final todaySelected = ref.watch(filtersProvider.select((f) => f.dayOfWeek)) == todayIndex;
    final nowLabel =
        '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}';

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      tween: Tween(begin: 0, end: 1),
      builder: (context, t, child) => Opacity(opacity: t, child: child),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: days.length,
        itemBuilder: (context, i) {
          final day = days[i];
          final daySlots = byDay[day]!;
          final showNow = todaySelected && day == todayIndex;
          // Slot the indicator in before the first class that starts after now.
          final nowIndex =
              showNow ? daySlots.indexWhere((s) => s.start.compareTo(nowLabel) > 0) : -1;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: i == 0 ? 0 : 14, bottom: 8),
                child: Row(
                  children: [
                    Text(
                      day >= 0 && day < kDayNames.length ? kDayNames[day] : 'Ден ${day + 1}',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.navy, letterSpacing: 0.4),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(child: Divider(color: AppColors.hairline, thickness: 1)),
                    const SizedBox(width: 10),
                    Text('${daySlots.length}',
                        style: const TextStyle(fontSize: 12, color: AppColors.faint)),
                  ],
                ),
              ),
              for (var j = 0; j < daySlots.length; j++) ...[
                if (showNow && nowIndex == j) _NowIndicator(label: nowLabel),
                _Entrance(
                  delayMs: (i * 70 + j * 45).clamp(0, 420),
                  child: SlotCard(slot: daySlots[j]),
                ),
              ],
              if (showNow && nowIndex == -1) _NowIndicator(label: nowLabel),
            ],
          );
        },
      ),
    );
  }
}

/// Fade + slide-up entrance used to stagger the slot cards into view.
class _Entrance extends StatefulWidget {
  final int delayMs;
  final Widget child;
  const _Entrance({required this.delayMs, required this.child});

  @override
  State<_Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<_Entrance> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 320));
  late final Animation<double> _a = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
  Timer? _delay;

  @override
  void initState() {
    super.initState();
    _delay = Timer(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _delay?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      builder: (context, child) => Opacity(
        opacity: _a.value,
        child: Transform.translate(offset: Offset(0, 18 * (1 - _a.value)), child: child),
      ),
      child: widget.child,
    );
  }
}

class _NowIndicator extends StatefulWidget {
  final String label;
  const _NowIndicator({required this.label});

  @override
  State<_NowIndicator> createState() => _NowIndicatorState();
}

class _NowIndicatorState extends State<_NowIndicator> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400))
    ..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          // Pulsing dot: a soft ring expands and fades behind the solid core.
          SizedBox(
            width: 16,
            height: 16,
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) => Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 8 + 8 * _pulse.value,
                    height: 8 + 8 * _pulse.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.bright.withValues(alpha: 0.35 * (1 - _pulse.value)),
                    ),
                  ),
                  Container(
                    width: 8,
                    height: 8,
                    decoration:
                        const BoxDecoration(color: AppColors.bright, shape: BoxShape.circle),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          const Expanded(child: Divider(color: AppColors.bright, thickness: 1.5, height: 1.5)),
          const SizedBox(width: 8),
          Text(
            'сега, ${widget.label}',
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.bright),
          ),
        ],
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
        IconButton(onPressed: onTap, icon: const Icon(Icons.tune_rounded)),
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
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        SizedBox(height: 120),
        Icon(Icons.event_busy_outlined, size: 44, color: AppColors.faint),
        SizedBox(height: 12),
        Center(child: Text('Нема часови за избраните филтри', style: TextStyle(color: AppColors.muted))),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 120),
        const Icon(Icons.cloud_off_rounded, size: 44, color: AppColors.faint),
        const SizedBox(height: 12),
        const Center(child: Text('Не може да се вчита распоредот', style: TextStyle(color: AppColors.muted))),
        const SizedBox(height: 8),
        Center(child: TextButton(onPressed: onRetry, child: const Text('Обиди се повторно'))),
      ],
    );
  }
}
