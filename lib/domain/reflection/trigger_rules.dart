import '../models/enums.dart';

/// Pure rules: whether an auto reflection should be offered.
class ReflectionTriggerRules {
  const ReflectionTriggerRules({this.maxAutoPerDay = 3});

  final int maxAutoPerDay;

  /// Reflective action kinds (not `other`) or bad-habit slip.
  bool shouldOffer({
    required bool reflectionsEnabled,
    required int autoReflectionsToday,
    required SubjectType subjectType,
    ActionKind? actionKind,
    HabitKind? habitKind,
    required CheckInStatus status,
  }) {
    if (!reflectionsEnabled) return false;
    if (status != CheckInStatus.done) return false;
    if (autoReflectionsToday >= maxAutoPerDay) return false;

    if (subjectType == SubjectType.action) {
      final kind = actionKind ?? ActionKind.other;
      return kind.triggersReflection;
    }
    if (subjectType == SubjectType.habit) {
      return habitKind == HabitKind.bad;
    }
    return false;
  }
}
