import 'package:flutter_test/flutter_test.dart';
import 'package:improve_yourself/domain/models/enums.dart';
import 'package:improve_yourself/domain/reflection/trigger_rules.dart';
import 'package:improve_yourself/services/coach/stub_coach_provider.dart';
import 'package:improve_yourself/services/coach/coach_provider.dart';

void main() {
  group('ReflectionTriggerRules', () {
    const rules = ReflectionTriggerRules(maxAutoPerDay: 3);

    test('offers for reflective action kind when done', () {
      expect(
        rules.shouldOffer(
          reflectionsEnabled: true,
          autoReflectionsToday: 0,
          subjectType: SubjectType.action,
          actionKind: ActionKind.workout,
          status: CheckInStatus.done,
        ),
        isTrue,
      );
    });

    test('does not offer for kind=other', () {
      expect(
        rules.shouldOffer(
          reflectionsEnabled: true,
          autoReflectionsToday: 0,
          subjectType: SubjectType.action,
          actionKind: ActionKind.other,
          status: CheckInStatus.done,
        ),
        isFalse,
      );
    });

    test('offers for bad habit slip', () {
      expect(
        rules.shouldOffer(
          reflectionsEnabled: true,
          autoReflectionsToday: 2,
          subjectType: SubjectType.habit,
          habitKind: HabitKind.bad,
          status: CheckInStatus.done,
        ),
        isTrue,
      );
    });

    test('anti-nag at max per day', () {
      expect(
        rules.shouldOffer(
          reflectionsEnabled: true,
          autoReflectionsToday: 3,
          subjectType: SubjectType.action,
          actionKind: ActionKind.reading,
          status: CheckInStatus.done,
        ),
        isFalse,
      );
    });

    test('disabled setting blocks', () {
      expect(
        rules.shouldOffer(
          reflectionsEnabled: false,
          autoReflectionsToday: 0,
          subjectType: SubjectType.action,
          actionKind: ActionKind.career,
          status: CheckInStatus.done,
        ),
        isFalse,
      );
    });
  });

  group('StubCoachProvider', () {
    test('returns structured failure_coach response', () async {
      final provider = StubCoachProvider();
      final ctx = CoachContext(
        mode: CoachMode.failureCoach,
        generatedAt: DateTime.utc(2026, 8, 7),
        windowFrom: '2026-07-08',
        windowTo: '2026-08-07',
        windowDays: 30,
        displayName: 'Тест',
        timezone: 'UTC',
        visions: ['Сильный и спокойный'],
        consistency30d: 0.5,
        recoveryWarning: 1,
        recoveryBroken: 1,
        checkInsDone: 10,
        badHabitSlips: 1,
        goals: [
          {'id': 'g1', 'title': 'Тренировки', 'life_area_key': 'health'},
        ],
        failures: [
          {
            'subject_id': 'a1',
            'title': 'Силовая',
            'missed_days': 3,
            'state': 'broken',
          },
        ],
        artifacts: const [],
        reflections: const [],
      );
      final res = await provider.advise(ctx);
      expect(res.mode, CoachMode.failureCoach);
      expect(res.headline, isNotEmpty);
      expect(res.summary, contains('Тест'));
      expect(res.insights, isNotEmpty);
      expect(res.suggestedActions, isNotEmpty);
      expect(res.toJson()['schema_version'], 1);
    });
  });
}
