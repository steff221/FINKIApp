import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';
import 'agenda_item.dart';

/// Macedonian copy for one overlap, from the perspective of the card it sits on.
///
/// A partial clash names the shared minutes, because losing 15 minutes of a
/// class is a different problem from losing all of it.
String conflictSentence(ClassConflict c) => c.partial
    ? 'Се преклопува ${c.overlapMinutes} мин со ${c.otherTitle}'
    : 'Се преклопува со ${c.otherTitle}, ${c.otherStart}';

/// The conflict strip at the bottom of a class card: a tinted sub-surface
/// spanning the full inner width, separated from the metadata stack above it.
///
/// This is deliberately not a metadata row — a conflict is a relationship
/// between two classes, so it names the other one and gets its own surface
/// instead of reading as one more attribute of this one.
class ConflictBanner extends StatelessWidget {
  final List<ClassConflict> conflicts;

  const ConflictBanner({super.key, required this.conflicts});

  @override
  Widget build(BuildContext context) {
    final sentences = conflicts.map(conflictSentence).toList();

    return Semantics(
      container: true,
      label: 'Конфликт во распоредот. ${sentences.join('. ')}',
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.danger.withValues(alpha: 0.06),
            border: Border(top: BorderSide(color: AppColors.danger.withValues(alpha: 0.15))),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nudged onto the first text line's optical centre.
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: SvgPicture.asset(
                    'assets/limit-hand.svg',
                    width: 15,
                    height: 15,
                    colorFilter: const ColorFilter.mode(
                      AppColors.danger,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < sentences.length; i++) ...[
                        if (i > 0) const SizedBox(height: 4),
                        Text(
                          sentences[i],
                          style: const TextStyle(
                            fontSize: 12.5,
                            height: 1.3,
                            fontWeight: FontWeight.w500,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
