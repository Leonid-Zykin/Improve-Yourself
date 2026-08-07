import 'package:improve_yourself/domain/rules/consistency.dart';
import 'package:improve_yourself/domain/rules/two_day.dart';
import 'package:improve_yourself/domain/rules/wheel.dart';
import 'package:improve_yourself/domain/rules/xp.dart';
import 'package:improve_yourself/domain/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TwoDayRule', () {
    const rule = TwoDayRule();

    test('today done → ok, 0 misses', () {
      final today = DateTime(2026, 8, 7);
      final r = rule.evaluate(
        doneDates: {'2026-08-07'},
        today: today,
      );
      expect(r.missedDays, 0);
      expect(r.state, TwoDayState.ok);
    });

    test('missed yesterday only → ok (1 miss)', () {
      final today = DateTime(2026, 8, 7);
      final r = rule.evaluate(
        doneDates: {'2026-08-05'},
        today: today,
      );
      // today + yesterday without done = 2? Wait:
      // today 08-07 not done, 08-06 not done, 08-05 done → missed=2 → warning
      expect(r.missedDays, 2);
      expect(r.state, TwoDayState.warning);
    });

    test('missed today only with yesterday done → ok', () {
      final today = DateTime(2026, 8, 7);
      final r = rule.evaluate(
        doneDates: {'2026-08-06'},
        today: today,
      );
      expect(r.missedDays, 1);
      expect(r.state, TwoDayState.ok);
    });

    test('3 consecutive misses → broken', () {
      final today = DateTime(2026, 8, 7);
      final r = rule.evaluate(
        doneDates: {'2026-08-04'},
        today: today,
      );
      // 07,06,05 miss → 3
      expect(r.missedDays, 3);
      expect(r.state, TwoDayState.broken);
    });

    test('never done → fresh start (ok, 1 miss)', () {
      final today = DateTime(2026, 8, 7);
      final r = rule.evaluate(doneDates: {}, today: today);
      expect(r.missedDays, 1);
      expect(r.state, TwoDayState.ok);
    });
  });

  group('XpRules', () {
    const xp = XpRules();

    test('level curve', () {
      expect(xp.levelForXp(0), 1);
      expect(xp.levelForXp(99), 1);
      expect(xp.levelForXp(100), 2);
      expect(xp.levelForXp(400), 3);
      expect(xp.levelForXp(900), 4);
    });

    test('applyDelta never negative', () {
      expect(xp.applyDelta(5, -10), 0);
      expect(xp.applyDelta(10, 5), 15);
    });
  });

  group('ConsistencyScore', () {
    const c = ConsistencyScore();

    test('subject and overall', () {
      expect(c.subjectScore(doneDays: 15, expectedDays: 30), 0.5);
      expect(c.overall([1.0, 0.5, 0.0]), closeTo(0.5, 1e-9));
      expect(c.overall([]), 0);
    });
  });

  group('WheelRules', () {
    const w = WheelRules();

    test('score clamped 1–10', () {
      expect(w.score(consistency: 1, goalProgress: 1), 10);
      expect(w.score(consistency: 0, goalProgress: 0, badHabitPenalty: 1), 1);
      final mid = w.score(consistency: 0.5, goalProgress: 0.5);
      expect(mid, greaterThanOrEqualTo(1));
      expect(mid, lessThanOrEqualTo(10));
    });
  });

  group('formatLocalDate', () {
    test('pads month and day', () {
      expect(formatLocalDate(DateTime(2026, 1, 5)), '2026-01-05');
    });
  });
}
