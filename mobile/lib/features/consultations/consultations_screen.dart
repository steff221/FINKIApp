import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_type.dart';
import '../../models/models.dart';
import 'consultations_providers.dart';
import 'professor_detail_screen.dart';
import '../../core/widgets/finki_loader.dart';
import '../../core/widgets/page_background.dart';
import '../../core/widgets/profile_menu.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/state_views.dart';
import '../../core/theme/app_shape.dart';

class ConsultationsScreen extends ConsumerStatefulWidget {
  const ConsultationsScreen({super.key});

  @override
  ConsumerState<ConsultationsScreen> createState() => _ConsultationsScreenState();
}

class _ConsultationsScreenState extends ConsumerState<ConsultationsScreen> {
  final _search = TextEditingController();
  String _query = '';

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
    final async = ref.watch(consultationsProvider);

    return Scaffold(
      body: Column(children: [
        ScreenHeader(
          title: 'Консултации',
          subtitle: switch (async.value?.length) {
            null => null,
            final n => '$n професори',
          },
          actions: const [ProfileMenu(), SizedBox(width: 4)],
        ),
        Expanded(
          child: async.when(
        loading: () => const Center(child: FinkiLoader()),
        error: (e, _) => ErrorStateView.from(
          e,
          onRetry: () => ref.invalidate(consultationsProvider),
        ),
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
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _search,
                        onChanged: (v) => setState(() => _query = v),
                        decoration: InputDecoration(
                          hintText: 'Пребарај по име на професор…',
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
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? EmptyStateView(
                        icon: Icons.search_off_rounded,
                        title: 'Нема резултати за „$_query“',
                        action: TextButton(
                          onPressed: _clearSearch,
                          child: const Text('Исчисти пребарување'),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
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
        ),
      ]),
    );
  }

  Widget _professorRow(TeacherWithSlots t) {
    final count = t.slots.length;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
        title: Text(t.teacher.displayName, style: AppType.cardTitle),
        subtitle: count > 0
            ? Text('$count ${count == 1 ? 'термин' : 'термини'}',
                style: const TextStyle(fontSize: 12, color: AppColors.muted))
            : const Text('Нема термини', style: TextStyle(fontSize: 12, color: AppColors.faint)),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.faint),
        onTap: () => Navigator.of(context).push(
          // Wrapped so the pushed page is opaque: the shared background lives
          // behind the router, and a see-through route would show this list
          // through it for the length of the transition.
          MaterialPageRoute(
              builder: (_) => PageBackground(child: ProfessorDetailScreen(data: t))),
        ),
      ),
    );
  }

}
