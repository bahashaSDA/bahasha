/// The weekly Sabbath prayer cycle.
///
/// A prayer request belongs to the Sabbath it will be prayed for: anything
/// submitted from Sunday 00:00 through Saturday 23:59 (East Africa Time) is
/// that week's Saturday. The prayer team prays over the active cycle on the
/// Sabbath; on Sunday the ended cycle is archived and the next one begins.
///
/// The cycle is computed in a FIXED zone — Africa/Nairobi, UTC+3, no daylight
/// saving — never the phone's own timezone, so a giver whose phone is set to
/// another zone still lands in the church's cycle. The authoritative copy of
/// this rule runs server-side in the Google Apps Script
/// (documentation/prayer/Code.gs, `sabbathFor`); this one labels the local
/// outbox and is unit-tested against the same cases.
class PrayerCycle {
  PrayerCycle._();

  /// East Africa Time offset. Kenya has not observed DST since 1942.
  static const Duration eatOffset = Duration(hours: 3);

  /// The EAT calendar date (at midnight, as a UTC-less DateTime) for [instant].
  static DateTime eatDate(DateTime instant) {
    final eat = instant.toUtc().add(eatOffset);
    return DateTime.utc(eat.year, eat.month, eat.day);
  }

  /// The Sabbath (Saturday) this [instant] belongs to.
  static DateTime sabbathFor(DateTime instant) {
    final day = eatDate(instant);
    // DateTime.weekday: Mon=1 … Sat=6, Sun=7. Sunday starts a new week, so it
    // maps six days forward to the following Saturday.
    final daysUntilSaturday = (DateTime.saturday - day.weekday) % 7;
    return day.add(Duration(days: daysUntilSaturday));
  }

  /// Stable cycle key, e.g. "2026-09-26" — the Sabbath's date.
  static String keyFor(DateTime instant) => _iso(sabbathFor(instant));

  /// Whether the cycle [key] has ended as of [now] (its Sabbath is before
  /// today's EAT date). Used by the cleanup; the current Sabbath — including
  /// all of Saturday itself — is never considered ended.
  static bool hasEnded(String key, DateTime now) => key.compareTo(_iso(eatDate(now))) < 0;

  static String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
