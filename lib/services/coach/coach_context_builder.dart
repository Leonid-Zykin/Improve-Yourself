import '../../data/repositories/app_repository.dart';
import '../../domain/models/enums.dart';
import '../../domain/rules/two_day.dart';
import 'coach_provider.dart';

/// Builds CoachContext JSON from local DB (no network).
class CoachContextBuilder {
  CoachContextBuilder(this.repo);

  final AppRepository repo;

  Future<CoachContext> build({
    required CoachMode mode,
    int? windowDays,
  }) async {
    final days = windowDays ??
        switch (mode) {
          CoachMode.yearlyReview => 365,
          _ => 30,
        };

    final today = repo.todayLocal;
    final from = today.subtract(Duration(days: days - 1));
    final fromKey = formatLocalDate(from);
    final toKey = formatLocalDate(today);

    final profile = await repo.getProfile();
    final visions = await repo.getVisions();
    final areas = await repo.getLifeAreas();
    final areaById = {for (final a in areas) a.id: a};
    final goals = await repo.getGoals();
    final recovery = await repo.getRecovery();
    final consistency = await repo.overallConsistency(windowDays: days.clamp(1, 30));
    final artifacts = await repo.getArtifacts(limit: 40);
    final reflections = await repo.getReflections(limit: 40, sinceLocalDate: fromKey);

    final checkInsDone = await repo.countDoneCheckIns(sinceLocalDate: fromKey);
    final badSlips = await repo.countBadHabitSlips(sinceLocalDate: fromKey);

    return CoachContext(
      mode: mode,
      generatedAt: DateTime.now().toUtc(),
      windowFrom: fromKey,
      windowTo: toKey,
      windowDays: days,
      displayName: profile?.displayName ?? 'Я',
      timezone: profile?.timezone ?? 'UTC',
      visions: visions.map((v) => v.title).toList(),
      consistency30d: consistency,
      recoveryWarning:
          recovery.where((r) => r.twoDay.state == TwoDayState.warning).length,
      recoveryBroken:
          recovery.where((r) => r.twoDay.state == TwoDayState.broken).length,
      checkInsDone: checkInsDone,
      badHabitSlips: badSlips,
      goals: [
        for (final g in goals)
          {
            'id': g.id,
            'title': g.title,
            'life_area_key': areaById[g.lifeAreaId]?.key,
            'progress': g.progressRatio,
            'target_value': g.targetValue,
            'unit': g.unit,
          },
      ],
      failures: [
        for (final f in recovery)
          {
            'subject_id': f.id,
            'title': f.title,
            'subject_type': f.subjectType.dbValue,
            'missed_days': f.twoDay.missedDays,
            'state': f.twoDay.state.name,
          },
      ],
      artifacts: [
        for (final a in artifacts)
          {
            'id': a.id,
            'type': a.type.dbValue,
            'title': a.title,
            'metric_value': a.metricValue,
            'metric_unit': a.metricUnit,
            'local_date': a.localDate,
            'goal_id': a.goalId,
            // paths omitted for future API privacy
          },
      ],
      reflections: [
        for (final r in reflections)
          {
            'prompt_key': r.promptKey,
            'answer': r.answer,
            'local_date': r.localDate,
            'skipped': r.skipped,
            'trigger': r.trigger.dbValue,
          },
      ],
    );
  }
}
