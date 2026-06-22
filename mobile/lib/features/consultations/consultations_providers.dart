import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../models/models.dart';

/// All professors with their consultation slots (filtered client-side by name).
final consultationsProvider = FutureProvider.autoDispose<List<TeacherWithSlots>>(
  (ref) => ref.read(apiProvider).getConsultations(),
);

/// Slot ids the user has booked, with optimistic book/cancel.
class BookingsController extends StateNotifier<Set<int>> {
  final Ref ref;
  BookingsController(this.ref) : super(<int>{}) {
    _load();
  }

  Future<void> _load() async {
    try {
      state = await ref.read(apiProvider).getMyConsultationBookings();
    } catch (_) {}
  }

  Future<void> book(int slotId, String reason) async {
    state = {...state, slotId};
    try {
      await ref.read(apiProvider).bookConsultation(slotId, reason);
    } catch (_) {
      final s = {...state}..remove(slotId);
      state = s;
      rethrow;
    }
  }

  Future<void> cancel(int slotId) async {
    final s = {...state}..remove(slotId);
    state = s;
    try {
      await ref.read(apiProvider).cancelConsultationBooking(slotId);
    } catch (_) {
      state = {...state, slotId};
      rethrow;
    }
  }
}

final bookingsProvider =
    StateNotifierProvider<BookingsController, Set<int>>((ref) => BookingsController(ref));
