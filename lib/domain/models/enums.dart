/// Shared domain enums for Improve Yourself.
library;

enum SubjectType { action, habit }

enum CheckInStatus { done, skipped, failed }

enum HabitKind { good, bad }

enum ActionSchedule { daily, weekly, custom }

/// Reflective kinds trigger soft reflection after check-in (`other` does not).
enum ActionKind { workout, reading, career, study, language, other }

enum ArtifactType { photo, metric, dailyLog, chapterNote, genericNote }

enum ReflectionTrigger { actionKind, badHabitSlip, manual }

enum CoachMode { goalDecompose, failureCoach, monthlyReview, yearlyReview }

enum GoalStatus { active, completed, paused, cancelled }

enum SyncStatus { pending, synced, conflict }

enum TwoDayState {
  /// 0–1 missed days in a row — healthy streak.
  ok,

  /// Exactly 2 missed days — one day left before soft break.
  warning,

  /// 3+ missed days — soft break; surfaced on Calendar.
  broken,
}

extension SubjectTypeX on SubjectType {
  String get dbValue => name;

  static SubjectType fromDb(String value) =>
      SubjectType.values.firstWhere((e) => e.name == value);
}

extension CheckInStatusX on CheckInStatus {
  String get dbValue => name;

  static CheckInStatus fromDb(String value) =>
      CheckInStatus.values.firstWhere((e) => e.name == value);
}

extension HabitKindX on HabitKind {
  String get dbValue => name;

  static HabitKind fromDb(String value) =>
      HabitKind.values.firstWhere((e) => e.name == value);
}

extension ActionScheduleX on ActionSchedule {
  String get dbValue => name;

  static ActionSchedule fromDb(String value) =>
      ActionSchedule.values.firstWhere((e) => e.name == value);
}

extension ActionKindX on ActionKind {
  String get dbValue => name;

  bool get triggersReflection => this != ActionKind.other;

  static ActionKind fromDb(String value) => ActionKind.values.firstWhere(
        (e) => e.name == value,
        orElse: () => ActionKind.other,
      );
}

extension ArtifactTypeX on ArtifactType {
  /// Snake_case for DB / JSON stability.
  String get dbValue => switch (this) {
        ArtifactType.photo => 'photo',
        ArtifactType.metric => 'metric',
        ArtifactType.dailyLog => 'daily_log',
        ArtifactType.chapterNote => 'chapter_note',
        ArtifactType.genericNote => 'generic_note',
      };

  static ArtifactType fromDb(String value) => switch (value) {
        'photo' => ArtifactType.photo,
        'metric' => ArtifactType.metric,
        'daily_log' => ArtifactType.dailyLog,
        'chapter_note' => ArtifactType.chapterNote,
        'generic_note' => ArtifactType.genericNote,
        _ => ArtifactType.genericNote,
      };
}

extension ReflectionTriggerX on ReflectionTrigger {
  String get dbValue => switch (this) {
        ReflectionTrigger.actionKind => 'action_kind',
        ReflectionTrigger.badHabitSlip => 'bad_habit_slip',
        ReflectionTrigger.manual => 'manual',
      };

  static ReflectionTrigger fromDb(String value) => switch (value) {
        'action_kind' => ReflectionTrigger.actionKind,
        'bad_habit_slip' => ReflectionTrigger.badHabitSlip,
        'manual' => ReflectionTrigger.manual,
        _ => ReflectionTrigger.manual,
      };
}

extension CoachModeX on CoachMode {
  String get apiValue => switch (this) {
        CoachMode.goalDecompose => 'goal_decompose',
        CoachMode.failureCoach => 'failure_coach',
        CoachMode.monthlyReview => 'monthly_review',
        CoachMode.yearlyReview => 'yearly_review',
      };

  static CoachMode fromApi(String value) => switch (value) {
        'goal_decompose' => CoachMode.goalDecompose,
        'failure_coach' => CoachMode.failureCoach,
        'monthly_review' => CoachMode.monthlyReview,
        'yearly_review' => CoachMode.yearlyReview,
        _ => CoachMode.failureCoach,
      };
}

extension GoalStatusX on GoalStatus {
  String get dbValue => name;

  static GoalStatus fromDb(String value) =>
      GoalStatus.values.firstWhere((e) => e.name == value);
}

extension SyncStatusX on SyncStatus {
  String get dbValue => name;

  static SyncStatus fromDb(String value) =>
      SyncStatus.values.firstWhere(
        (e) => e.name == value,
        orElse: () => SyncStatus.pending,
      );
}
