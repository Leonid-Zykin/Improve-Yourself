import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/models.dart';
import '../../domain/reflection/prompts.dart';
import '../../domain/reflection/trigger_rules.dart';
import '../../domain/rules/consistency.dart';
import '../../domain/rules/two_day.dart';
import '../../domain/rules/wheel.dart';
import '../../domain/rules/xp.dart';
import '../db/database.dart'
    hide
        Profile,
        Vision,
        LifeArea,
        Goal,
        Action,
        Habit,
        CheckIn,
        Artifact,
        Reflection;
import '../templates/catalog.dart';

class AppRepository {
  AppRepository(this.db);

  final AppDatabase db;
  static const _uuid = Uuid();
  static const _twoDay = TwoDayRule();
  static const _xp = XpRules();
  static const _consistency = ConsistencyScore();
  static const _wheel = WheelRules();

  DateTime get _nowUtc => DateTime.now().toUtc();

  DateTime get todayLocal {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  String get todayKey => formatLocalDate(todayLocal);

  // ── Profile / onboarding ──────────────────────────────────────────

  Stream<Profile?> watchProfile() {
    return (db.select(db.profiles)
          ..where((t) => t.deletedAt.isNull())
          ..limit(1))
        .watchSingleOrNull()
        .map((row) => row == null
            ? null
            : Profile(
                id: row.id,
                displayName: row.displayName,
                timezone: row.timezone,
                createdAt: row.createdAt,
                onboardingCompleted: row.onboardingCompleted,
              ));
  }

  Future<Profile?> getProfile() async {
    final row = await (db.select(db.profiles)
          ..where((t) => t.deletedAt.isNull())
          ..limit(1))
        .getSingleOrNull();
    if (row == null) return null;
    return Profile(
      id: row.id,
      displayName: row.displayName,
      timezone: row.timezone,
      createdAt: row.createdAt,
      onboardingCompleted: row.onboardingCompleted,
    );
  }

  Future<void> completeOnboarding({
    required String displayName,
    required List<String> visionTitles,
    required Map<String, List<GoalSeed>> goalsByAreaKey,
    required List<ActionSeed> actions,
    required List<HabitSeed> habits,
  }) async {
    final now = _nowUtc;
    await db.transaction(() async {
      final profile = await (db.select(db.profiles)..limit(1)).getSingle();
      await (db.update(db.profiles)..where((t) => t.id.equals(profile.id)))
          .write(ProfilesCompanion(
        displayName: Value(displayName),
        onboardingCompleted: const Value(true),
        updatedAt: Value(now),
        syncStatus: const Value('pending'),
      ));

      String? firstVisionId;
      for (var i = 0; i < visionTitles.length; i++) {
        final title = visionTitles[i].trim();
        if (title.isEmpty) continue;
        final id = _uuid.v4();
        firstVisionId ??= id;
        await db.into(db.visions).insert(VisionsCompanion.insert(
              id: id,
              title: title,
              sortOrder: Value(i),
              updatedAt: now,
            ));
      }

      final areas = await (db.select(db.lifeAreas)
            ..where((t) => t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .get();
      final byKey = {for (final a in areas) a.key: a};

      for (final entry in goalsByAreaKey.entries) {
        final area = byKey[entry.key];
        if (area == null) continue;
        for (final g in entry.value) {
          if (g.title.trim().isEmpty) continue;
          await db.into(db.goals).insert(GoalsCompanion.insert(
                id: _uuid.v4(),
                lifeAreaId: area.id,
                visionId: Value(firstVisionId),
                title: g.title.trim(),
                targetValue: Value(g.targetValue),
                unit: Value(g.unit),
                updatedAt: now,
              ));
        }
      }

      for (final a in actions) {
        final area = byKey[a.areaKey];
        if (area == null || a.title.trim().isEmpty) continue;
        await db.into(db.actions).insert(ActionsCompanion.insert(
              id: _uuid.v4(),
              lifeAreaId: area.id,
              title: a.title.trim(),
              xpReward: Value(a.xp),
              kind: Value(a.kind.dbValue),
              schedule: Value(a.schedule.dbValue),
              updatedAt: now,
            ));
      }

      for (final h in habits) {
        if (h.title.trim().isEmpty) continue;
        final habitId = _uuid.v4();
        await db.into(db.habits).insert(HabitsCompanion.insert(
              id: habitId,
              kind: h.kind.dbValue,
              title: h.title.trim(),
              xpDelta: Value(h.xpDelta),
              updatedAt: now,
            ));
        for (final areaKey in h.areaKeys) {
          final area = byKey[areaKey];
          if (area == null) continue;
          await db.into(db.habitAreaEffects).insert(
                HabitAreaEffectsCompanion.insert(
                  habitId: habitId,
                  lifeAreaId: area.id,
                  weight: Value(h.kind == HabitKind.bad ? -1.0 : 1.0),
                  updatedAt: now,
                ),
              );
        }
      }
    });
  }

  // ── Life areas / visions / goals ──────────────────────────────────

  Stream<List<LifeArea>> watchLifeAreas() {
    return (db.select(db.lifeAreas)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .watch()
        .map((rows) => rows
            .map((r) => LifeArea(
                  id: r.id,
                  key: r.key,
                  title: r.title,
                  color: r.color,
                  icon: r.icon,
                  sortOrder: r.sortOrder,
                ))
            .toList());
  }

  Future<List<LifeArea>> getLifeAreas() async {
    final rows = await (db.select(db.lifeAreas)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
    return rows
        .map((r) => LifeArea(
              id: r.id,
              key: r.key,
              title: r.title,
              color: r.color,
              icon: r.icon,
              sortOrder: r.sortOrder,
            ))
        .toList();
  }

  Stream<List<Vision>> watchVisions() {
    return (db.select(db.visions)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .watch()
        .map((rows) => rows
            .map((r) => Vision(
                  id: r.id,
                  title: r.title,
                  targetDate: r.targetDate,
                  sortOrder: r.sortOrder,
                ))
            .toList());
  }

  Stream<List<Goal>> watchGoals() {
    return (db.select(db.goals)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.title)]))
        .watch()
        .map((rows) => rows
            .map((r) => Goal(
                  id: r.id,
                  lifeAreaId: r.lifeAreaId,
                  visionId: r.visionId,
                  title: r.title,
                  targetValue: r.targetValue,
                  unit: r.unit,
                  currentValue: r.currentValue,
                  deadline: r.deadline,
                  status: GoalStatusX.fromDb(r.status),
                ))
            .toList());
  }

  Future<void> addGoal({
    required String lifeAreaId,
    required String title,
    double? targetValue,
    String? unit,
  }) async {
    final now = _nowUtc;
    await db.into(db.goals).insert(GoalsCompanion.insert(
          id: _uuid.v4(),
          lifeAreaId: lifeAreaId,
          title: title,
          targetValue: Value(targetValue),
          unit: Value(unit),
          updatedAt: now,
        ));
  }

  Future<void> updateGoalProgress(String goalId, double currentValue) async {
    await (db.update(db.goals)..where((t) => t.id.equals(goalId))).write(
      GoalsCompanion(
        currentValue: Value(currentValue),
        updatedAt: Value(_nowUtc),
        syncStatus: const Value('pending'),
      ),
    );
  }

  Future<void> addAction({
    required String lifeAreaId,
    required String title,
    String? goalId,
    int xpReward = 10,
    ActionKind kind = ActionKind.other,
    ActionSchedule schedule = ActionSchedule.daily,
  }) async {
    await db.into(db.actions).insert(ActionsCompanion.insert(
          id: _uuid.v4(),
          lifeAreaId: lifeAreaId,
          goalId: Value(goalId),
          title: title,
          xpReward: Value(xpReward),
          kind: Value(kind.dbValue),
          schedule: Value(schedule.dbValue),
          updatedAt: _nowUtc,
        ));
  }

  Future<void> addHabit({
    required String title,
    required HabitKind kind,
    required List<String> lifeAreaIds,
    int xpDelta = 5,
  }) async {
    final now = _nowUtc;
    final id = _uuid.v4();
    await db.transaction(() async {
      await db.into(db.habits).insert(HabitsCompanion.insert(
            id: id,
            kind: kind.dbValue,
            title: title,
            xpDelta: Value(xpDelta),
            updatedAt: now,
          ));
      for (final areaId in lifeAreaIds) {
        await db.into(db.habitAreaEffects).insert(
              HabitAreaEffectsCompanion.insert(
                habitId: id,
                lifeAreaId: areaId,
                weight: Value(kind == HabitKind.bad ? -1.0 : 1.0),
                updatedAt: now,
              ),
            );
      }
    });
  }

  // ── Check-ins ─────────────────────────────────────────────────────

  /// One-tap check-in in a single transaction (check_in + area_xp).
  Future<void> checkIn({
    required SubjectType subjectType,
    required String subjectId,
    CheckInStatus status = CheckInStatus.done,
    String? note,
    String? localDate,
  }) async {
    final date = localDate ?? todayKey;
    final now = _nowUtc;

    await db.transaction(() async {
      final existing = await (db.select(db.checkIns)
            ..where((t) =>
                t.subjectType.equals(subjectType.dbValue) &
                t.subjectId.equals(subjectId) &
                t.localDate.equals(date) &
                t.deletedAt.isNull()))
          .getSingleOrNull();

      if (existing != null) {
        if (existing.status == status.dbValue) return;
        // Soft-replace: update status; reverse previous XP if needed.
        await _applyXpDelta(
          subjectType: subjectType,
          subjectId: subjectId,
          previousStatus: CheckInStatusX.fromDb(existing.status),
          newStatus: status,
        );
        await (db.update(db.checkIns)..where((t) => t.id.equals(existing.id)))
            .write(CheckInsCompanion(
          status: Value(status.dbValue),
          note: Value(note),
          updatedAt: Value(now),
          syncStatus: const Value('pending'),
        ));
        return;
      }

      await db.into(db.checkIns).insert(CheckInsCompanion.insert(
            id: _uuid.v4(),
            subjectType: subjectType.dbValue,
            subjectId: subjectId,
            localDate: date,
            status: status.dbValue,
            note: Value(note),
            createdAt: now,
            updatedAt: now,
          ));

      await _applyXpDelta(
        subjectType: subjectType,
        subjectId: subjectId,
        previousStatus: null,
        newStatus: status,
      );
    });
  }

  Future<void> _applyXpDelta({
    required SubjectType subjectType,
    required String subjectId,
    required CheckInStatus? previousStatus,
    required CheckInStatus newStatus,
  }) async {
    final now = _nowUtc;
    int delta = 0;
    List<String> areaIds = [];

    if (subjectType == SubjectType.action) {
      final action = await (db.select(db.actions)
            ..where((t) => t.id.equals(subjectId)))
          .getSingleOrNull();
      if (action == null) return;
      areaIds = [action.lifeAreaId];
      final reward = action.xpReward;
      if (previousStatus == CheckInStatus.done) delta -= reward;
      if (newStatus == CheckInStatus.done) delta += reward;
    } else {
      final habit = await (db.select(db.habits)
            ..where((t) => t.id.equals(subjectId)))
          .getSingleOrNull();
      if (habit == null) return;
      final effects = await (db.select(db.habitAreaEffects)
            ..where((t) =>
                t.habitId.equals(subjectId) & t.deletedAt.isNull()))
          .get();
      areaIds = effects.map((e) => e.lifeAreaId).toList();
      if (areaIds.isEmpty) return;

      final kind = HabitKindX.fromDb(habit.kind);
      int reward;
      if (kind == HabitKind.good) {
        reward = habit.xpDelta;
      } else {
        // Bad habit marked done = slip → negative XP
        reward = -habit.xpDelta.abs();
      }
      if (previousStatus == CheckInStatus.done) delta -= reward;
      if (newStatus == CheckInStatus.done) delta += reward;
    }

    if (delta == 0) return;

    for (final areaId in areaIds) {
      final row = await (db.select(db.areaXpTable)
            ..where((t) => t.lifeAreaId.equals(areaId)))
          .getSingleOrNull();
      final current = row?.xpTotal ?? 0;
      final next = _xp.applyDelta(current, delta);
      final level = _xp.levelForXp(next);
      if (row == null) {
        await db.into(db.areaXpTable).insert(AreaXpTableCompanion.insert(
              lifeAreaId: areaId,
              xpTotal: Value(next),
              level: Value(level),
              updatedAt: now,
            ));
      } else {
        await (db.update(db.areaXpTable)
              ..where((t) => t.lifeAreaId.equals(areaId)))
            .write(AreaXpTableCompanion(
          xpTotal: Value(next),
          level: Value(level),
          updatedAt: Value(now),
          syncStatus: const Value('pending'),
        ));
      }
    }
  }

  Future<Set<String>> _doneDatesFor(
    SubjectType type,
    String subjectId, {
    int lookbackDays = 60,
  }) async {
    final from = todayLocal.subtract(Duration(days: lookbackDays));
    final fromKey = formatLocalDate(from);
    final rows = await (db.select(db.checkIns)
          ..where((t) =>
              t.subjectType.equals(type.dbValue) &
              t.subjectId.equals(subjectId) &
              t.status.equals(CheckInStatus.done.dbValue) &
              t.localDate.isBiggerOrEqualValue(fromKey) &
              t.deletedAt.isNull()))
        .get();
    return rows.map((r) => r.localDate).toSet();
  }

  // ── Today plan ────────────────────────────────────────────────────

  Stream<List<TodaySubject>> watchTodayPlan() {
    // Recompute when any relevant table changes.
    return db.select(db.checkIns).watch().asyncMap((_) => getTodayPlan());
  }

  Future<List<TodaySubject>> getTodayPlan() async {
    final actions = await (db.select(db.actions)
          ..where((t) => t.active.equals(true) & t.deletedAt.isNull()))
        .get();
    final habits = await (db.select(db.habits)
          ..where((t) => t.active.equals(true) & t.deletedAt.isNull()))
        .get();

    final todayChecks = await (db.select(db.checkIns)
          ..where((t) =>
              t.localDate.equals(todayKey) & t.deletedAt.isNull()))
        .get();
    final bySubject = {
      for (final c in todayChecks) '${c.subjectType}:${c.subjectId}': c,
    };

    final result = <TodaySubject>[];

    for (final a in actions) {
      final done = await _doneDatesFor(SubjectType.action, a.id);
      final two = _twoDay.evaluate(doneDates: done, today: todayLocal);
      final key = '${SubjectType.action.dbValue}:${a.id}';
      final check = bySubject[key];
      result.add(TodaySubject(
        id: a.id,
        title: a.title,
        subjectType: SubjectType.action,
        lifeAreaId: a.lifeAreaId,
        xp: a.xpReward,
        twoDay: two,
        actionKind: ActionKindX.fromDb(a.kind),
        goalId: a.goalId,
        todayStatus:
            check == null ? null : CheckInStatusX.fromDb(check.status),
      ));
    }

    for (final h in habits) {
      final done = await _doneDatesFor(SubjectType.habit, h.id);
      final two = _twoDay.evaluate(doneDates: done, today: todayLocal);
      final effects = await (db.select(db.habitAreaEffects)
            ..where(
                (t) => t.habitId.equals(h.id) & t.deletedAt.isNull()))
          .get();
      final areaId = effects.isNotEmpty ? effects.first.lifeAreaId : '';
      final key = '${SubjectType.habit.dbValue}:${h.id}';
      final check = bySubject[key];
      result.add(TodaySubject(
        id: h.id,
        title: h.title,
        subjectType: SubjectType.habit,
        lifeAreaId: areaId,
        xp: h.xpDelta,
        twoDay: two,
        habitKind: HabitKindX.fromDb(h.kind),
        todayStatus:
            check == null ? null : CheckInStatusX.fromDb(check.status),
      ));
    }

    return result;
  }

  // ── Recovery ──────────────────────────────────────────────────────

  Stream<List<RecoveryItem>> watchRecovery() {
    return db.select(db.checkIns).watch().asyncMap((_) => getRecovery());
  }

  Future<List<RecoveryItem>> getRecovery() async {
    final plan = await getTodayPlan();
    return plan
        .where((s) =>
            s.twoDay.state == TwoDayState.warning ||
            s.twoDay.state == TwoDayState.broken)
        .map((s) => RecoveryItem(
              id: s.id,
              title: s.title,
              subjectType: s.subjectType,
              twoDay: s.twoDay,
              lifeAreaId: s.lifeAreaId,
            ))
        .toList();
  }

  Stream<int> watchRecoveryBadgeCount() {
    return watchRecovery().map((items) => items.length);
  }

  // ── Wheel / XP ────────────────────────────────────────────────────

  Stream<List<AreaXp>> watchAreaXp() {
    return db.select(db.areaXpTable).watch().map((rows) => rows
        .map((r) => AreaXp(
              lifeAreaId: r.lifeAreaId,
              xpTotal: r.xpTotal,
              level: r.level,
            ))
        .toList());
  }

  Future<List<WheelSlice>> computeWheel({int windowDays = 30}) async {
    final areas = await getLifeAreas();
    final goals = await (db.select(db.goals)
          ..where((t) =>
              t.deletedAt.isNull() & t.status.equals(GoalStatus.active.dbValue)))
        .get();
    final xpRows = await db.select(db.areaXpTable).get();
    final xpByArea = {for (final x in xpRows) x.lifeAreaId: x};

    final from = todayLocal.subtract(Duration(days: windowDays - 1));
    final fromKey = formatLocalDate(from);

    final actions = await (db.select(db.actions)
          ..where((t) => t.active.equals(true) & t.deletedAt.isNull()))
        .get();
    final habits = await (db.select(db.habits)
          ..where((t) => t.active.equals(true) & t.deletedAt.isNull()))
        .get();
    final effects = await (db.select(db.habitAreaEffects)
          ..where((t) => t.deletedAt.isNull()))
        .get();

    final slices = <WheelSlice>[];

    for (final area in areas) {
      final areaActions =
          actions.where((a) => a.lifeAreaId == area.id).toList();
      final areaHabitIds = effects
          .where((e) => e.lifeAreaId == area.id)
          .map((e) => e.habitId)
          .toSet();
      final areaHabits =
          habits.where((h) => areaHabitIds.contains(h.id)).toList();

      final scores = <double>[];
      for (final a in areaActions) {
        final checks = await (db.select(db.checkIns)
              ..where((t) =>
                  t.subjectType.equals(SubjectType.action.dbValue) &
                  t.subjectId.equals(a.id) &
                  t.status.equals(CheckInStatus.done.dbValue) &
                  t.localDate.isBiggerOrEqualValue(fromKey) &
                  t.deletedAt.isNull()))
            .get();
        scores.add(_consistency.subjectScore(
          doneDays: checks.length,
          expectedDays: windowDays,
        ));
      }
      for (final h in areaHabits.where((h) => h.kind == HabitKind.good.dbValue)) {
        final checks = await (db.select(db.checkIns)
              ..where((t) =>
                  t.subjectType.equals(SubjectType.habit.dbValue) &
                  t.subjectId.equals(h.id) &
                  t.status.equals(CheckInStatus.done.dbValue) &
                  t.localDate.isBiggerOrEqualValue(fromKey) &
                  t.deletedAt.isNull()))
            .get();
        scores.add(_consistency.subjectScore(
          doneDays: checks.length,
          expectedDays: windowDays,
        ));
      }

      final cons = _consistency.overall(scores);

      final areaGoals = goals.where((g) => g.lifeAreaId == area.id);
      final goalProgress = _wheel.averageGoalProgress(areaGoals.map((g) {
        final target = g.targetValue;
        if (target == null || target <= 0) return 0.0;
        return (g.currentValue / target).clamp(0.0, 1.0);
      }));

      var badPenalty = 0.0;
      for (final h
          in areaHabits.where((h) => h.kind == HabitKind.bad.dbValue)) {
        final slips = await (db.select(db.checkIns)
              ..where((t) =>
                  t.subjectType.equals(SubjectType.habit.dbValue) &
                  t.subjectId.equals(h.id) &
                  t.status.equals(CheckInStatus.done.dbValue) &
                  t.localDate.isBiggerOrEqualValue(fromKey) &
                  t.deletedAt.isNull()))
            .get();
        badPenalty += (slips.length / windowDays).clamp(0.0, 1.0);
      }
      badPenalty = _wheel.softenPenalty(badPenalty);

      final xp = xpByArea[area.id];
      slices.add(WheelSlice(
        lifeArea: area,
        score: _wheel.score(
          consistency: cons,
          goalProgress: goalProgress,
          badHabitPenalty: badPenalty,
        ),
        xp: xp?.xpTotal ?? 0,
        level: xp?.level ?? 1,
        consistency: cons,
      ));
    }

    return slices;
  }

  Future<double> overallConsistency({int windowDays = 30}) async {
    final plan = await getTodayPlan();
    if (plan.isEmpty) return 0;
    final from = todayLocal.subtract(Duration(days: windowDays - 1));
    final fromKey = formatLocalDate(from);
    final scores = <double>[];
    for (final s in plan) {
      if (s.habitKind == HabitKind.bad) continue;
      final checks = await (db.select(db.checkIns)
            ..where((t) =>
                t.subjectType.equals(s.subjectType.dbValue) &
                t.subjectId.equals(s.id) &
                t.status.equals(CheckInStatus.done.dbValue) &
                t.localDate.isBiggerOrEqualValue(fromKey) &
                t.deletedAt.isNull()))
          .get();
      scores.add(_consistency.subjectScore(
        doneDays: checks.length,
        expectedDays: windowDays,
      ));
    }
    return _consistency.overall(scores);
  }

  Future<List<ProgressPoint>> progressSeries({int windowDays = 30}) async {
    final plan = await getTodayPlan();
    final expected = plan.where((s) => s.habitKind != HabitKind.bad).length;
    final points = <ProgressPoint>[];
    for (var i = windowDays - 1; i >= 0; i--) {
      final day = todayLocal.subtract(Duration(days: i));
      final key = formatLocalDate(day);
      final rows = await (db.select(db.checkIns)
            ..where((t) =>
                t.localDate.equals(key) &
                t.status.equals(CheckInStatus.done.dbValue) &
                t.deletedAt.isNull()))
          .get();
      // Count only non-bad subjects roughly: count all done that match plan ids of non-bad
      final goodIds = {
        for (final s in plan.where((s) => s.habitKind != HabitKind.bad))
          '${s.subjectType.dbValue}:${s.id}'
      };
      final done = rows
          .where((r) => goodIds.contains('${r.subjectType}:${r.subjectId}'))
          .length;
      points.add(ProgressPoint(
        localDate: key,
        doneCount: done,
        expectedCount: expected == 0 ? 1 : expected,
      ));
    }
    return points;
  }

  // ── Settings / reflections / artifacts / templates ─────────────────

  Future<AppSettings> getSettings() async {
    final row = await (db.select(db.settings)..limit(1)).getSingleOrNull();
    if (row == null) return const AppSettings();
    return AppSettings(
      missLimit: row.missLimit,
      day2NotificationsEnabled: row.day2NotificationsEnabled,
      reflectionsEnabled: row.reflectionsEnabled,
      maxAutoReflectionsPerDay: row.maxAutoReflectionsPerDay,
    );
  }

  Future<List<Vision>> getVisions() async {
    final rows = await (db.select(db.visions)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
    return rows
        .map((r) => Vision(
              id: r.id,
              title: r.title,
              targetDate: r.targetDate,
              sortOrder: r.sortOrder,
            ))
        .toList();
  }

  Future<List<Goal>> getGoals() async {
    final rows = await (db.select(db.goals)
          ..where((t) => t.deletedAt.isNull()))
        .get();
    return rows
        .map((r) => Goal(
              id: r.id,
              lifeAreaId: r.lifeAreaId,
              visionId: r.visionId,
              title: r.title,
              targetValue: r.targetValue,
              unit: r.unit,
              currentValue: r.currentValue,
              deadline: r.deadline,
              status: GoalStatusX.fromDb(r.status),
            ))
        .toList();
  }

  Future<int> countAutoReflectionsToday() async {
    final rows = await (db.select(db.reflections)
          ..where((t) =>
              t.localDate.equals(todayKey) &
              t.deletedAt.isNull() &
              t.trigger.isIn([
                ReflectionTrigger.actionKind.dbValue,
                ReflectionTrigger.badHabitSlip.dbValue,
              ])))
        .get();
    return rows.length;
  }

  /// Whether UI should show soft reflection sheet after this check-in.
  Future<bool> shouldOfferReflection({
    required SubjectType subjectType,
    required String subjectId,
    required CheckInStatus status,
  }) async {
    final settings = await getSettings();
    final todayCount = await countAutoReflectionsToday();
    ActionKind? actionKind;
    HabitKind? habitKind;
    if (subjectType == SubjectType.action) {
      final a = await (db.select(db.actions)
            ..where((t) => t.id.equals(subjectId)))
          .getSingleOrNull();
      if (a != null) actionKind = ActionKindX.fromDb(a.kind);
    } else {
      final h = await (db.select(db.habits)
            ..where((t) => t.id.equals(subjectId)))
          .getSingleOrNull();
      if (h != null) habitKind = HabitKindX.fromDb(h.kind);
    }
    return ReflectionTriggerRules(
      maxAutoPerDay: settings.maxAutoReflectionsPerDay,
    ).shouldOffer(
      reflectionsEnabled: settings.reflectionsEnabled,
      autoReflectionsToday: todayCount,
      subjectType: subjectType,
      actionKind: actionKind,
      habitKind: habitKind,
      status: status,
    );
  }

  Future<ReflectionPrompt?> reflectionPromptFor({
    required SubjectType subjectType,
    required String subjectId,
  }) async {
    if (subjectType == SubjectType.action) {
      final a = await (db.select(db.actions)
            ..where((t) => t.id.equals(subjectId)))
          .getSingleOrNull();
      if (a == null) return null;
      final kind = ActionKindX.fromDb(a.kind);
      if (!kind.triggersReflection) return null;
      return ReflectionPrompts.forActionKind(kind);
    }
    final h = await (db.select(db.habits)
          ..where((t) => t.id.equals(subjectId)))
        .getSingleOrNull();
    if (h == null) return null;
    if (HabitKindX.fromDb(h.kind) != HabitKind.bad) return null;
    return ReflectionPrompts.forBadHabitSlip();
  }

  Future<void> saveReflection({
    required String promptKey,
    required String promptText,
    required ReflectionTrigger trigger,
    String? answer,
    bool skipped = false,
    SubjectType? subjectType,
    String? subjectId,
    ActionKind? actionKind,
    String? checkInId,
  }) async {
    final now = _nowUtc;
    await db.into(db.reflections).insert(ReflectionsCompanion.insert(
          id: _uuid.v4(),
          promptKey: promptKey,
          promptText: promptText,
          answer: Value(answer),
          trigger: trigger.dbValue,
          subjectType: Value(subjectType?.dbValue),
          subjectId: Value(subjectId),
          actionKind: Value(actionKind?.dbValue),
          checkInId: Value(checkInId),
          skipped: Value(skipped),
          localDate: todayKey,
          createdAt: now,
          updatedAt: now,
        ));
  }

  Stream<List<Artifact>> watchArtifacts({String? goalId}) {
    final q = db.select(db.artifacts)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    if (goalId != null) {
      q.where((t) => t.goalId.equals(goalId));
    }
    return q.watch().map(
          (rows) => [
            for (final r in rows)
              Artifact(
                id: r.id,
                type: ArtifactTypeX.fromDb(r.type),
                title: r.title,
                body: r.body,
                metricValue: r.metricValue,
                metricUnit: r.metricUnit,
                localPath: r.localPath,
                thumbnailPath: r.thumbnailPath,
                goalId: r.goalId,
                lifeAreaId: r.lifeAreaId,
                actionId: r.actionId,
                checkInId: r.checkInId,
                localDate: r.localDate,
                createdAt: r.createdAt,
              ),
          ],
        );
  }

  Future<List<Artifact>> getArtifacts({
    String? goalId,
    int limit = 50,
  }) async {
    final q = db.select(db.artifacts)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(limit);
    if (goalId != null) {
      q.where((t) => t.goalId.equals(goalId));
    }
    final rows = await q.get();
    return [
      for (final r in rows)
        Artifact(
          id: r.id,
          type: ArtifactTypeX.fromDb(r.type),
          title: r.title,
          body: r.body,
          metricValue: r.metricValue,
          metricUnit: r.metricUnit,
          localPath: r.localPath,
          thumbnailPath: r.thumbnailPath,
          goalId: r.goalId,
          lifeAreaId: r.lifeAreaId,
          actionId: r.actionId,
          checkInId: r.checkInId,
          localDate: r.localDate,
          createdAt: r.createdAt,
        ),
    ];
  }

  Future<List<Reflection>> getReflections({
    int limit = 50,
    String? sinceLocalDate,
  }) async {
    final q = db.select(db.reflections)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(limit);
    if (sinceLocalDate != null) {
      q.where((t) => t.localDate.isBiggerOrEqualValue(sinceLocalDate));
    }
    final rows = await q.get();
    return rows
        .map((r) => Reflection(
              id: r.id,
              promptKey: r.promptKey,
              promptText: r.promptText,
              answer: r.answer,
              trigger: ReflectionTriggerX.fromDb(r.trigger),
              subjectType: r.subjectType == null
                  ? null
                  : SubjectTypeX.fromDb(r.subjectType!),
              subjectId: r.subjectId,
              actionKind: r.actionKind == null
                  ? null
                  : ActionKindX.fromDb(r.actionKind!),
              checkInId: r.checkInId,
              skipped: r.skipped,
              localDate: r.localDate,
              createdAt: r.createdAt,
            ))
        .toList();
  }

  Future<Artifact> addArtifact({
    required ArtifactType type,
    String? title,
    String? body,
    double? metricValue,
    String? metricUnit,
    String? localPath,
    String? thumbnailPath,
    String? goalId,
    String? lifeAreaId,
    String? actionId,
    String? checkInId,
  }) async {
    final now = _nowUtc;
    final id = _uuid.v4();
    await db.into(db.artifacts).insert(ArtifactsCompanion.insert(
          id: id,
          type: type.dbValue,
          title: Value(title),
          body: Value(body),
          metricValue: Value(metricValue),
          metricUnit: Value(metricUnit),
          localPath: Value(localPath),
          thumbnailPath: Value(thumbnailPath),
          goalId: Value(goalId),
          lifeAreaId: Value(lifeAreaId),
          actionId: Value(actionId),
          checkInId: Value(checkInId),
          localDate: todayKey,
          createdAt: now,
          updatedAt: now,
        ));
    return Artifact(
      id: id,
      type: type,
      title: title,
      body: body,
      metricValue: metricValue,
      metricUnit: metricUnit,
      localPath: localPath,
      thumbnailPath: thumbnailPath,
      goalId: goalId,
      lifeAreaId: lifeAreaId,
      actionId: actionId,
      checkInId: checkInId,
      localDate: todayKey,
      createdAt: now,
    );
  }

  Future<int> countDoneCheckIns({required String sinceLocalDate}) async {
    final rows = await (db.select(db.checkIns)
          ..where((t) =>
              t.status.equals(CheckInStatus.done.dbValue) &
              t.localDate.isBiggerOrEqualValue(sinceLocalDate) &
              t.deletedAt.isNull()))
        .get();
    return rows.length;
  }

  Future<int> countBadHabitSlips({required String sinceLocalDate}) async {
    final badHabits = await (db.select(db.habits)
          ..where((t) =>
              t.kind.equals(HabitKind.bad.dbValue) & t.deletedAt.isNull()))
        .get();
    if (badHabits.isEmpty) return 0;
    final ids = badHabits.map((h) => h.id).toSet();
    final rows = await (db.select(db.checkIns)
          ..where((t) =>
              t.subjectType.equals(SubjectType.habit.dbValue) &
              t.status.equals(CheckInStatus.done.dbValue) &
              t.localDate.isBiggerOrEqualValue(sinceLocalDate) &
              t.deletedAt.isNull()))
        .get();
    return rows.where((r) => ids.contains(r.subjectId)).length;
  }

  /// Creates goal + actions + habits from a catalog template.
  Future<void> applyTemplate(String templateId) async {
    final template = TemplateCatalog.byId(templateId);
    if (template == null) return;
    final now = _nowUtc;
    final areas = await getLifeAreas();
    final byKey = {for (final a in areas) a.key: a};
    final area = byKey[template.lifeArea];
    if (area == null) return;

    await db.transaction(() async {
      final goalId = _uuid.v4();
      DateTime? deadline;
      if (template.deadlineWeeks != null) {
        deadline = todayLocal.add(Duration(days: template.deadlineWeeks! * 7));
      }
      await db.into(db.goals).insert(GoalsCompanion.insert(
            id: goalId,
            lifeAreaId: area.id,
            title: template.title,
            targetValue: Value(template.targetValue),
            unit: Value(template.unit),
            deadline: Value(deadline),
            updatedAt: now,
          ));

      for (final a in template.actions) {
        await db.into(db.actions).insert(ActionsCompanion.insert(
              id: _uuid.v4(),
              goalId: Value(goalId),
              lifeAreaId: area.id,
              title: a.title,
              kind: Value(a.kind.dbValue),
              schedule: Value(a.schedule.dbValue),
              xpReward: Value(a.xp),
              updatedAt: now,
            ));
      }

      for (final h in template.habits) {
        final habitId = _uuid.v4();
        await db.into(db.habits).insert(HabitsCompanion.insert(
              id: habitId,
              kind: h.kind.dbValue,
              title: h.title,
              xpDelta: Value(h.xpDelta),
              updatedAt: now,
            ));
        for (final areaKey in h.areaKeys) {
          final effectArea = byKey[areaKey];
          if (effectArea == null) continue;
          await db.into(db.habitAreaEffects).insert(
                HabitAreaEffectsCompanion.insert(
                  habitId: habitId,
                  lifeAreaId: effectArea.id,
                  weight: Value(h.kind == HabitKind.bad ? -1.0 : 1.0),
                  updatedAt: now,
                ),
              );
        }
      }
    });
  }

  Future<void> applyOnboardingPreset(String presetId) async {
    final preset = TemplateCatalog.presetById(presetId);
    if (preset == null) return;
    for (final id in preset.templateIds) {
      await applyTemplate(id);
    }
  }

  // ── Backup ────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> exportBackupJson() async {
    Future<List<Map<String, Object?>>> dump(String tableName) async {
      final rows =
          await db.customSelect('SELECT * FROM $tableName').get();
      return rows.map((r) {
        final map = <String, Object?>{};
        for (final e in r.data.entries) {
          final v = e.value;
          map[e.key] = v is DateTime ? v.toIso8601String() : v;
        }
        return map;
      }).toList();
    }

    return {
      'version': 2,
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'profiles': await dump('profiles'),
      'visions': await dump('visions'),
      'life_areas': await dump('life_areas'),
      'goals': await dump('goals'),
      'actions': await dump('actions'),
      'habits': await dump('habits'),
      'habit_area_effects': await dump('habit_area_effects'),
      'check_ins': await dump('check_ins'),
      'area_xp': await dump('area_xp'),
      'settings': await dump('settings'),
      'artifacts': await dump('artifacts'),
      'reflections': await dump('reflections'),
    };
  }
}

class GoalSeed {
  const GoalSeed({required this.title, this.targetValue, this.unit});
  final String title;
  final double? targetValue;
  final String? unit;
}

class ActionSeed {
  const ActionSeed({
    required this.title,
    required this.areaKey,
    this.xp = 10,
    this.kind = ActionKind.other,
    this.schedule = ActionSchedule.daily,
  });
  final String title;
  final String areaKey;
  final int xp;
  final ActionKind kind;
  final ActionSchedule schedule;
}

class HabitSeed {
  const HabitSeed({
    required this.title,
    required this.kind,
    required this.areaKeys,
    this.xpDelta = 5,
  });
  final String title;
  final HabitKind kind;
  final List<String> areaKeys;
  final int xpDelta;
}
