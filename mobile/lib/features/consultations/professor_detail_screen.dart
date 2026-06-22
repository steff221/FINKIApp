import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/models.dart';
import 'consultations_providers.dart';

const _mkMonthsShort = [
  'јан', 'фев', 'мар', 'апр', 'мај', 'јун',
  'јул', 'авг', 'сеп', 'окт', 'ное', 'дек',
];
const _mkDaysShort = ['Нед', 'Пон', 'Вто', 'Сре', 'Чет', 'Пет', 'Саб'];

String _slotDate(String iso) {
  final p = iso.split('-');
  if (p.length != 3) return iso;
  final d = DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
  return '${_mkDaysShort[d.weekday % 7]}, ${d.day} ${_mkMonthsShort[d.month - 1]}';
}

class ProfessorDetailScreen extends ConsumerWidget {
  final TeacherWithSlots data;
  const ProfessorDetailScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booked = ref.watch(bookingsProvider);
    final slots = [...data.slots]
      ..sort((a, b) {
        final d = a.date.compareTo(b.date);
        return d != 0 ? d : a.startTime.compareTo(b.startTime);
      });

    return Scaffold(
      appBar: AppBar(title: Text(data.teacher.displayName)),
      body: slots.isEmpty
          ? const Center(
              child: Text('Нема закажани термини', style: TextStyle(color: AppColors.muted)))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
              itemCount: slots.length,
              itemBuilder: (context, i) => _SlotCard(
                slot: slots[i],
                isBooked: booked.contains(slots[i].id),
              ),
            ),
    );
  }
}

class _SlotCard extends ConsumerWidget {
  final ConsultationSlot slot;
  final bool isBooked;
  const _SlotCard({required this.slot, required this.isBooked});

  Future<void> _onBook(BuildContext context, WidgetRef ref) async {
    final reason = await showDialog<String?>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Пријави се'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 2,
            decoration: const InputDecoration(hintText: 'Причина (опционално)'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Откажи')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text('Пријави'),
            ),
          ],
        );
      },
    );
    if (reason == null) return; // cancelled
    try {
      await ref.read(bookingsProvider.notifier).book(slot.id, reason);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Успешно пријавени')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не успеа пријавувањето')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: AppColors.navy.withValues(alpha: 0.7), width: 4)),
        boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${_slotDate(slot.date)} · ${slot.start}–${slot.end}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 4),
                  Wrap(spacing: 12, children: [
                    if (slot.room != null && slot.room!.isNotEmpty)
                      Text(slot.room!, style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
                    Text('${slot.enrolledCount} пријавени',
                        style: const TextStyle(fontSize: 12.5, color: AppColors.faint)),
                  ]),
                  if (slot.instructions != null && slot.instructions!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(slot.instructions!,
                        style: const TextStyle(fontSize: 12, color: AppColors.faint)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            isBooked
                ? OutlinedButton(
                    onPressed: () => ref.read(bookingsProvider.notifier).cancel(slot.id),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFB91C1C),
                      side: const BorderSide(color: Color(0xFFFECACA)),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Откажи'),
                  )
                : FilledButton(
                    onPressed: () => _onBook(context, ref),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Пријави се'),
                  ),
          ],
        ),
      ),
    );
  }
}
