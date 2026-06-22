import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../env.dart';
import '../providers.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final String? email;
  final bool loading;
  final String? error;

  const AuthState({
    required this.status,
    this.email,
    this.loading = false,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? email,
    bool? loading,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      email: email ?? this.email,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  final Ref ref;

  AuthController(this.ref) : super(const AuthState(status: AuthStatus.unknown)) {
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final store = ref.read(tokenStoreProvider);
    final token = await store.readToken();
    final email = await store.readEmail();

    if (token != null && token.isNotEmpty) {
      state = AuthState(status: AuthStatus.authenticated, email: email);
      return;
    }

    // No token — try to auto-login with saved credentials.
    final password = await store.readPassword();
    if (email != null && password != null) {
      final ok = await login(email, password);
      if (ok) return;
    }

    // Fall back to build-time baked credentials (silent auto-login, no login UI).
    if (Env.defaultEmail.isNotEmpty && Env.defaultPassword.isNotEmpty) {
      final ok = await login(Env.defaultEmail, Env.defaultPassword);
      if (ok) return;
    }

    state = AuthState(status: AuthStatus.unauthenticated, email: email);
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final res = await ref.read(apiProvider).login(email.trim(), password);
      final store = ref.read(tokenStoreProvider);
      await store.save(token: res.token, userId: res.userId, email: res.email);
      await store.savePassword(password);
      state = AuthState(status: AuthStatus.authenticated, email: res.email);
      return true;
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final msg = (code == 401 || code == 403)
          ? 'Погрешен е-маил или лозинка.'
          : 'Не може да се поврзе со серверот. Проверете ја врската.';
      state = AuthState(status: AuthStatus.unauthenticated, email: email, error: msg);
      return false;
    } catch (_) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        email: email,
        error: 'Се случи грешка. Обидете се повторно.',
      );
      return false;
    }
  }

  Future<void> logout() async {
    await ref.read(tokenStoreProvider).clear();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Called by the Dio interceptor when the backend returns 401/403.
  Future<void> onSessionExpired() async {
    final store = ref.read(tokenStoreProvider);
    await store.clear();
    final email = await store.readEmail();
    final password = await store.readPassword();
    if (email != null && password != null) {
      final ok = await login(email, password);
      if (ok) return;
    }
    if (state.status != AuthStatus.unauthenticated) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }
}
