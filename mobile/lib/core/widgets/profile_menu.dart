import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_shape.dart';
import '../utils/mk_date.dart';

/// The account button shown in every screen's AppBar: who is signed in and a
/// sign-out action.
///
/// Tints itself from the surrounding AppBar's `foregroundColor`, so it reads
/// white on the navy bars and navy on Дома's canvas bar.
class ProfileMenu extends ConsumerWidget {
  const ProfileMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.account_circle_outlined),
      tooltip: 'Сметка',
      offset: const Offset(0, 48),
      constraints: const BoxConstraints(minWidth: 232, maxWidth: 300),
      padding: EdgeInsets.zero,
      onSelected: (v) async {
        if (v == 'logout') ref.read(authControllerProvider.notifier).logout();
        if (v == 'reminders') {
          final wanted = !ref.read(remindersProvider);
          final on = await ref.read(remindersProvider.notifier).toggle(wanted);
          if (!context.mounted) return;
          // Asking for permission is the one step the app cannot do on its own;
          // if iOS said no, say so rather than leaving the switch mysteriously
          // off.
          final message = on
              ? 'Ќе те потсетиме 15 минути пред час.'
              : wanted
                  ? 'Дозволете известувања во Поставки за да ги вклучите потсетниците.'
                  : 'Потсетниците се исклучени.';
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(message)));
        }
      },
      itemBuilder: (_) {
        final auth = ref.read(authControllerProvider);
        final remindersOn = ref.read(remindersProvider);
        final name = auth.name?.trim();
        final first = firstName(name);
        final initial = (first == null || first.isEmpty) ? null : first[0].toUpperCase();

        return [
          // Identity, not an action — it sits above the rule and cannot be
          // tapped.
          PopupMenuItem<String>(
            enabled: false,
            height: 0,
            padding: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.navy.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: initial == null
                        ? const Icon(Icons.person_outline_rounded,
                            size: 18, color: AppColors.navy)
                        : Text(
                            initial,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.navy),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (name != null && name.isNotEmpty) ...[
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink),
                          ),
                          const SizedBox(height: 1),
                        ],
                        Text(
                          auth.email ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const PopupMenuDivider(height: 1),
          // Reminders read as a setting, not a command, so the row carries its
          // current state instead of naming an action.
          PopupMenuItem<String>(
            value: 'reminders',
            height: 48,
            padding: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 18,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: remindersOn ? AppColors.navy : AppColors.faint,
                      borderRadius: BorderRadius.circular(AppRadius.grabber),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Потсетници',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink),
                    ),
                  ),
                  Icon(
                    remindersOn
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_off_outlined,
                    size: 18,
                    color: remindersOn ? AppColors.navy : AppColors.faint,
                  ),
                ],
              ),
            ),
          ),
          const PopupMenuDivider(height: 1),
          PopupMenuItem<String>(
            value: 'logout',
            height: 48,
            padding: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  // The same leading rule the dropdowns and cards use.
                  Container(
                    width: 3,
                    height: 18,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      borderRadius: BorderRadius.circular(AppRadius.grabber),
                    ),
                  ),
                  const Text(
                    'Одјави се',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.danger),
                  ),
                ],
              ),
            ),
          ),
        ];
      },
    );
  }
}
