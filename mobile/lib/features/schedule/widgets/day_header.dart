import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/models.dart';

/// Section header above a day's classes: the day's name, and nothing else.
/// Shared by Мој Распоред, Дома and Распоред.
class DayHeader extends StatelessWidget {
  final int day; // 0=Mon … 4=Fri

  const DayHeader({super.key, required this.day});

  @override
  Widget build(BuildContext context) {
    // The timetable groups on whatever the API returns, so a day outside the
    // working week still gets a header rather than a range error.
    final name = day >= 0 && day < kDayNames.length ? kDayNames[day] : 'Ден ${day + 1}';
    // Set as a small caps-style label, as the design has it — the day is a
    // section marker, not a heading competing with the class titles.
    final label = name.toUpperCase();

    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Text(label,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
              letterSpacing: 0.4)),
    );
  }
}
