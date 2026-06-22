import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../models/models.dart';

/// Saved timetable slots (full objects) for the weekly view.
final scheduleSlotsProvider = FutureProvider.autoDispose<List<ScheduleSlot>>(
  (ref) => ref.read(apiProvider).getScheduleSlots(),
);

/// User's custom weekly entries, with add/delete.
class CustomEntriesController extends StateNotifier<AsyncValue<List<CustomEntry>>> {
  final Ref ref;
  CustomEntriesController(this.ref) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    state = const AsyncValue.loading();
    try {
      state = AsyncValue.data(await ref.read(apiProvider).getCustomEntries());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> reload() => _load();

  Future<void> add({
    required String title,
    required String entryType,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    String? room,
    String? professor,
  }) async {
    final created = await ref.read(apiProvider).createCustomEntry(
          title: title,
          entryType: entryType,
          dayOfWeek: dayOfWeek,
          startTime: startTime,
          endTime: endTime,
          room: room,
          professor: professor,
        );
    final current = state.value ?? [];
    state = AsyncValue.data([...current, created]);
  }

  Future<void> delete(int id) async {
    final current = state.value ?? [];
    state = AsyncValue.data(current.where((e) => e.id != id).toList());
    try {
      await ref.read(apiProvider).deleteCustomEntry(id);
    } catch (_) {
      await _load();
    }
  }
}

final customEntriesProvider =
    StateNotifierProvider.autoDispose<CustomEntriesController, AsyncValue<List<CustomEntry>>>(
        (ref) => CustomEntriesController(ref));

/// Exams pinned to Мој Распоред, with optimistic removal.
class SavedExamsController extends StateNotifier<AsyncValue<List<Exam>>> {
  final Ref ref;
  SavedExamsController(this.ref) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      state = AsyncValue.data(await ref.read(apiProvider).getSavedExams());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> add(Exam exam) async {
    final current = state.value ?? [];
    if (current.any((e) => e.id == exam.id)) return;
    state = AsyncValue.data([...current, exam]); // optimistic
    try {
      await ref.read(apiProvider).addSavedExam(exam.id);
    } catch (_) {
      await load();
    }
  }

  Future<void> remove(int examId) async {
    final current = state.value ?? [];
    state = AsyncValue.data(current.where((e) => e.id != examId).toList()); // optimistic
    try {
      await ref.read(apiProvider).removeSavedExam(examId);
    } catch (_) {
      await load(); // revert by reloading
    }
  }
}

/// Set of pinned exam ids — for the +/✓ toggle on the Испити screen.
final savedExamIdsProvider = Provider.autoDispose<Set<int>>((ref) {
  final exams = ref.watch(savedExamsProvider).value ?? [];
  return exams.map((e) => e.id).toSet();
});

final savedExamsProvider =
    StateNotifierProvider.autoDispose<SavedExamsController, AsyncValue<List<Exam>>>(
        (ref) => SavedExamsController(ref));
