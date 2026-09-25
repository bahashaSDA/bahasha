import 'package:flutter_test/flutter_test.dart';
import 'package:bahasha/features/prayer/data/prayer_outbox.dart';
import 'package:bahasha/features/prayer/domain/prayer_cycle.dart';

void main() {
  // 2026-09-26 is a Saturday (Sabbath); 2026-09-27 a Sunday.
  DateTime eat(int y, int m, int d, int h, [int min = 0]) =>
      DateTime.utc(y, m, d, h, min).subtract(PrayerCycle.eatOffset);

  group('PrayerCycle.keyFor (Africa/Nairobi, fixed UTC+3)', () {
    test('Sunday through Saturday belong to that Saturday', () {
      expect(PrayerCycle.keyFor(eat(2026, 9, 20, 0, 0)), '2026-09-26'); // Sun 00:00
      expect(PrayerCycle.keyFor(eat(2026, 9, 23, 12)), '2026-09-26'); // Wed
      expect(PrayerCycle.keyFor(eat(2026, 9, 26, 9)), '2026-09-26'); // Sabbath morning
      expect(PrayerCycle.keyFor(eat(2026, 9, 26, 23, 59)), '2026-09-26'); // Sat 23:59
    });

    test('Sunday 00:00 EAT starts the next cycle', () {
      expect(PrayerCycle.keyFor(eat(2026, 9, 27, 0, 0)), '2026-10-03');
    });

    test('uses EAT, not UTC or the phone timezone, at the day boundary', () {
      // Saturday 22:30 UTC is already Sunday 01:30 in Nairobi.
      expect(PrayerCycle.keyFor(DateTime.utc(2026, 9, 26, 22, 30)), '2026-10-03');
      // Saturday 20:59 UTC is Saturday 23:59 in Nairobi.
      expect(PrayerCycle.keyFor(DateTime.utc(2026, 9, 26, 20, 59)), '2026-09-26');
    });

    test('crosses month and year ends', () {
      expect(PrayerCycle.keyFor(eat(2026, 12, 28, 10)), '2027-01-02');
    });
  });

  group('PrayerCycle.hasEnded (the Sunday cleanup rule)', () {
    test('the current Sabbath is never ended, including all of Saturday', () {
      expect(PrayerCycle.hasEnded('2026-09-26', eat(2026, 9, 26, 23, 59)), isFalse);
      expect(PrayerCycle.hasEnded('2026-09-26', eat(2026, 9, 22, 8)), isFalse);
    });

    test('ends on Sunday, and stays ended if cleanup ran late (missed days)', () {
      expect(PrayerCycle.hasEnded('2026-09-26', eat(2026, 9, 27, 0, 30)), isTrue);
      expect(PrayerCycle.hasEnded('2026-09-26', eat(2026, 10, 8, 9)), isTrue);
      expect(PrayerCycle.hasEnded('2026-09-19', eat(2026, 10, 8, 9)), isTrue);
    });

    test('a prayer sent on Sunday lands in the next cycle, untouched by cleanup', () {
      final sunday = eat(2026, 9, 27, 0, 10);
      expect(PrayerCycle.hasEnded(PrayerCycle.keyFor(sunday), sunday), isFalse);
    });
  });

  group('PrayerRequest.clean', () {
    test('empty and whitespace-only prayers are not saved', () {
      expect(PrayerRequest.clean(null), isNull);
      expect(PrayerRequest.clean(''), isNull);
      expect(PrayerRequest.clean('   \n\t '), isNull);
    });

    test('trims and caps length', () {
      expect(PrayerRequest.clean('  Pray for my family  '), 'Pray for my family');
      expect(PrayerRequest.clean('a' * 1500)!.length, PrayerRequest.maxLength);
    });
  });
}
