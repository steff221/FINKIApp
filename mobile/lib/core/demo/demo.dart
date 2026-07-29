/// Presentation build: no server, no sign-in.
///
/// Every screen behaves exactly as it does against the real backend — the data
/// simply comes from a snapshot bundled in `assets/demo/` instead of over the
/// wire, and anything changed during the demo (saving a class, pinning an exam,
/// adding an entry) lives in memory until the app is closed.
///
/// Switched on at build time:
///
/// ```
/// flutter build ios --release --dart-define=DEMO=true
/// ```
const kDemoMode = bool.fromEnvironment('DEMO');

/// Who the app is signed in as while presenting.
const kDemoName = 'Стефан';
const kDemoEmail = 'stefan.perovski20@gmail.com';
