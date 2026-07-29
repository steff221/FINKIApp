import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// The last good answer the server gave, kept on the phone.
///
/// A timetable changes a few times a semester, so the copy from yesterday is
/// almost always the right thing to show while the network is being asked for
/// today's. That is the whole point: the app opens with data, not a spinner,
/// and it still opens with data on the train home.
///
/// Deliberately dumb — raw response JSON in, raw response JSON out, keyed by
/// request. Nothing here knows what a [ScheduleSlot] is, so nothing here breaks
/// when the models change.
class JsonCache {
  static const _prefix = 'cache:';
  static const _stampPrefix = 'cache_at:';

  final SharedPreferences _prefs;

  JsonCache(this._prefs);

  /// Reads the store into memory once, at launch.
  static Future<JsonCache> open() async =>
      JsonCache(await SharedPreferences.getInstance());

  /// Stores [data] — anything `jsonEncode` accepts — under [key].
  ///
  /// A cache write must never take a screen down with it: an entry we cannot
  /// encode is simply an entry we will not have next time.
  Future<void> write(String key, Object? data) async {
    try {
      await _prefs.setString('$_prefix$key', jsonEncode(data));
      await _prefs.setInt(
          '$_stampPrefix$key', DateTime.now().millisecondsSinceEpoch);
    } catch (_) {
      // Not worth reporting — see above.
    }
  }

  /// The stored response, or null when there is none (or it is corrupt).
  dynamic read(String key) {
    final raw = _prefs.getString('$_prefix$key');
    if (raw == null) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  bool has(String key) => _prefs.containsKey('$_prefix$key');

  /// When [key] was last written — what "зачувано пред 2 часа" is built from.
  DateTime? writtenAt(String key) {
    final ms = _prefs.getInt('$_stampPrefix$key');
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// Drops everything. Called on sign-out: the next account must not inherit
  /// the previous one's timetable.
  Future<void> clear() async {
    for (final key in _prefs.getKeys().toList()) {
      if (key.startsWith(_prefix) || key.startsWith(_stampPrefix)) {
        await _prefs.remove(key);
      }
    }
  }
}
