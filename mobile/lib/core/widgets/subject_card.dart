import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';
import '../theme/app_shape.dart';
import '../theme/app_type.dart';

/// One meta line under a subject title: an icon and its value.
///
/// [asset] takes precedence over [icon] when set, so a row can use a bundled
/// SVG (the lesson-type glyphs) instead of a Material icon. Both tint to the
/// same colour, so the rows stay visually consistent either way.
///
/// [onTap] turns the value into an underlined navy link (used for room names
/// that navigate to the map).
class SubjectMeta {
  final IconData icon;
  final String text;
  final String? asset;
  final VoidCallback? onTap;

  const SubjectMeta(this.icon, this.text, {this.asset, this.onTap});
}

/// The icon vocabulary every subject card shares, so a clock always means a
/// time and a pin always means a room.
abstract final class SubjectIcons {
  static const date = Icons.calendar_month_outlined;
  static const time = Icons.schedule_rounded;
  static const room = Icons.place_outlined;
  static const teacher = Icons.person_outline_rounded;
  static const type = Icons.label_outline_rounded;
  static const conflict = Icons.warning_amber_rounded;
  static const note = Icons.info_outline_rounded;
}

/// What the card answers first: *when*.
///
/// Classes put the start over the end with the length underneath. It sits in
/// the card's leading gutter in tabular figures, so a column of cards lines up
/// digit for digit the way a printed timetable does.
class SubjectLead {
  final String primary;
  final String? secondary;
  final String? caption;

  const SubjectLead(this.primary, {this.secondary, this.caption});
}

/// Title-over-stacked-meta-rows layout shared by every card that describes a
/// class — timetable slots and the personal agenda.
///
/// The lesson type is carried by the card's own [surface]: a wash of the type's
/// colour across the whole card, rather than a rule down the side of it.
class SubjectCard extends StatelessWidget {
  final String title;

  /// The card's fill — the lesson type's tint, or the danger tint on a clash.
  final Color surface;

  final List<SubjectMeta> meta;

  /// The when, shown in the leading gutter. Cards without one keep the plain
  /// body layout.
  final SubjectLead? lead;

  /// Trailing affordance (add, pin, delete). Aligned to the top of the card.
  final Widget? trailing;

  /// Tightens the shadow while the card is held down.
  final bool pressed;

  /// Full-inner-width strip below the metadata stack, for facts that are not
  /// attributes of the subject (a schedule conflict). Clipped to the card's
  /// bottom corners, so it can carry its own background.
  final Widget? footer;

  final EdgeInsets margin;

  const SubjectCard({
    super.key,
    required this.title,
    required this.surface,
    required this.meta,
    this.lead,
    this.trailing,
    this.pressed = false,
    this.footer,
    this.margin = const EdgeInsets.only(bottom: 10),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      clipBehavior: footer == null ? Clip.none : Clip.antiAlias,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.08),
            blurRadius: pressed ? 3 : 10,
            offset: Offset(0, pressed ? 1 : 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(14, 12, trailing == null ? 14 : 2, 12),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (lead != null) ...[
                    _Gutter(lead!),
                    const SizedBox(width: 14),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.cardTitle,
                        ),
                        const SizedBox(height: 6),
                        for (var i = 0; i < meta.length; i++) ...[
                          if (i > 0) const SizedBox(height: 4),
                          SubjectMetaRow(meta[i]),
                        ],
                      ],
                    ),
                  ),
                  ?trailing,
                ],
              ),
            ),
          ),
          ?footer,
        ],
      ),
    );
  }
}

/// The leading time column. Fixed width and tabular figures so every card in a
/// list aligns on the same digits.
class _Gutter extends StatelessWidget {
  final SubjectLead lead;
  const _Gutter(this.lead);

  static const _tabular = [FontFeature.tabularFigures()];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lead.primary,
            style: const TextStyle(
              fontSize: 15,
              height: 1.2,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
              fontFeatures: _tabular,
              letterSpacing: -0.2,
            ),
          ),
          if (lead.secondary != null)
            Text(
              lead.secondary!,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.35,
                fontWeight: FontWeight.w500,
                color: AppColors.muted,
                fontFeatures: _tabular,
                letterSpacing: -0.2,
              ),
            ),
          if (lead.caption != null) ...[
            const SizedBox(height: 3),
            Text(
              lead.caption!,
              maxLines: 1,
              // Never silently truncate the length — it either fits or it says
              // so with an ellipsis.
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                height: 1.1,
                letterSpacing: -0.1,
                fontWeight: FontWeight.w500,
                color: AppColors.faint,
                fontFeatures: _tabular,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A single icon + value line. Public so the Дома hero can reuse the exact
/// treatment without adopting the whole card.
class SubjectMetaRow extends StatelessWidget {
  final SubjectMeta meta;
  const SubjectMetaRow(this.meta, {super.key});

  @override
  Widget build(BuildContext context) {
    final label = Text(
      meta.text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 12.5,
        fontWeight: meta.onTap == null ? FontWeight.w400 : FontWeight.w600,
        color: meta.onTap == null ? AppColors.muted : AppColors.navy,
        decoration: meta.onTap == null ? null : TextDecoration.underline,
        decorationColor: AppColors.navy,
      ),
    );

    return Row(
      children: [
        if (meta.asset != null)
          SvgPicture.asset(
            meta.asset!,
            width: 14,
            height: 14,
            colorFilter: const ColorFilter.mode(AppColors.faint, BlendMode.srcIn),
          )
        else
          Icon(meta.icon, size: 14, color: AppColors.faint),
        const SizedBox(width: 6),
        Flexible(
          child: meta.onTap == null
              ? label
              : GestureDetector(onTap: meta.onTap, child: label),
        ),
      ],
    );
  }
}
