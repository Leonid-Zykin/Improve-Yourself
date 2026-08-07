import '../models/models.dart';

/// Two-day rule: streak stays alive while consecutive misses from today
/// backwards are fewer than 3. Soft break at missedDays >= 3.
class TwoDayRule {
  const TwoDayRule({this.missLimit = 2});

  /// Max consecutive misses before soft break.
  /// missLimit=2 means warning at 2 misses, broken at 3+.
  final int missLimit;

  /// [doneDates] — set of local dates (YYYY-MM-DD) where status was `done`.
  /// [today] — calendar day in user's local timezone.
  TwoDayResult evaluate({
    required Set<String> doneDates,
    required DateTime today,
  }) {
    final todayKey = formatLocalDate(today);
    var missed = 0;
    var cursor = DateTime(today.year, today.month, today.day);

    // If today is already done, streak is healthy (0 misses).
    if (doneDates.contains(todayKey)) {
      return const TwoDayResult(missedDays: 0, state: TwoDayState.ok);
    }

    // Never completed — fresh subject: only today's open miss (ok), not a break.
    if (doneDates.isEmpty) {
      return const TwoDayResult(missedDays: 1, state: TwoDayState.ok);
    }

    // Count consecutive days without done, starting from today backwards.
    while (true) {
      final key = formatLocalDate(cursor);
      if (doneDates.contains(key)) break;
      missed++;
      if (missed > missLimit + 5) break; // safety bound
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return TwoDayResult(missedDays: missed, state: stateFor(missed));
  }

  TwoDayState stateFor(int missedDays) {
    if (missedDays <= 1) return TwoDayState.ok;
    if (missedDays == missLimit) return TwoDayState.warning;
    if (missedDays > missLimit) return TwoDayState.broken;
    return TwoDayState.ok;
  }
}

String formatLocalDate(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

DateTime parseLocalDate(String yyyyMmDd) {
  final parts = yyyyMmDd.split('-');
  return DateTime(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
}
