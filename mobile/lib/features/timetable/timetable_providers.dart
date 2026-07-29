import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../models/models.dart';
import '../schedule/schedule_providers.dart';

/// Which kind of class the subject browser is showing.
///
/// Kept apart from [filtersProvider] because COMBINED (`п+ав`) classes belong
/// under *both* Предавање and Аудиториски вежби — they are literally both — so
/// the narrowing happens client-side rather than in the query.
final browseTypeProvider = StateProvider<String>((ref) => 'LECTURE');

/// Current filter selection (sent to GET /timetable/slots).
final filtersProvider = StateProvider<TimetableFilters>((ref) => const TimetableFilters());

/// Dropdown options for the filter sheet.
final filtersDataProvider = FutureProvider<TimetableFiltersData>(
  (ref) => ref.read(apiProvider).getFilters(),
);

/// Timetable slots for the active filters.
final slotsProvider = FutureProvider.autoDispose<List<ScheduleSlot>>((ref) {
  final filters = ref.watch(filtersProvider);
  return ref.read(apiProvider).getSlots(filters);
});

/// Slot ids the user has saved to their schedule, with optimistic toggling.
class SavedSlotsController extends StateNotifier<Set<int>> {
  final Ref ref;
  SavedSlotsController(this.ref) : super(<int>{}) {
    _load();
  }

  Future<void> _load() async {
    try {
      state = await ref.read(apiProvider).getScheduleSlotIds();
    } catch (_) {
      // Leave empty on failure; the toggle will still work.
    }
  }

  Future<void> toggle(int slotId) async {
    final wasSaved = state.contains(slotId);
    final next = {...state};
    wasSaved ? next.remove(slotId) : next.add(slotId);
    state = next; // optimistic

    try {
      if (wasSaved) {
        await ref.read(apiProvider).removeSlot(slotId);
      } else {
        await ref.read(apiProvider).addSlot(slotId);
      }
      // This notifier only holds ids; Мој Распоред and Дома render the full
      // slot objects from their own provider, which the shell keeps alive for
      // the life of the session. Without this it goes on showing the list it
      // loaded when the tab was first opened, and a class just added looks
      // like it was never saved.
      ref.invalidate(scheduleSlotsProvider);
    } catch (_) {
      final reverted = {...state};
      wasSaved ? reverted.add(slotId) : reverted.remove(slotId);
      state = reverted; // revert on failure
    }
  }
}

final savedSlotsProvider =
    StateNotifierProvider<SavedSlotsController, Set<int>>((ref) => SavedSlotsController(ref));
