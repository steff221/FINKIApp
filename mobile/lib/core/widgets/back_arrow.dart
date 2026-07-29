import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The way back out of a screen pushed over the shell.
///
/// [ScreenHeader] draws no bar, so it gets no automatic leading of its own —
/// every pushed screen passes this as its `leading` instead, which is what
/// keeps the arrow in the same place at the same weight throughout the app.
class BackArrow extends StatelessWidget {
  const BackArrow({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_rounded, size: 26),
      color: AppColors.navy,
      tooltip: 'Назад',
      onPressed: () => Navigator.of(context).pop(),
    );
  }
}
