import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_shape.dart';
import '../theme/app_type.dart';

/// One fact on an exam card — a glyph and its value, set inline.
///
/// [strong] is for the time: it is the fact a student is scanning for, so it
/// carries the weight while rooms and notes stay quiet.
class ExamFact {
  final IconData icon;
  final String text;
  final bool strong;

  const ExamFact(this.icon, this.text, {this.strong = false});
}

/// One exam: the subject, a line of facts, and whatever the faculty added as a
/// note.
///
/// Bordered rather than raised — exams arrive in dense date-grouped runs, and a
/// column of shadows at that rhythm reads as noise. Classes, which are spaced
/// out across a week, keep theirs.
class ExamCard extends StatelessWidget {
  final String title;
  final List<ExamFact> facts;
  final String? note;

  /// Grey on an ordinary exam; the exams accent on the nearest one still ahead.
  final Color border;

  final Widget? trailing;
  final EdgeInsets margin;

  const ExamCard({
    super.key,
    required this.title,
    required this.facts,
    this.note,
    this.border = AppColors.border,
    this.trailing,
    this.margin = const EdgeInsets.only(bottom: 8),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: EdgeInsets.fromLTRB(14, 13, trailing == null ? 14 : 8, 13),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.listCard),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                if (facts.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  // Wraps rather than truncating: a long room list is worth a
                  // second line, and dropping it would hide where to turn up.
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [for (final fact in facts) _Fact(fact)],
                  ),
                ],
                if (note != null && note!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    note!,
                    style: const TextStyle(
                      fontSize: 11.5,
                      height: 1.3,
                      fontWeight: FontWeight.w400,
                      color: AppColors.faint,
                    ),
                  ),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  final ExamFact fact;
  const _Fact(this.fact);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(fact.icon, size: 14, color: AppColors.faint),
        const SizedBox(width: 5),
        Text(
          fact.text,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: fact.strong ? FontWeight.w600 : FontWeight.w400,
            color: fact.strong ? AppColors.ink : AppColors.muted,
          ),
        ),
      ],
    );
  }
}
