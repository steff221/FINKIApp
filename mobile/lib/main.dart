import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/providers.dart';
import 'core/storage/json_cache.dart';

Future<void> main() async {
  // Hold the native splash until SplashScreen calls FlutterNativeSplash.remove()
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Opened before the first frame: the point of the cache is that the first
  // screen never waits on the network, so it has to be ready before there is a
  // screen to serve.
  final cache = await JsonCache.open();

  runApp(ProviderScope(
    overrides: [jsonCacheProvider.overrideWithValue(cache)],
    child: const FinkiApp(),
  ));
}
