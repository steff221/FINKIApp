import 'package:flutter/material.dart';

import '../theme/app_type.dart';

/// The header every screen wears: its name in the serif, an optional line of
/// context under it, and whatever actions belong to the page.
///
/// No bar and no colour — a screen begins by saying what it is, on the same
/// surface as everything below it.
class ScreenHeader extends StatelessWidget {
  final String title;

  /// One quiet line of context — the session and its size, the week, the
  /// number of professors. Skipped where the title says enough.
  final String? subtitle;

  /// Back chevron and the like, before the title.
  final Widget? leading;

  final List<Widget> actions;

  const ScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(leading == null ? 16 : 4, 10, 8, 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ?leading,
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppType.screenTitle),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: AppType.subtitle),
                  ],
                ],
              ),
            ),
            ...actions,
          ],
        ),
      ),
    );
  }
}

/// Heading over a section of a page. The serif again, a step down from the
/// screen's own name.
class SectionHeading extends StatelessWidget {
  final String label;

  /// Right-aligned counterpart — a count, or an action.
  final Widget? trailing;

  final EdgeInsets padding;

  const SectionHeading(
    this.label, {
    super.key,
    this.trailing,
    this.padding = const EdgeInsets.only(top: 8, bottom: 6),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppType.section)),
          ?trailing,
        ],
      ),
    );
  }
}
