import 'dart:math' as math;

/// XP / level curve: level = floor(sqrt(xp / 100)) + 1
class XpRules {
  const XpRules({this.xpPerLevelBase = 100});

  final int xpPerLevelBase;

  int levelForXp(int xpTotal) {
    if (xpTotal <= 0) return 1;
    return math.sqrt(xpTotal / xpPerLevelBase).floor() + 1;
  }

  /// XP needed to reach [level] (level starts at 1).
  int xpForLevel(int level) {
    if (level <= 1) return 0;
    final n = level - 1;
    return n * n * xpPerLevelBase;
  }

  int xpToNextLevel(int xpTotal) {
    final level = levelForXp(xpTotal);
    return xpForLevel(level + 1) - xpTotal;
  }

  /// Apply delta; never go below 0.
  int applyDelta(int current, int delta) =>
      math.max(0, current + delta);
}
