import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/models/enums.dart';
import 'coach_provider.dart';
import 'stub_coach_provider.dart';

/// OpenAI-compatible chat completions via OpenRouter.
class OpenRouterCoachProvider implements CoachProvider {
  OpenRouterCoachProvider({
    required this.apiKey,
    this.model = 'openrouter/free',
    CoachProvider? fallback,
    http.Client? client,
    this.baseUrl = 'https://openrouter.ai/api/v1/chat/completions',
    this.httpReferer = 'https://github.com/improve-yourself/app',
    this.appTitle = 'Improve Yourself',
  })  : fallback = fallback ?? StubCoachProvider(),
        _client = client ?? http.Client(),
        _ownsClient = client == null;

  final String apiKey;
  final String model;
  final CoachProvider fallback;
  final String baseUrl;
  final String httpReferer;
  final String appTitle;
  final http.Client _client;
  final bool _ownsClient;

  void dispose() {
    if (_ownsClient) _client.close();
  }

  @override
  Future<CoachResponse> advise(CoachContext context) async {
    try {
      return await _adviseLive(context);
    } catch (e) {
      final stub = await fallback.advise(context);
      return stub.copyWith(
        disclaimer:
            'Показан локальный stub: живой коуч недоступен (${_friendlyError(e)}). '
            'Не медицинский совет.',
        warning:
            'Живой коуч недоступен. Показан локальный черновик. ${_friendlyError(e)}',
      );
    }
  }

  Future<CoachResponse> _adviseLive(CoachContext context) async {
    final body = jsonEncode({
      'model': model,
      'response_format': {'type': 'json_object'},
      'temperature': 0.4,
      'messages': [
        {'role': 'system', 'content': _systemPrompt(context.mode)},
        {
          'role': 'user',
          'content': jsonEncode(context.toJson()),
        },
      ],
    });

    final response = await _client.post(
      Uri.parse(baseUrl),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        'HTTP-Referer': httpReferer,
        'X-Title': appTitle,
      },
      body: body,
    );

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const CoachHttpException(
        'Ключ OpenRouter отклонён. Проверьте его в Настройках.',
        statusCode: 401,
      );
    }
    if (response.statusCode == 429) {
      throw const CoachHttpException(
        'Лимит запросов OpenRouter. Попробуйте позже.',
        statusCode: 429,
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw CoachHttpException(
        'OpenRouter ответил ${response.statusCode}.',
        statusCode: response.statusCode,
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Неожиданный ответ OpenRouter');
    }
    final choices = decoded['choices'];
    if (choices is! List || choices.isEmpty) {
      throw const FormatException('Пустой ответ модели');
    }
    final message = choices.first is Map ? choices.first['message'] : null;
    final content = message is Map ? message['content']?.toString() : null;
    if (content == null || content.trim().isEmpty) {
      throw const FormatException('Модель вернула пустой текст');
    }

    final map = _parseJsonObject(content);
    return CoachResponse.fromJson(map, fallbackMode: context.mode).copyWith(
      disclaimer: map['disclaimer']?.toString() ??
          'Черновик от живого коуча (OpenRouter); не медицинский совет.',
    );
  }

  static String _systemPrompt(CoachMode mode) {
    final modeHint = switch (mode) {
      CoachMode.failureCoach =>
        'Режим failure_coach: мягкий разбор срыва / правила двух дней, без вины.',
      CoachMode.monthlyReview =>
        'Режим monthly_review: черновик месячного обзора по статистике окна.',
      CoachMode.yearlyReview =>
        'Режим yearly_review: длинный обзор; держи фокус на смыслах, не на давлении.',
      CoachMode.goalDecompose =>
        'Режим goal_decompose: разбей цель на маленькие реалистичные шаги.',
    };

    return '''
Ты — поддерживающий русскоязычный коуч приложения Improve Yourself.
$modeHint
Отвечай ТОЛЬКО валидным JSON-объектом (без markdown и без текста вокруг) со схемой:
{
  "schema_version": 1,
  "mode": "${mode.apiValue}",
  "headline": "короткий заголовок",
  "summary": "2–4 предложения",
  "insights": ["…"],
  "suggested_actions": [{"title": "…", "kind": "other|study|workout|reading|career|language", "why": "…"}],
  "reflection_prompts": ["slip_next"],
  "tone": "supportive",
  "disclaimer": "кратко: не медицинский совет"
}
Не давай медицинских, психиатрических или юридических советов.
Опирайся только на переданный CoachContext JSON. Пиши по-русски, тепло и конкретно.
''';
  }

  /// Public for unit tests.
  static Map<String, dynamic> parseModelContent(String content) =>
      _parseJsonObject(content);

  static Map<String, dynamic> _parseJsonObject(String content) {
    var text = content.trim();
    if (text.startsWith('```')) {
      final firstNl = text.indexOf('\n');
      if (firstNl != -1) text = text.substring(firstNl + 1);
      if (text.endsWith('```')) {
        text = text.substring(0, text.length - 3).trim();
      }
    }
    final decoded = jsonDecode(text);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    throw const FormatException('Ответ модели не JSON-объект');
  }

  static String _friendlyError(Object e) {
    if (e is CoachHttpException) return e.message;
    if (e is FormatException) {
      return e.message.isNotEmpty ? e.message : 'Не удалось разобрать ответ';
    }
    final s = e.toString();
    if (s.contains('SocketException') || s.contains('Failed host lookup')) {
      return 'Нет сети';
    }
    if (s.contains('TimeoutException')) return 'Таймаут сети';
    return 'ошибка запроса';
  }
}

class CoachHttpException implements Exception {
  const CoachHttpException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
