import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The link to the prayer team's Google Sheet (documentation/prayer/), where
/// the anonymous silent prayers givers send with their offerings collect for
/// this Sabbath ("Active" tab).
///
/// Access is controlled by the Sheet's own Google sharing setting. It is
/// currently "Anyone with the link" (church's choice, 2026-09): the prayers
/// are anonymous, but anyone holding the link — which ships inside this app —
/// can read them. Switching the Sheet to "Restricted" makes the link open
/// only for accounts it is shared with; no app change is needed either way.
/// A build can bake a link in with --dart-define=PRAYER_SHEET_URL=...;
/// otherwise the deacon pastes it once on the hub.
class PrayerSheet {
  static const _key = 'cvendor.prayer_sheet_url.v1';
  /// The church's prayer requests Sheet.
  static const builtIn = String.fromEnvironment(
    'PRAYER_SHEET_URL',
    defaultValue: 'https://docs.google.com/spreadsheets/d/1kP9OotJrrlm0-eRAPoMlNnKzN9Qyi64Z56mGj913Uso/edit?usp=sharing',
  );

  /// Accept only a Google Sheets link, so a mistyped or unrelated URL is never
  /// opened from the hub.
  static String? normalise(String raw) {
    final t = raw.trim();
    final uri = Uri.tryParse(t);
    if (uri == null || uri.scheme != 'https' || uri.host != 'docs.google.com') return null;
    if (!uri.path.startsWith('/spreadsheets/d/')) return null;
    return t;
  }

  static Future<String?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null && saved.isNotEmpty) return saved;
    return builtIn.isEmpty ? null : builtIn;
  }

  static Future<void> save(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, url);
  }
}

final prayerSheetUrlProvider = FutureProvider<String?>((ref) => PrayerSheet.load());
