/// Corner radii, so a card is the same shape wherever it is built.
///
/// Everything rounded in the app should pick one of these — the values were
/// already in use, just spelled out screen by screen and drifting by 2pt.
abstract final class AppRadius {
  /// Panels and card-like containers (the Дома hero, sheets' content).
  static const card = 16.0;

  /// Cards in a scrolling list — classes and exams. Slightly tighter than
  /// [card] so a column of them reads as a list rather than a stack of panels.
  static const listCard = 14.0;

  /// Controls: text fields, buttons, segmented rows.
  static const control = 14.0;

  /// Small square affordances — the +/✓ and pin chips on cards.
  static const chip = 9.0;

  /// Fully rounded: tags, legend dots, grabber handles.
  static const pill = 999.0;

  /// Modal sheet grabber.
  static const grabber = 2.0;
}
