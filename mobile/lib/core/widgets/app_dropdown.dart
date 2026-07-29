import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_shape.dart';
import 'labeled_field.dart';

/// The app's select control. One widget so a day picker and a filter behave and
/// look identical wherever they appear.
///
/// The open menu echoes the cards: the chosen row is marked by a navy rule on
/// its leading edge rather than a grey wash, so "which one is picked" reads the
/// same way everywhere in the app.
class AppDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;

  /// Value → what the student reads, in the order they should see them.
  final List<(T, String)> options;

  final ValueChanged<T?> onChanged;

  /// Label for the "no choice" row. Null makes the field required.
  final String? emptyLabel;

  const AppDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.emptyLabel,
  });

  @override
  Widget build(BuildContext context) {
    Widget row(String text, {required bool selected, bool muted = false}) {
      return Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 3,
            height: 18,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: selected ? AppColors.navy : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.grabber),
            ),
          ),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: muted
                    ? AppColors.muted
                    : (selected ? AppColors.navy : AppColors.ink),
              ),
            ),
          ),
        ],
      );
    }

    final entries = <DropdownMenuItem<T?>>[
      if (emptyLabel != null)
        DropdownMenuItem<T?>(
          value: null,
          child: row(emptyLabel!, selected: value == null, muted: true),
        ),
      for (final (v, text) in options)
        DropdownMenuItem<T?>(
          value: v,
          child: row(text, selected: v == value),
        ),
    ];

    return LabeledField(
      label: label,
      child: DropdownButtonFormField<T?>(
        initialValue: value,
        isExpanded: true,
        decoration: const InputDecoration(),
        icon: const Icon(Icons.expand_more_rounded, size: 20, color: AppColors.faint),
        borderRadius: BorderRadius.circular(AppRadius.card),
        dropdownColor: AppColors.card,
        elevation: 3,
        menuMaxHeight: 340,
        style: const TextStyle(fontSize: 14, color: AppColors.ink),
        // The collapsed field shows the plain label — the rule belongs to the
        // open menu, not the closed control.
        selectedItemBuilder: (context) => [
          if (emptyLabel != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                emptyLabel!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, color: AppColors.muted),
              ),
            ),
          for (final (_, text) in options)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
            ),
        ],
        items: entries,
        onChanged: onChanged,
      ),
    );
  }
}
