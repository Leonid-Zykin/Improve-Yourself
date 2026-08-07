import 'package:flutter_test/flutter_test.dart';
import 'package:improve_yourself/data/db/database.dart';
import 'package:improve_yourself/data/repositories/app_repository.dart';
import 'package:improve_yourself/domain/models/models.dart';

void main() {
  test('check-in updates area_xp in transaction', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    final repo = AppRepository(db);

    final areas = await repo.getLifeAreas();
    final health = areas.firstWhere((a) => a.key == 'health');
    await repo.addAction(lifeAreaId: health.id, title: 'Walk', xpReward: 20);

    final plan = await repo.getTodayPlan();
    final action = plan.firstWhere((s) => s.title == 'Walk');

    await repo.checkIn(
      subjectType: SubjectType.action,
      subjectId: action.id,
      status: CheckInStatus.done,
    );

    final xp = await db.select(db.areaXpTable).get();
    final healthXp = xp.firstWhere((r) => r.lifeAreaId == health.id);
    expect(healthXp.xpTotal, 20);
    expect(healthXp.level, greaterThanOrEqualTo(1));
  });
}
