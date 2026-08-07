import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:improve_yourself/domain/models/enums.dart';
import 'package:improve_yourself/services/coach/coach_provider.dart';
import 'package:improve_yourself/services/coach/openrouter_coach_provider.dart';
import 'package:improve_yourself/services/coach/stub_coach_provider.dart';

CoachContext _sampleContext() => CoachContext(
      mode: CoachMode.failureCoach,
      generatedAt: DateTime.utc(2026, 8, 7),
      windowFrom: '2026-07-08',
      windowTo: '2026-08-07',
      windowDays: 30,
      displayName: 'Тест',
      timezone: 'UTC',
      visions: const ['Спокойствие'],
      consistency30d: 0.4,
      recoveryWarning: 1,
      recoveryBroken: 0,
      checkInsDone: 8,
      badHabitSlips: 0,
      goals: const [
        {'id': 'g1', 'title': 'Бег', 'life_area_key': 'health'},
      ],
      failures: const [
        {
          'subject_id': 'a1',
          'title': 'Пробежка',
          'missed_days': 2,
          'state': 'warning',
        },
      ],
      artifacts: const [],
      reflections: const [],
    );

void main() {
  group('CoachResponse.fromJson', () {
    test('parses structured payload', () {
      final res = CoachResponse.fromJson({
        'schema_version': 1,
        'mode': 'failure_coach',
        'headline': 'Заголовок',
        'summary': 'Краткий текст',
        'insights': ['a', 'b'],
        'suggested_actions': [
          {'title': 'Шаг', 'kind': 'other', 'why': 'потому что'},
        ],
        'reflection_prompts': ['slip_next'],
        'tone': 'supportive',
        'disclaimer': 'не медсовет',
      });
      expect(res.mode, CoachMode.failureCoach);
      expect(res.headline, 'Заголовок');
      expect(res.suggestedActions.single.title, 'Шаг');
      expect(res.insights, ['a', 'b']);
    });

    test('rejects empty headline', () {
      expect(
        () => CoachResponse.fromJson({
          'mode': 'monthly_review',
          'headline': '  ',
          'summary': 'ok',
        }),
        throwsFormatException,
      );
    });
  });

  group('OpenRouterCoachProvider', () {
    test('strips markdown fences from model content', () {
      final map = OpenRouterCoachProvider.parseModelContent('''
```json
{"headline":"H","summary":"S","insights":[],"suggested_actions":[]}
```
''');
      expect(map['headline'], 'H');
    });

    test('parses successful chat completion', () async {
      final client = MockClient((request) async {
        expect(request.url.host, 'openrouter.ai');
        expect(request.headers['Authorization'], 'Bearer test-key');
        expect(request.headers['X-Title'], 'Improve Yourself');
        expect(request.headers['HTTP-Referer'], isNotEmpty);
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['model'], 'openrouter/free');
        expect(body['response_format'], {'type': 'json_object'});
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {
                  'content': jsonEncode({
                    'schema_version': 1,
                    'mode': 'failure_coach',
                    'headline': 'Живой разбор',
                    'summary': 'Ты справишься сегодня одним шагом.',
                    'insights': ['Фокус на минимуме'],
                    'suggested_actions': [
                      {'title': 'Короткая прогулка', 'kind': 'other'},
                    ],
                    'tone': 'supportive',
                    'disclaimer': 'не медсовет',
                  }),
                },
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final provider = OpenRouterCoachProvider(
        apiKey: 'test-key',
        model: 'openrouter/free',
        client: client,
        fallback: StubCoachProvider(),
      );
      final res = await provider.advise(_sampleContext());
      expect(res.headline, 'Живой разбор');
      expect(res.warning, isNull);
      expect(res.suggestedActions, isNotEmpty);
    });

    test('falls back to stub on HTTP error', () async {
      final client = MockClient(
        (_) async => http.Response('rate limited', 429),
      );
      final provider = OpenRouterCoachProvider(
        apiKey: 'test-key',
        client: client,
        fallback: StubCoachProvider(),
      );
      final res = await provider.advise(_sampleContext());
      expect(res.headline, isNotEmpty);
      expect(res.warning, contains('Живой коуч недоступен'));
      expect(res.disclaimer, contains('stub'));
    });
  });
}
