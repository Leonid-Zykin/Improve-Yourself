/// Consistency Score over a window (default 30 days).
class ConsistencyScore {
  const ConsistencyScore();

  /// Per-subject: doneDays / expectedDays.
  double subjectScore({
    required int doneDays,
    required int expectedDays,
  }) {
    if (expectedDays <= 0) return 0;
    return (doneDays / expectedDays).clamp(0.0, 1.0);
  }

  /// Average across active subjects (simple mean).
  double overall(Iterable<double> subjectScores) {
    final list = subjectScores.toList();
    if (list.isEmpty) return 0;
    final sum = list.fold<double>(0, (a, b) => a + b);
    return (sum / list.length).clamp(0.0, 1.0);
  }

  /// Weighted average by life-area weights (optional).
  double weighted({
    required List<double> scores,
    required List<double> weights,
  }) {
    assert(scores.length == weights.length);
    if (scores.isEmpty) return 0;
    var num = 0.0;
    var den = 0.0;
    for (var i = 0; i < scores.length; i++) {
      num += scores[i] * weights[i];
      den += weights[i];
    }
    if (den == 0) return 0;
    return (num / den).clamp(0.0, 1.0);
  }
}
