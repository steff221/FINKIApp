import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import '../theme/app_colors.dart';

/// A slim strip that owns up to showing yesterday's copy.
///
/// The app deliberately keeps working without a network — but a timetable is
/// exactly the kind of thing that must never quietly lie about being current,
/// so when the data came out of the cache it says so, once, for the whole app.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stale = ref.watch(servingCacheProvider);

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: stale
          ? Container(
              width: double.infinity,
              color: AppColors.navy.withValues(alpha: 0.06),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off_rounded, size: 14, color: AppColors.muted),
                  SizedBox(width: 7),
                  Text(
                    'Офлајн · прикажан е зачуваниот распоред',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox(width: double.infinity),
    );
  }
}
