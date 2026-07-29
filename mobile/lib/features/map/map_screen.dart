import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/finki_loader.dart';
import '../../core/widgets/profile_menu.dart';

const _mapUrl = 'https://map.finki.ukim.mk/?l=0#19/42.00460/21.40945';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() {
            _loading = true;
            _error = false;
          }),
          onPageFinished: (_) => setState(() => _loading = false),
          onWebResourceError: (_) => setState(() {
            _loading = false;
            _error = true;
          }),
        ),
      )
      ..loadRequest(Uri.parse(_mapUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The map fills the page, so the shared background has nothing to add
      // here — an opaque surface keeps the campus photo from showing through
      // behind the header.
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Карта'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Освежи',
            onPressed: () => _controller.reload(),
          ),
          const ProfileMenu(),
          const SizedBox(width: 4),
        ],
      ),
      body: _error
          ? _ErrorView(
              onRetry: () {
                setState(() => _error = false);
                _controller.loadRequest(Uri.parse(_mapUrl));
              },
            )
          : Column(
              children: [
                const _RoomHint(),
                Expanded(child: _mapBody()),
              ],
            ),
    );
  }

  Widget _mapBody() {
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        // The map draws itself in pieces as it loads, which looks
        // broken rather than busy — so the wait happens on a clean
        // surface, with the same loader every other screen uses,
        // and the map is only shown once it is whole.
        IgnorePointer(
          ignoring: !_loading,
          child: AnimatedOpacity(
            opacity: _loading ? 1 : 0,
            duration: const Duration(milliseconds: 300),
            child: const ColoredBox(
              color: Colors.white,
              child: Center(
                child: FinkiLoader(caption: 'Ја вчитувам картата…'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The room the student tapped to get here, kept in front of them while they
/// look for it.
///
/// The map is an external web app with no room index we can drive, so this is
/// deliberately a note and not a search: it carries the name across the tab
/// switch so nobody has to hold "Барака 3.2" in their head.
class _RoomHint extends StatelessWidget {
  const _RoomHint();

  @override
  Widget build(BuildContext context) {
    final room = GoRouterState.of(context).uri.queryParameters['room'];
    if (room == null || room.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      color: AppColors.panel,
      padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
      child: Row(
        children: [
          const Icon(Icons.place_outlined, size: 16, color: AppColors.navy),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'Го барате '),
                  TextSpan(
                    text: room,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: AppColors.ink),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            color: AppColors.muted,
            tooltip: 'Затвори',
            onPressed: () => context.go('/map'),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 52,
              color: AppColors.faint,
            ),
            const SizedBox(height: 16),
            const Text(
              'Картата не може да се вчита',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            const Text(
              'Проверете ја вашата интернет врска.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Обиди се повторно'),
            ),
          ],
        ),
      ),
    );
  }
}
