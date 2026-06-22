import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth/auth_controller.dart';
import 'network/api.dart';
import 'network/api_client.dart';
import 'storage/token_store.dart';

final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());

final dioProvider = Provider<Dio>((ref) {
  final store = ref.watch(tokenStoreProvider);
  return buildDio(store, () {
    // Lazy read avoids a construction-time cycle with AuthController.
    return ref.read(authControllerProvider.notifier).onSessionExpired();
  });
});

final apiProvider = Provider<Api>((ref) => Api(ref.watch(dioProvider)));

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) => AuthController(ref));
