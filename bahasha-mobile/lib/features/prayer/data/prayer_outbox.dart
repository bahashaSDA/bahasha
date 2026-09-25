import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../domain/prayer_cycle.dart';

/// A silent prayer request, given alongside an offering.
///
/// ANONYMOUS BY DESIGN: it carries only the prayer text and when it is for.
/// No name, phone, user or device id, home church or offering reference
/// ever leaves the phone with it — nothing the prayer team (or anyone who can
/// read the sheet) could use to tell who wrote it.
class PrayerRequest {
  const PrayerRequest({
    required this.id,
    required this.text,
    required this.submittedAt,
    required this.cycle,
  });

  /// A random UUID minted for this prayer alone (not derived from the giver
  /// or the offering) — only so a retry never creates a second row.
  final String id;
  final String text;

  /// Kept on the phone for queue order only; never sent.
  final DateTime submittedAt; // UTC

  /// Sabbath the prayer is for (PrayerCycle.keyFor). The sheet recomputes it
  /// authoritatively in Africa/Nairobi time when it arrives.
  final String cycle;

  Map<String, dynamic> toJson() => {
        'requestId': id,
        'prayer': text,
        'cycle': cycle,
        'submittedAt': submittedAt.toUtc().toIso8601String(),
      };

  factory PrayerRequest.fromJson(Map<String, dynamic> j) => PrayerRequest(
        id: j['requestId'] as String,
        text: j['prayer'] as String,
        submittedAt: DateTime.parse(j['submittedAt'] as String),
        cycle: j['cycle'] as String,
      );

  /// Normalise what the giver typed: trimmed, and null when empty or
  /// whitespace-only (an empty prayer is never saved).
  static String? clean(String? raw) {
    final t = (raw ?? '').trim();
    if (t.isEmpty) return null;
    return t.length > maxLength ? t.substring(0, maxLength) : t;
  }

  static const int maxLength = 1000;
}

/// Prayers waiting on the phone to be handed to a CVendor hub over BLE. The
/// hub (which has internet) forwards them to the prayer team's Google Sheet;
/// Bahasha itself never goes online. A prayer is removed from the phone as
/// soon as a hub acknowledges it — the phone keeps no prayer archive.
class PrayerOutbox {
  static const _uuid = Uuid();
  static const _prefsKey = 'bahasha.prayers.outbox.v1';

  /// Persist an anonymous prayer. Returns null (and saves nothing) when
  /// [text] is empty or whitespace. The caller only enqueues AFTER the
  /// offering has been saved.
  Future<PrayerRequest?> enqueue({required String? text, DateTime? now}) async {
    final prayer = PrayerRequest.clean(text);
    if (prayer == null) return null;
    final at = (now ?? DateTime.now()).toUtc();
    final request = PrayerRequest(id: _uuid.v4(), text: prayer, submittedAt: at, cycle: PrayerCycle.keyFor(at));
    await _save([...await pending(), request]);
    return request;
  }

  /// Prayers not yet handed to a hub, oldest first.
  Future<List<PrayerRequest>> pending() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      return (jsonDecode(raw) as List).cast<Map<String, dynamic>>().map(PrayerRequest.fromJson).toList();
    } catch (_) {
      return const [];
    }
  }

  /// A hub has the prayer: it leaves the phone.
  Future<void> remove(String id) async => _save((await pending()).where((p) => p.id != id).toList());

  Future<void> _save(List<PrayerRequest> queue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(queue.map((q) => q.toJson()).toList()));
  }

  /// Remove every queued prayer from this phone (account deletion).
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }
}
