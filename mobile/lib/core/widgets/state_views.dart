import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../network/app_error.dart';
import '../theme/app_colors.dart';
import '../theme/app_type.dart';

/// Shared skeleton for the "nothing here" screens: a haloed icon, a title, an
/// optional supporting line, and an optional action.
///
/// Empty and error states differ in wording and action, not in shape — keeping
/// one layout means they read the same on every tab.
class _StatePlaceholder extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  final bool scrollable;
  final double topGap;

  /// A Lottie composition to show instead of the haloed icon.
  ///
  /// Reserved for the states that are not failures — an empty timetable is a
  /// blank page, not an error, and deserves something with a bit of life in it.
  final String? animation;

  const _StatePlaceholder({
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    required this.scrollable,
    required this.topGap,
    this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      SizedBox(height: topGap),
      Center(
        child: animation != null
            ? Lottie.asset(animation!, width: 168, height: 168, repeat: true)
            : Container(
                width: 84,
                height: 84,
                decoration: const BoxDecoration(
                  color: AppColors.panel,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 34, color: AppColors.navy),
              ),
      ),
      const SizedBox(height: 18),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: AppType.panelTitle,
        ),
      ),
      if (subtitle != null) ...[
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: AppType.subtitle,
          ),
        ),
      ],
      if (action != null) ...[
        const SizedBox(height: 18),
        Center(child: action!),
      ],
    ];

    if (scrollable) {
      return ListView(physics: const AlwaysScrollableScrollPhysics(), children: children);
    }
    return Column(children: children);
  }
}

/// Empty-state placeholder: a muted icon, a title, an optional subtitle, and an
/// optional action widget (e.g. a "clear search" button).
///
/// [scrollable] (default true) makes it a scroll view so it can be the direct
/// child of a `RefreshIndicator`; set false to embed inside an existing scroll
/// view without nesting scrollables.
class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  final bool scrollable;
  final double topGap;

  /// See [_StatePlaceholder.animation] — takes the icon's place when given.
  final String? animation;

  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.scrollable = true,
    this.topGap = 100,
    this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return _StatePlaceholder(
      icon: icon,
      title: title,
      subtitle: subtitle,
      action: action,
      scrollable: scrollable,
      topGap: topGap,
      animation: animation,
    );
  }
}

/// Error-state placeholder with a retry affordance.
///
/// [scrollable] behaves as in [EmptyStateView].
class ErrorStateView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final String? subtitle;
  final IconData icon;
  final bool scrollable;
  final double topGap;

  /// Whether the retry button is worth offering. An expired session cannot be
  /// retried into working.
  final bool canRetry;

  const ErrorStateView({
    super.key,
    required this.message,
    required this.onRetry,
    this.subtitle = 'Проверете ја врската и обидете се повторно',
    this.icon = Icons.cloud_off_rounded,
    this.scrollable = true,
    this.topGap = 100,
    this.canRetry = true,
  });

  /// The screen's reading of whatever was thrown.
  ///
  /// "Нема интернет врска" and "Серверот има проблем" call for different things
  /// from the student, and only one of them is their problem to fix — so the
  /// failure is classified once, in [AppError], and every screen shows what it
  /// says instead of one message for everything.
  factory ErrorStateView.from(
    Object? error, {
    Key? key,
    required VoidCallback onRetry,
    bool scrollable = true,
    double topGap = 100,
  }) {
    final e = AppError.from(error ?? const AppError(AppErrorKind.unknown));
    return ErrorStateView(
      key: key,
      message: e.message,
      subtitle: e.hint,
      icon: e.icon,
      onRetry: onRetry,
      scrollable: scrollable,
      topGap: topGap,
      canRetry: e.isRetryable,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _StatePlaceholder(
      icon: icon,
      title: message,
      subtitle: subtitle,
      scrollable: scrollable,
      topGap: topGap,
      // Retry is the whole point of this screen, so it gets a real button.
      action: canRetry
          ? FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('Обиди се повторно'),
            )
          : null,
    );
  }
}
