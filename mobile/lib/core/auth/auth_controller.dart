import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../demo/demo.dart';
import '../env.dart';
import '../network/app_error.dart';
import '../providers.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final String? email;

  /// Display name, used for the greeting on Дома. Null on accounts made before
  /// the field existed — every consumer falls back to the plain greeting.
  final String? name;

  final bool loading;
  final String? error;

  const AuthState({
    required this.status,
    this.email,
    this.name,
    this.loading = false,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? email,
    String? name,
    bool? loading,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      email: email ?? this.email,
      name: name ?? this.name,
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
    // A presentation build has no server to sign in to — it opens straight
    // into the app as the account being demonstrated.
    if (kDemoMode) {
      state = const AuthState(
          status: AuthStatus.authenticated, email: kDemoEmail, name: kDemoName);
      return;
    }

    final store = ref.read(tokenStoreProvider);
    final token = await store.readToken();
    final email = await store.readEmail();
    final name = await store.readName();

    if (token != null && token.isNotEmpty) {
      state = AuthState(status: AuthStatus.authenticated, email: email, name: name);
      // Show the cached identity straight away, then quietly catch it up — a
      // session that started before the display name existed has a perfectly
      // good token and no name on file.
      unawaited(_refreshIdentity());
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

  /// Pulls the account's current details in the background and keeps them.
  ///
  /// Failure is not worth reporting: the cached identity is still usable, and
  /// the greeting simply stays as it was.
  Future<void> _refreshIdentity() async {
    try {
      final me = await ref.read(apiProvider).me();
      if (me.name != null && me.name!.isNotEmpty) {
        await ref.read(tokenStoreProvider).saveName(me.name!);
      }
      if (!mounted) return;
      state = state.copyWith(email: me.email, name: me.name);
    } catch (_) {
      // Offline, or a backend that predates /auth/me.
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final res = await ref.read(apiProvider).login(email.trim(), password);
      final store = ref.read(tokenStoreProvider);
      await store.save(
          token: res.token, userId: res.userId, email: res.email, name: res.name);
      await store.savePassword(password);
      state = AuthState(
        status: AuthStatus.authenticated,
        email: res.email,
        name: res.name ?? await store.readName(),
      );
      return true;
    } on AppError catch (e) {
      // Wrong password and no signal are different problems; only one of them
      // is worth re-typing the form over.
      final msg = e.kind == AppErrorKind.auth
          ? 'Погрешна е-пошта или лозинка.'
          : '${e.message}. ${e.hint}';
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

  /// Creates the account and signs straight in — the backend returns a token
  /// with the 201, so there is no second round trip.
  Future<bool> register(String email, String password, {required String name}) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final res = await ref.read(apiProvider).register(email.trim(), password, name.trim());
      final store = ref.read(tokenStoreProvider);
      await store.save(
          token: res.token, userId: res.userId, email: res.email, name: res.name ?? name.trim());
      await store.savePassword(password);
      state = AuthState(
        status: AuthStatus.authenticated,
        email: res.email,
        name: res.name ?? name.trim(),
      );
      return true;
    } on AppError catch (e) {
      final msg = switch (e.statusCode) {
        409 => 'Оваа е-пошта е веќе регистрирана.',
        400 || 422 => 'Проверете ги внесените податоци.',
        _ => '${e.message}. ${e.hint}',
      };
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
    // Nothing to sign out of while presenting, and no login screen to land on.
    if (kDemoMode) return;
    await ref.read(tokenStoreProvider).clear();
    // The next account must not open onto this one's timetable.
    await ref.read(jsonCacheProvider).clear();
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
