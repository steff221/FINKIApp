import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/page_background.dart';
import 'core/widgets/splash_overlay.dart';

class FinkiApp extends ConsumerWidget {
  const FinkiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'ФИНКИ Распоред',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: router,
      builder: (context, child) => PageBackground(
        child: SplashOverlay(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}
