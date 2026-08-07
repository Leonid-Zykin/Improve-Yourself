import 'package:drift/drift.dart';

/// Sync-ready mixin columns for all tables.
mixin SyncColumns on Table {
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();
  TextColumn get syncStatus =>
      text().named('sync_status').withDefault(const Constant('pending'))();
}

class Profiles extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get displayName => text().named('display_name')();
  TextColumn get timezone => text().withDefault(const Constant('UTC'))();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  BoolColumn get onboardingCompleted =>
      boolean().named('onboarding_completed').withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class Visions extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get title => text()();
  DateTimeColumn get targetDate => dateTime().named('target_date').nullable()();
  IntColumn get sortOrder =>
      integer().named('sort_order').withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class LifeAreas extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get key => text()();
  TextColumn get title => text()();
  IntColumn get color => integer()();
  TextColumn get icon => text()();
  IntColumn get sortOrder =>
      integer().named('sort_order').withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class Goals extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get lifeAreaId => text().named('life_area_id')();
  TextColumn get visionId => text().named('vision_id').nullable()();
  TextColumn get title => text()();
  RealColumn get targetValue => real().named('target_value').nullable()();
  TextColumn get unit => text().nullable()();
  RealColumn get currentValue =>
      real().named('current_value').withDefault(const Constant(0.0))();
  DateTimeColumn get deadline => dateTime().nullable()();
  TextColumn get status => text().withDefault(const Constant('active'))();

  @override
  Set<Column> get primaryKey => {id};
}

class Actions extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get goalId => text().named('goal_id').nullable()();
  TextColumn get lifeAreaId => text().named('life_area_id')();
  TextColumn get title => text()();
  TextColumn get schedule => text().withDefault(const Constant('daily'))();
  TextColumn get kind => text().withDefault(const Constant('other'))();
  IntColumn get xpReward =>
      integer().named('xp_reward').withDefault(const Constant(10))();
  BoolColumn get active => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

class Habits extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get kind => text()(); // good | bad
  TextColumn get title => text()();
  IntColumn get xpDelta =>
      integer().named('xp_delta').withDefault(const Constant(5))();
  BoolColumn get active => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

class HabitAreaEffects extends Table with SyncColumns {
  TextColumn get habitId => text().named('habit_id')();
  TextColumn get lifeAreaId => text().named('life_area_id')();
  RealColumn get weight => real().withDefault(const Constant(1.0))();

  @override
  Set<Column> get primaryKey => {habitId, lifeAreaId};
}

class CheckIns extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get subjectType => text().named('subject_type')();
  TextColumn get subjectId => text().named('subject_id')();
  TextColumn get localDate => text().named('local_date')();
  TextColumn get status => text()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {subjectType, subjectId, localDate},
      ];
}

class AreaXpTable extends Table with SyncColumns {
  @override
  String get tableName => 'area_xp';

  TextColumn get lifeAreaId => text().named('life_area_id')();
  IntColumn get xpTotal =>
      integer().named('xp_total').withDefault(const Constant(0))();
  IntColumn get level => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {lifeAreaId};
}

class Settings extends Table with SyncColumns {
  TextColumn get id => text()(); // singleton row id e.g. 'default'
  IntColumn get missLimit =>
      integer().named('miss_limit').withDefault(const Constant(2))();
  BoolColumn get day2NotificationsEnabled => boolean()
      .named('day2_notifications_enabled')
      .withDefault(const Constant(true))();
  BoolColumn get reflectionsEnabled => boolean()
      .named('reflections_enabled')
      .withDefault(const Constant(true))();
  IntColumn get maxAutoReflectionsPerDay => integer()
      .named('max_auto_reflections_per_day')
      .withDefault(const Constant(3))();

  @override
  Set<Column> get primaryKey => {id};
}

class Artifacts extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get type => text()();
  TextColumn get title => text().nullable()();
  TextColumn get body => text().nullable()();
  RealColumn get metricValue => real().named('metric_value').nullable()();
  TextColumn get metricUnit => text().named('metric_unit').nullable()();
  TextColumn get localPath => text().named('local_path').nullable()();
  TextColumn get thumbnailPath => text().named('thumbnail_path').nullable()();
  TextColumn get goalId => text().named('goal_id').nullable()();
  TextColumn get lifeAreaId => text().named('life_area_id').nullable()();
  TextColumn get actionId => text().named('action_id').nullable()();
  TextColumn get checkInId => text().named('check_in_id').nullable()();
  TextColumn get localDate => text().named('local_date')();
  DateTimeColumn get createdAt => dateTime().named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}

class Reflections extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get promptKey => text().named('prompt_key')();
  TextColumn get promptText => text().named('prompt_text')();
  TextColumn get answer => text().nullable()();
  TextColumn get trigger => text()();
  TextColumn get subjectType => text().named('subject_type').nullable()();
  TextColumn get subjectId => text().named('subject_id').nullable()();
  TextColumn get actionKind => text().named('action_kind').nullable()();
  TextColumn get checkInId => text().named('check_in_id').nullable()();
  BoolColumn get skipped =>
      boolean().withDefault(const Constant(false))();
  TextColumn get localDate => text().named('local_date')();
  DateTimeColumn get createdAt => dateTime().named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}
