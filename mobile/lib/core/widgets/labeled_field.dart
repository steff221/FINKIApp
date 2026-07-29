import 'package:flutter/material.dart';

import '../theme/app_type.dart';

/// A form control with its name set above it.
///
/// Material's floating label wants to sit on an outline. These fields have no
/// outline — they are a fill in the page — so the label has nowhere to land and
/// ends up straddling the top edge. Putting it above solves that and matches
/// how the rest of the app labels things.
class LabeledField extends StatelessWidget {
  final String label;
  final Widget child;

  const LabeledField({super.key, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Text(label, style: AppType.fieldLabel),
        ),
        child,
      ],
    );
  }
}
