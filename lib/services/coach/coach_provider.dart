import '../../domain/models/enums.dart';

class CoachContext {
  const CoachContext({
    required this.mode,
    required this.generatedAt,
    required this.windowFrom,
    required this.windowTo,
    required this.windowDays,
    required this.displayName,
    required this.timezone,
    required this.visions,
    required this.consistency30d,
    required this.recoveryWarning,
    required this.recoveryBroken,
    required this.checkInsDone,
    required this.badHabitSlips,
    required this.goals,
    required this.failures,
    required this.artifacts,
    required this.reflections,
  });

  final CoachMode mode;
  final DateTime generatedAt;
  final String windowFrom;
  final String windowTo;
  final int windowDays;
  final String displayName;
  final String timezone;
  final List<String> visions;
  final double consistency30d;
  final int recoveryWarning;
  final int recoveryBroken;
  final int checkInsDone;
  final int badHabitSlips;
  final List<Map<String, Object?>> goals;
  final List<Map<String, Object?>> failures;
  final List<Map<String, Object?>> artifacts;
  final List<Map<String, Object?>> reflections;

  Map<String, Object?> toJson() => {
        'schema_version': 1,
        'mode': mode.apiValue,
        'generated_at': generatedAt.toUtc().toIso8601String(),
        'window': {
          'from': windowFrom,
          'to': windowTo,
          'days': windowDays,
        },
        'profile': {
          'display_name': displayName,
          'timezone': timezone,
        },
        'visions': visions,
        'stats': {
          'consistency_30d': consistency30d,
          'recovery_warning': recoveryWarning,
          'recovery_broken': recoveryBroken,
          'check_ins_done': checkInsDone,
          'bad_habit_slips': badHabitSlips,
        },
        'goals': goals,
        'failures': failures,
        'artifacts': artifacts,
        'reflections': reflections,
      };
}

class CoachSuggestedAction {
  const CoachSuggestedAction({
    required this.title,
    required this.kind,
    this.why,
  });

  final String title;
  final String kind;
  final String? why;
}

class CoachResponse {
  const CoachResponse({
    required this.mode,
    required this.headline,
    required this.summary,
    required this.insights,
    required this.suggestedActions,
    this.reflectionPrompts = const [],
    this.tone = 'supportive',
    this.disclaimer =
        'Черновик от локального stub-коуча; не медицинский совет.',
    this.warning,
  });

  final CoachMode mode;
  final String headline;
  final String summary;
  final List<String> insights;
  final List<CoachSuggestedAction> suggestedActions;
  final List<String> reflectionPrompts;
  final String tone;
  final String disclaimer;

  /// Optional UI notice (e.g. live API fell back to stub).
  final String? warning;

  factory CoachResponse.fromJson(
    Map<String, dynamic> json, {
    CoachMode? fallbackMode,
  }) {
    final modeRaw = json['mode'] as String?;
    final mode = modeRaw != null
        ? CoachModeX.fromApi(modeRaw)
        : (fallbackMode ?? CoachMode.failureCoach);

    final actionsRaw = json['suggested_actions'];
    final actions = <CoachSuggestedAction>[];
    if (actionsRaw is List) {
      for (final item in actionsRaw) {
        if (item is! Map) continue;
        final title = item['title']?.toString().trim() ?? '';
        if (title.isEmpty) continue;
        actions.add(
          CoachSuggestedAction(
            title: title,
            kind: item['kind']?.toString() ?? 'other',
            why: item['why']?.toString(),
          ),
        );
      }
    }

    final insightsRaw = json['insights'];
    final insights = insightsRaw is List
        ? insightsRaw.map((e) => e.toString()).where((s) => s.isNotEmpty).toList()
        : <String>[];

    final promptsRaw = json['reflection_prompts'];
    final prompts = promptsRaw is List
        ? promptsRaw.map((e) => e.toString()).toList()
        : <String>[];

    final headline = json['headline']?.toString().trim() ?? '';
    final summary = json['summary']?.toString().trim() ?? '';
    if (headline.isEmpty || summary.isEmpty) {
      throw const FormatException('CoachResponse: headline/summary required');
    }

    return CoachResponse(
      mode: mode,
      headline: headline,
      summary: summary,
      insights: insights,
      suggestedActions: actions,
      reflectionPrompts: prompts,
      tone: json['tone']?.toString() ?? 'supportive',
      disclaimer: json['disclaimer']?.toString() ??
          'Черновик от коуча; не медицинский совет.',
    );
  }

  CoachResponse copyWith({
    CoachMode? mode,
    String? headline,
    String? summary,
    List<String>? insights,
    List<CoachSuggestedAction>? suggestedActions,
    List<String>? reflectionPrompts,
    String? tone,
    String? disclaimer,
    String? warning,
  }) {
    return CoachResponse(
      mode: mode ?? this.mode,
      headline: headline ?? this.headline,
      summary: summary ?? this.summary,
      insights: insights ?? this.insights,
      suggestedActions: suggestedActions ?? this.suggestedActions,
      reflectionPrompts: reflectionPrompts ?? this.reflectionPrompts,
      tone: tone ?? this.tone,
      disclaimer: disclaimer ?? this.disclaimer,
      warning: warning ?? this.warning,
    );
  }

  Map<String, Object?> toJson() => {
        'schema_version': 1,
        'mode': mode.apiValue,
        'headline': headline,
        'summary': summary,
        'insights': insights,
        'suggested_actions': [
          for (final a in suggestedActions)
            {
              'title': a.title,
              'kind': a.kind,
              if (a.why != null) 'why': a.why,
            },
        ],
        'reflection_prompts': reflectionPrompts,
        'tone': tone,
        'disclaimer': disclaimer,
      };
}

abstract class CoachProvider {
  Future<CoachResponse> advise(CoachContext context);
}
