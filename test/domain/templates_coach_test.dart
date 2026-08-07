import 'package:flutter_test/flutter_test.dart';
import 'package:improve_yourself/data/db/database.dart';
import 'package:improve_yourself/data/repositories/app_repository.dart';
import 'package:improve_yourself/domain/models/models.dart';
import 'package:improve_yourself/services/coach/coach_context_builder.dart';

void main() {
  test('applyTemplate creates goal+actions; coach context builds', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    final repo = AppRepository(db);

    await repo.applyTemplate('health_train_3x');
    final goals = await repo.getGoals();
    expect(goals.any((g) => g.title.contains('Тренировки')), isTrue);

    final plan = await repo.getTodayPlan();
    expect(plan.any((s) => s.actionKind == ActionKind.workout), isTrue);

    final builder = CoachContextBuilder(repo);
    final ctx = await builder.build(mode: CoachMode.monthlyReview);
    expect(ctx.toJson()['schema_version'], 1);
    expect(ctx.goals, isNotEmpty);
  });

  test('reflection anti-nag counts saved rows', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    final repo = AppRepository(db);

    final areas = await repo.getLifeAreas();
    final health = areas.firstWhere((a) => a.key == 'health');
    await repo.addAction(
      lifeAreaId: health.id,
      title: 'Силовая',
      kind: ActionKind.workout,
    );
    final action = (await repo.getTodayPlan()).firstWhere((s) => s.title == 'Силовая');

    for (var i = 0; i < 3; i++) {
      await repo.saveReflection(
        promptKey: 'workout_feel',
        promptText: 'q',
        trigger: ReflectionTrigger.actionKind,
        skipped: true,
        subjectType: SubjectType.action,
        subjectId: action.id,
        actionKind: ActionKind.workout,
      );
    }

    final offer = await repo.shouldOfferReflection(
      subjectType: SubjectType.action,
      subjectId: action.id,
      status: CheckInStatus.done,
    );
    expect(offer, isFalse);
  });
}
