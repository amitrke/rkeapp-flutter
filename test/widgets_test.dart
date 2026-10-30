import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rkeapp/widgets.dart';

void main() {
  group('clockLabel', () {
    test('drops minutes on the hour', () {
      expect(clockLabel(DateTime(2026, 1, 1, 19)), '7 pm');
      expect(clockLabel(DateTime(2026, 1, 1, 0)), '12 am');
      expect(clockLabel(DateTime(2026, 1, 1, 12)), '12 pm');
    });

    test('keeps minutes when asked or when not on the hour', () {
      expect(clockLabel(DateTime(2026, 1, 1, 18, 10), minutes: true), '6:10 pm');
      expect(clockLabel(DateTime(2026, 1, 1, 7, 30)), '7:30 am');
    });
  });

  group('relativeTime', () {
    test('is empty for a missing date', () {
      expect(relativeTime(0), '');
    });

    test('uses hours and days for recent dates', () {
      final now = DateTime.now();
      expect(relativeTime(now.subtract(const Duration(hours: 3)).millisecondsSinceEpoch), '3h ago');
      expect(relativeTime(now.subtract(const Duration(days: 2)).millisecondsSinceEpoch), '2 days ago');
    });

    test('uses a date for anything over a week old', () {
      expect(relativeTime(DateTime(2023, 1, 16).millisecondsSinceEpoch), '16 Jan 2023');
    });
  });

  group('shortDate', () {
    test('formats ISO dates and rejects bad input', () {
      expect(shortDate('2026-11-08'), 'Nov 8');
      expect(shortDate('not a date'), '');
    });
  });

  group('weatherIcon', () {
    test('maps OpenWeatherMap codes, day and night', () {
      expect(weatherIcon('01d'), Icons.wb_sunny_outlined);
      expect(weatherIcon('01n'), Icons.nightlight_outlined);
      expect(weatherIcon('10d'), Icons.water_drop_outlined);
      expect(weatherIcon('50n'), Icons.foggy);
      expect(weatherIcon(''), Icons.wb_sunny_outlined);
    });
  });
}
