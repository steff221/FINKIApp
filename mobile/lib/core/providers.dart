import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth/auth_controller.dart';
import 'demo/demo.dart';
import 'demo/demo_api.dart';
import 'network/api.dart';
import 'network/api_client.dart';
import 'notifications/reminders.dart';
import 'storage/json_cache.dart';
import 'storage/token_store.dart';

final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());

/// Opened in `main()` before the app runs, then handed in here — reading it
/// without that override is a wiring mistake, not a runtime condition.
final jsonCacheProvider = Provider<JsonCache>(
    (ref) => throw StateError('jsonCacheProvider must be overridden in main()'));

/// Whether what is on screen came out of the cache rather than off the wire.
///
/// One flag for the whole app: the screens all read the same backend, so if one
/// of them is looking at yesterday's copy they all are.
class ServingCache extends StateNotifier<bool> {
  ServingCache() : super(false);

  void report({required bool fromCache}) {
    if (state != fromCache) state = fromCache;
  }
}

final servingCacheProvider =
    StateNotifierProvider<ServingCache, bool>((ref) => ServingCache());

final dioProvider = Provider<Dio>((ref) {
  final store = ref.watch(tokenStoreProvider);
  return buildDio(store, () {
    // Lazy read avoids a construction-time cycle with AuthController.
    return ref.read(authControllerProvider.notifier).onSessionExpired();
  });
});

final apiProvider = Provider<Api>((ref) {
  // The presentation build reads a snapshot from the bundle; there is nothing
  // to cache and nothing that can be stale.
  if (kDemoMode) return DemoApi();
  return Api(
    ref.watch(dioProvider),
    cache: ref.watch(jsonCacheProvider),
    freshness: ({required fromCache}) =>
        ref.read(servingCacheProvider.notifier).report(fromCache: fromCache),
  );
});

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) => AuthController(ref));

/// Class and exam reminders — see [RemindersController].
final remindersProvider =
    StateNotifierProvider<RemindersController, bool>((ref) => RemindersController(ref));
