import 'package:flutter_test/flutter_test.dart';
import 'package:cvendor/core/prayer_sheet.dart';

void main() {
  test('only a Google Sheets link is accepted for prayer requests', () {
    const ok = 'https://docs.google.com/spreadsheets/d/1AbC_dEf/edit?usp=sharing';
    expect(PrayerSheet.normalise('  $ok  '), ok);
    expect(PrayerSheet.normalise('http://docs.google.com/spreadsheets/d/1AbC'), isNull);
    expect(PrayerSheet.normalise('https://evil.example.com/spreadsheets/d/1AbC'), isNull);
    expect(PrayerSheet.normalise('https://docs.google.com/document/d/1AbC'), isNull);
    expect(PrayerSheet.normalise('not a link'), isNull);
  });

  test('the built-in church prayer sheet link is a valid Sheets link', () {
    expect(PrayerSheet.normalise(PrayerSheet.builtIn), isNotNull);
  });
}
