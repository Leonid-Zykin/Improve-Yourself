import 'package:flutter_test/flutter_test.dart';
import 'package:improve_yourself/data/db/database.dart';
import 'package:improve_yourself/data/repositories/app_repository.dart';

void main() {
  test('memory database seeds life areas and settings', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);

    final repo = AppRepository(db);
    // Allow migration/seed to finish.
    final areas = await repo.getLifeAreas();
    expect(areas.length, 5);
    expect(areas.map((a) => a.key), containsAll(['health', 'career']));

    final profile = await repo.getProfile();
    expect(profile, isNotNull);
    expect(profile!.onboardingCompleted, isFalse);
  });
}
