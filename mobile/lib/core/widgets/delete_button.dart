import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';

/// The red trash affordance every subject / exam card carries.
///
/// A null [onTap] keeps the glyph in place but dims it and swallows taps —
/// used on browse cards where there is nothing saved to remove yet, so the
/// cards stay visually identical whether or not the action is live.
class CardDeleteButton extends StatelessWidget {
  final VoidCallback? onTap;

  const CardDeleteButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        // Visible glyph is 16x16; pad out to a comfortable tap target.
        padding: const EdgeInsets.all(10),
        child: SvgPicture.asset(
          'assets/trash.svg',
          width: 16,
          height: 16,
          colorFilter: ColorFilter.mode(
            onTap == null ? AppColors.danger.withValues(alpha: 0.3) : AppColors.danger,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}
