import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
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

class _SlotList extends StatelessWidget {
  final List<ScheduleSlot> slots;
  const _SlotList({super.key, required this.slots});

  @override
  Widget build(BuildContext context) {
    // Group by day, sorted by day then start time.
    final byDay = <int, List<ScheduleSlot>>{};
    for (final s in slots) {
      (byDay[s.dayOfWeek] ??= []).add(s);
    }
    final days = byDay.keys.toList()..sort();
    for (final d in days) {
      byDay[d]!.sort((a, b) => a.startTime.compareTo(b.startTime));
    }

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
              ...daySlots.map((s) => SlotCard(slot: s)),
            ],
          );
        },
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
  Widget build(BuildContext context) => const Center(child: CircularProgressIndicator());
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
