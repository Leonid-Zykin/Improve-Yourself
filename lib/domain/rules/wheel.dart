import 'dart:math' as math;

/// Life wheel score 1–10 from consistency, goal progress, and bad-habit penalty.
class WheelRules {
  const WheelRules();

  /// [consistency] 0–1, [goalProgress] 0–1, [badHabitPenalty] 0–1 (higher = worse).
  double score({
    required double consistency,
    required double goalProgress,
    double badHabitPenalty = 0,
  }) {
    final raw = (consistency * 0.6 + goalProgress * 0.4) * 10 -
        badHabitPenalty * 3;
    return raw.clamp(1.0, 10.0);
  }

  /// Aggregate goal progress for an area (mean of ratios).
  double averageGoalProgress(Iterable<double> ratios) {
    final list = ratios.toList();
    if (list.isEmpty) return 0.5; // neutral when no goals yet
    return list.fold<double>(0, (a, b) => a + b) / list.length;
  }

  double clampScore(double v) => v.clamp(1.0, 10.0);

  /// Soften extreme penalties.
  double softenPenalty(double p) => math.min(1.0, math.max(0.0, p));
}
