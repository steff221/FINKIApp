/// The app's Lottie compositions, named once.
///
/// Referring to them by constant rather than by path keeps a re-export from the
/// design tool — which is where these come from — out of a dozen widget files.
abstract final class AppArt {
  /// Shown wherever the answer is "nothing to do here": an empty timetable, a
  /// free day, the end of a teaching day.
  static const programmer = 'assets/animations/Programmer.json';

  /// The teaching day is over — a dog with a coffee, resting. The art has to
  /// agree with the message: nothing left to do today.
  static const restingDog = 'assets/animations/LazyDoge Coffee.json';

  /// The in-app spinner (see FinkiLoader).
  static const loading = 'assets/animations/loading.json';
}
