import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../models/models.dart';

final examSessionsProvider = FutureProvider<List<String>>(
  (ref) => ref.read(apiProvider).getExamSessions(),
);

/// Explicitly selected session (null → default to the most recent one).
final selectedSessionProvider = StateProvider<String?>((ref) => null);

/// Exams for a given session (client filters by query in the screen).
final examsProvider = FutureProvider.autoDispose.family<List<Exam>, String?>(
  (ref, session) => ref.read(apiProvider).getExams(session: session),
);
