import 'package:dio/dio.dart';
import '../env.dart';
import '../storage/token_store.dart';

/// Builds a Dio instance that attaches the JWT to every request and reports
/// 401/403 responses (expired/invalid session) via [onUnauthorized].
Dio buildDio(TokenStore store, Future<void> Function() onUnauthorized) {
  final dio = Dio(
    BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await store.readToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (e, handler) {
        final code = e.response?.statusCode;
        if (code == 401 || code == 403) {
          onUnauthorized();
        }
        handler.next(e);
      },
    ),
  );

  return dio;
}
