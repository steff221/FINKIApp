import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shape.dart';

/// A persistent label over one of the app's standard fields. The label stays
/// put — a placeholder would vanish as soon as the student typed.
///
/// Shared by Најава and Нов профил so the two screens cannot drift apart.
class AuthField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;

  /// Bundled Uicons SVG for the prefix, tinted to [AppColors.faint]. Falls back
  /// to [iconData] when the set has no glyph for the field.
  final String? icon;
  final IconData? iconData;

  final Widget? suffix;
  final String? errorText;
  final bool obscureText;
  final bool autocorrect;
  final bool enableSuggestions;
  final TextCapitalization textCapitalization;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<String>? autofillHints;
  final VoidCallback? onChanged;
  final VoidCallback? onSubmitted;

  const AuthField({
    super.key,
    required this.label,
    required this.controller,
    required this.focusNode,
    this.icon,
    this.iconData,
    this.suffix,
    this.errorText,
    this.obscureText = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.textCapitalization = TextCapitalization.none,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.control),
      borderSide: const BorderSide(color: AppColors.danger),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: text.labelLarge?.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscureText,
          autocorrect: autocorrect,
          enableSuggestions: enableSuggestions,
          textCapitalization: textCapitalization,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          onChanged: (_) => onChanged?.call(),
          onSubmitted: (_) => onSubmitted?.call(),
          style: text.bodyMedium?.copyWith(color: AppColors.ink),
          decoration: InputDecoration(
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 16, right: 12),
              child: icon != null
                  ? SvgPicture.asset(
                      icon!,
                      width: 18,
                      height: 18,
                      colorFilter:
                          const ColorFilter.mode(AppColors.faint, BlendMode.srcIn),
                    )
                  : Icon(iconData, size: 18, color: AppColors.faint),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            suffixIcon: suffix,
            // Material owns the error slot so the message is announced to
            // VoiceOver; the borders below keep it on the app's danger red
            // rather than the M3 scheme error colour.
            errorText: errorText,
            errorStyle: text.bodySmall?.copyWith(color: AppColors.danger),
            errorBorder: errorBorder,
            focusedErrorBorder: errorBorder,
          ),
        ),
      ],
    );
  }
}

/// The eye toggle both password fields use.
class PasswordToggle extends StatelessWidget {
  final bool obscured;
  final VoidCallback onPressed;

  const PasswordToggle({super.key, required this.obscured, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      iconSize: 20,
      color: AppColors.faint,
      tooltip: obscured ? 'Прикажи лозинка' : 'Скриј лозинка',
      icon: Icon(obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined),
      onPressed: onPressed,
    );
  }
}

/// Form-level failure line (bad credentials, taken e-mail, no network).
class AuthFormError extends StatelessWidget {
  final String message;
  const AuthFormError(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 1),
          child: Icon(Icons.error_outline_rounded, size: 16, color: AppColors.danger),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.danger),
          ),
        ),
      ],
    );
  }
}

/// Full-width primary action. The label stays in the tree while loading, just
/// invisible, so the button keeps its exact height at any Dynamic Type size.
class AuthSubmitButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  const AuthSubmitButton({
    super.key,
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          disabledBackgroundColor: AppColors.navy.withValues(alpha: 0.30),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.90),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Opacity(opacity: loading ? 0 : 1, child: Text(label)),
            if (loading)
              const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }
}

/// The "question + action" line that swaps between Најава and Нов профил.
class AuthSwitchLink extends StatelessWidget {
  final String question;
  final String action;
  final VoidCallback onPressed;

  const AuthSwitchLink({
    super.key,
    required this.question,
    required this.action,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(question, style: text.bodyMedium?.copyWith(color: AppColors.muted)),
        TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.navy,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            minimumSize: const Size(0, 44),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            action,
            style: text.bodyMedium?.copyWith(
              color: AppColors.navy,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
