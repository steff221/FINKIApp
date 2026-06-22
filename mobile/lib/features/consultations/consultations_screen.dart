import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/models.dart';
import 'consultations_providers.dart';
import 'professor_detail_screen.dart';

class ConsultationsScreen extends ConsumerStatefulWidget {
  const ConsultationsScreen({super.key});

  @override
  ConsumerState<ConsultationsScreen> createState() => _ConsultationsScreenState();
}

class _ConsultationsScreenState extends ConsumerState<ConsultationsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(consultationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Консултации')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _msg('Не може да се вчитаат консултациите'),
        data: (all) {
          final q = _query.trim().toLowerCase();
          final filtered =
              q.isEmpty ? all : all.where((t) => t.teacher.displayName.toLowerCase().contains(q)).toList();

          // Group alphabetically by first letter.
          filtered.sort((a, b) => a.teacher.displayName.compareTo(b.teacher.displayName));
          final groups = <String, List<TeacherWithSlots>>{};
          for (final t in filtered) {
            final name = t.teacher.displayName;
            final letter = name.isNotEmpty ? name[0].toUpperCase() : '#';
            (groups[letter] ??= []).add(t);
          }
          final letters = groups.keys.toList()..sort();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (v) => setState(() => _query = v),
                        decoration: const InputDecoration(
                          hintText: 'Пребарај по име на професор…',
                          prefixIcon: Icon(Icons.search_rounded, size: 20),
                          contentPadding: EdgeInsets.symmetric(vertical: 4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('${all.length} професори',
                      style: const TextStyle(color: AppColors.faint, fontSize: 12)),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? _msg('Нема резултати за „$_query“')
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 28),
                        itemCount: letters.length,
                        itemBuilder: (context, i) {
                          final letter = letters[i];
                          final pros = groups[letter]!;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(4, 14, 0, 6),
                                child: CircleAvatar(
                                  radius: 13,
                                  backgroundColor: AppColors.navy,
                                  child: Text(letter,
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                                ),
                              ),
                              ...pros.map((t) => _professorRow(t)),
                            ],
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _professorRow(TeacherWithSlots t) {
    final count = t.slots.length;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(t.teacher.displayName,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: count > 0
            ? Text('$count ${count == 1 ? 'термин' : 'термини'}',
                style: const TextStyle(fontSize: 12, color: AppColors.muted))
            : const Text('Нема термини', style: TextStyle(fontSize: 12, color: AppColors.faint)),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.faint),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ProfessorDetailScreen(data: t)),
        ),
      ),
    );
  }

  Widget _msg(String text) => ListView(children: [
        const SizedBox(height: 100),
        const Icon(Icons.forum_outlined, size: 44, color: AppColors.faint),
        const SizedBox(height: 12),
        Center(child: Text(text, style: const TextStyle(color: AppColors.muted))),
      ]);
}
