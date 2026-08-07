import 'enums.dart';

export 'enums.dart';

class Profile {
  const Profile({
    required this.id,
    required this.displayName,
    required this.timezone,
    required this.createdAt,
    this.onboardingCompleted = false,
  });

  final String id;
  final String displayName;
  final String timezone;
  final DateTime createdAt;
  final bool onboardingCompleted;
}

class Vision {
  const Vision({
    required this.id,
    required this.title,
    this.targetDate,
    this.sortOrder = 0,
  });

  final String id;
  final String title;
  final DateTime? targetDate;
  final int sortOrder;
}

class LifeArea {
  const LifeArea({
    required this.id,
    required this.key,
    required this.title,
    required this.color,
    required this.icon,
    this.sortOrder = 0,
  });

  final String id;
  final String key;
  final String title;
  final int color;
  final String icon;
  final int sortOrder;
}

class Goal {
  const Goal({
    required this.id,
    required this.lifeAreaId,
    required this.title,
    this.visionId,
    this.targetValue,
    this.unit,
    this.currentValue = 0,
    this.deadline,
    this.status = GoalStatus.active,
  });

  final String id;
  final String lifeAreaId;
  final String? visionId;
  final String title;
  final double? targetValue;
  final String? unit;
  final double currentValue;
  final DateTime? deadline;
  final GoalStatus status;

  double get progressRatio {
    final target = targetValue;
    if (target == null || target <= 0) return 0;
    return (currentValue / target).clamp(0.0, 1.0);
  }
}

class ActionItem {
  const ActionItem({
    required this.id,
    required this.lifeAreaId,
    required this.title,
    this.goalId,
    this.schedule = ActionSchedule.daily,
    this.kind = ActionKind.other,
    this.xpReward = 10,
    this.active = true,
  });

  final String id;
  final String? goalId;
  final String lifeAreaId;
  final String title;
  final ActionSchedule schedule;
  final ActionKind kind;
  final int xpReward;
  final bool active;
}

class Artifact {
  const Artifact({
    required this.id,
    required this.type,
    required this.localDate,
    required this.createdAt,
    this.title,
    this.body,
    this.metricValue,
    this.metricUnit,
    this.localPath,
    this.thumbnailPath,
    this.goalId,
    this.lifeAreaId,
    this.actionId,
    this.checkInId,
  });

  final String id;
  final ArtifactType type;
  final String? title;
  final String? body;
  final double? metricValue;
  final String? metricUnit;
  final String? localPath;
  final String? thumbnailPath;
  final String? goalId;
  final String? lifeAreaId;
  final String? actionId;
  final String? checkInId;
  final String localDate;
  final DateTime createdAt;
}

class Reflection {
  const Reflection({
    required this.id,
    required this.promptKey,
    required this.promptText,
    required this.trigger,
    required this.localDate,
    required this.createdAt,
    this.answer,
    this.subjectType,
    this.subjectId,
    this.actionKind,
    this.checkInId,
    this.skipped = false,
  });

  final String id;
  final String promptKey;
  final String promptText;
  final String? answer;
  final ReflectionTrigger trigger;
  final SubjectType? subjectType;
  final String? subjectId;
  final ActionKind? actionKind;
  final String? checkInId;
  final bool skipped;
  final String localDate;
  final DateTime createdAt;
}

class Habit {
  const Habit({
    required this.id,
    required this.kind,
    required this.title,
    this.xpDelta = 5,
    this.active = true,
  });

  final String id;
  final HabitKind kind;
  final String title;
  final int xpDelta;
  final bool active;
}

class HabitAreaEffect {
  const HabitAreaEffect({
    required this.habitId,
    required this.lifeAreaId,
    this.weight = 1.0,
  });

  final String habitId;
  final String lifeAreaId;
  final double weight;
}

class CheckIn {
  const CheckIn({
    required this.id,
    required this.subjectType,
    required this.subjectId,
    required this.localDate,
    required this.status,
    required this.createdAt,
    this.note,
  });

  final String id;
  final SubjectType subjectType;
  final String subjectId;
  final String localDate; // YYYY-MM-DD
  final CheckInStatus status;
  final String? note;
  final DateTime createdAt;
}

class AreaXp {
  const AreaXp({
    required this.lifeAreaId,
    this.xpTotal = 0,
    this.level = 1,
  });

  final String lifeAreaId;
  final int xpTotal;
  final int level;
}

class AppSettings {
  const AppSettings({
    this.missLimit = 2,
    this.day2NotificationsEnabled = true,
    this.reflectionsEnabled = true,
    this.maxAutoReflectionsPerDay = 3,
  });

  final int missLimit;
  final bool day2NotificationsEnabled;
  final bool reflectionsEnabled;
  final int maxAutoReflectionsPerDay;
}

/// A subject on the Today list with optional today's check-in and two-day state.
class TodaySubject {
  const TodaySubject({
    required this.id,
    required this.title,
    required this.subjectType,
    required this.lifeAreaId,
    required this.xp,
    required this.twoDay,
    this.habitKind,
    this.actionKind,
    this.goalId,
    this.todayStatus,
  });

  final String id;
  final String title;
  final SubjectType subjectType;
  final String lifeAreaId;
  final int xp;
  final TwoDayResult twoDay;
  final HabitKind? habitKind;
  final ActionKind? actionKind;
  final String? goalId;
  final CheckInStatus? todayStatus;

  bool get isDoneToday => todayStatus == CheckInStatus.done;
}

class TwoDayResult {
  const TwoDayResult({
    required this.missedDays,
    required this.state,
  });

  final int missedDays;
  final TwoDayState state;
}

class WheelSlice {
  const WheelSlice({
    required this.lifeArea,
    required this.score,
    required this.xp,
    required this.level,
    required this.consistency,
  });

  final LifeArea lifeArea;
  final double score; // 1–10
  final int xp;
  final int level;
  final double consistency;
}

class RecoveryItem {
  const RecoveryItem({
    required this.id,
    required this.title,
    required this.subjectType,
    required this.twoDay,
    required this.lifeAreaId,
  });

  final String id;
  final String title;
  final SubjectType subjectType;
  final TwoDayResult twoDay;
  final String lifeAreaId;
}

class ProgressPoint {
  const ProgressPoint({
    required this.localDate,
    required this.doneCount,
    required this.expectedCount,
  });

  final String localDate;
  final int doneCount;
  final int expectedCount;

  double get ratio =>
      expectedCount == 0 ? 0 : (doneCount / expectedCount).clamp(0.0, 1.0);
}
