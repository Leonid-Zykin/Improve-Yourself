import '../../domain/models/enums.dart';

class TemplateActionSpec {
  const TemplateActionSpec({
    required this.title,
    required this.kind,
    this.schedule = ActionSchedule.daily,
    this.xp = 10,
    this.artifactHints = const [],
    this.reflectionPromptKeys = const [],
  });

  final String title;
  final ActionKind kind;
  final ActionSchedule schedule;
  final int xp;
  final List<ArtifactType> artifactHints;
  final List<String> reflectionPromptKeys;
}

class TemplateHabitSpec {
  const TemplateHabitSpec({
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

class GoalTemplate {
  const GoalTemplate({
    required this.id,
    required this.lifeArea,
    required this.title,
    required this.description,
    this.targetValue,
    this.unit,
    this.deadlineWeeks,
    this.actions = const [],
    this.habits = const [],
  });

  final String id;
  final String lifeArea;
  final String title;
  final String description;
  final double? targetValue;
  final String? unit;
  final int? deadlineWeeks;
  final List<TemplateActionSpec> actions;
  final List<TemplateHabitSpec> habits;
}

class OnboardingPreset {
  const OnboardingPreset({
    required this.id,
    required this.label,
    required this.visionHint,
    required this.templateIds,
  });

  final String id;
  final String label;
  final String visionHint;
  final List<String> templateIds;
}

/// Stable template catalog (ids must not change).
class TemplateCatalog {
  static const templates = <GoalTemplate>[
    GoalTemplate(
      id: 'health_train_3x',
      lifeArea: 'health',
      title: 'Тренировки 3× в неделю',
      description: 'ACSM/NSCA: новичкам 2–3 силовых в неделю на всё тело.',
      targetValue: 12,
      unit: 'трен./мес',
      actions: [
        TemplateActionSpec(
          title: 'Силовая / тело',
          kind: ActionKind.workout,
          schedule: ActionSchedule.weekly,
          xp: 15,
          artifactHints: [ArtifactType.photo, ArtifactType.genericNote],
          reflectionPromptKeys: ['workout_feel'],
        ),
      ],
      habits: [
        TemplateHabitSpec(
          title: 'Разминка 5 мин',
          kind: HabitKind.good,
          areaKeys: ['health'],
          xpDelta: 5,
        ),
      ],
    ),
    GoalTemplate(
      id: 'health_lose_5kg',
      lifeArea: 'health',
      title: '−5 кг устойчиво',
      description: 'CDC: ~0.5–1 кг/нед → −5 кг за ~6–12 недель.',
      targetValue: 5,
      unit: 'кг',
      deadlineWeeks: 12,
      actions: [
        TemplateActionSpec(
          title: 'Взвешивание + короткий лог',
          kind: ActionKind.other,
          schedule: ActionSchedule.weekly,
          xp: 10,
          artifactHints: [ArtifactType.metric],
        ),
      ],
      habits: [
        TemplateHabitSpec(
          title: 'Прогулка 20–30 мин',
          kind: HabitKind.good,
          areaKeys: ['health'],
          xpDelta: 8,
        ),
      ],
    ),
    GoalTemplate(
      id: 'health_sleep_8h',
      lifeArea: 'health',
      title: 'Сон ~8 часов',
      description: 'NSF: взрослым 7–9 ч; 8 ч — удобная цель внутри диапазона.',
      targetValue: 8,
      unit: 'ч/ночь',
      actions: [
        TemplateActionSpec(
          title: 'Отбой по плану',
          kind: ActionKind.other,
          xp: 10,
          artifactHints: [ArtifactType.metric],
        ),
      ],
      habits: [
        TemplateHabitSpec(
          title: 'Экраны за 30 мин до сна',
          kind: HabitKind.good,
          areaKeys: ['health', 'growth'],
          xpDelta: 6,
        ),
      ],
    ),
    GoalTemplate(
      id: 'career_remote_4k',
      lifeArea: 'career',
      title: 'Удалёнка \$4000+',
      description: 'Точечные отклики + English + портфолио, без spray-and-pray.',
      targetValue: 4000,
      unit: '\$/мес',
      actions: [
        TemplateActionSpec(
          title: '2–3 точечных отклика',
          kind: ActionKind.career,
          xp: 15,
          artifactHints: [ArtifactType.dailyLog],
          reflectionPromptKeys: ['career_blocker'],
        ),
        TemplateActionSpec(
          title: 'English 30 мин (собес)',
          kind: ActionKind.language,
          xp: 12,
          reflectionPromptKeys: ['language_practice'],
        ),
        TemplateActionSpec(
          title: 'Портфолио / кейс 45 мин',
          kind: ActionKind.career,
          schedule: ActionSchedule.weekly,
          xp: 15,
          artifactHints: [ArtifactType.genericNote],
        ),
      ],
    ),
    GoalTemplate(
      id: 'career_junior_middle',
      lifeArea: 'career',
      title: 'Junior → Middle',
      description: 'Ежедневная глубокая практика 45–60 мин.',
      actions: [
        TemplateActionSpec(
          title: 'Глубокая практика 45–60 мин',
          kind: ActionKind.study,
          xp: 15,
          artifactHints: [ArtifactType.genericNote],
          reflectionPromptKeys: ['study_focus'],
        ),
      ],
    ),
    GoalTemplate(
      id: 'career_daily_log',
      lifeArea: 'career',
      title: 'Ежедневный work log',
      description: '5–10 минут фиксации: что сделал, что блокер.',
      targetValue: 20,
      unit: 'логов/мес',
      actions: [
        TemplateActionSpec(
          title: 'Work log 5–10 мин',
          kind: ActionKind.career,
          xp: 8,
          artifactHints: [ArtifactType.dailyLog],
          reflectionPromptKeys: ['career_blocker'],
        ),
      ],
    ),
    GoalTemplate(
      id: 'books_12_year',
      lifeArea: 'growth',
      title: '12 книг в год',
      description: '~10 стр/день при ~300 стр/книгу ≈ 12 книг/год.',
      targetValue: 12,
      unit: 'книг',
      actions: [
        TemplateActionSpec(
          title: '10 страниц',
          kind: ActionKind.reading,
          xp: 10,
          artifactHints: [ArtifactType.chapterNote, ArtifactType.metric],
          reflectionPromptKeys: ['reading_takeaway'],
        ),
      ],
    ),
    GoalTemplate(
      id: 'books_finish_one',
      lifeArea: 'growth',
      title: 'Дочитать одну книгу',
      description: '15 стр/день — одна книга за ~3–5 недель.',
      targetValue: 1,
      unit: 'книга',
      deadlineWeeks: 5,
      actions: [
        TemplateActionSpec(
          title: '15 страниц текущей книги',
          kind: ActionKind.reading,
          xp: 10,
          artifactHints: [ArtifactType.chapterNote],
          reflectionPromptKeys: ['reading_takeaway'],
        ),
      ],
    ),
    GoalTemplate(
      id: 'finance_emergency_fund',
      lifeArea: 'finance',
      title: 'Подушка безопасности',
      description: 'Стартовый этап \$1000, затем 3–6 месяцев расходов.',
      targetValue: 1000,
      unit: '\$',
      actions: [
        TemplateActionSpec(
          title: 'Перевод в подушку',
          kind: ActionKind.other,
          schedule: ActionSchedule.weekly,
          xp: 12,
          artifactHints: [ArtifactType.metric],
        ),
      ],
    ),
    GoalTemplate(
      id: 'finance_expense_track',
      lifeArea: 'finance',
      title: 'Учёт расходов',
      description: '30 дней подряд с короткой записью трат.',
      targetValue: 30,
      unit: 'дней',
      actions: [
        TemplateActionSpec(
          title: 'Записать расходы дня',
          kind: ActionKind.other,
          xp: 8,
          artifactHints: [ArtifactType.dailyLog, ArtifactType.metric],
        ),
      ],
    ),
    GoalTemplate(
      id: 'rel_contact_loved',
      lifeArea: 'relationships',
      title: 'Связь с близкими',
      description: '~1 контакт в неделю = 4 / месяц.',
      targetValue: 4,
      unit: 'контактов/мес',
      actions: [
        TemplateActionSpec(
          title: 'Созвон / сообщение близким',
          kind: ActionKind.other,
          schedule: ActionSchedule.weekly,
          xp: 10,
          artifactHints: [ArtifactType.genericNote],
        ),
      ],
    ),
    GoalTemplate(
      id: 'lang_english_b2',
      lifeArea: 'growth',
      title: 'English → B2',
      description: 'Cambridge: ~500–600 ч до B2; 30–45 мин/день устойчиво.',
      actions: [
        TemplateActionSpec(
          title: 'English 30 мин',
          kind: ActionKind.language,
          xp: 12,
          artifactHints: [ArtifactType.genericNote],
          reflectionPromptKeys: ['language_practice'],
        ),
      ],
      habits: [
        TemplateHabitSpec(
          title: 'Listening в дороге 15 мин',
          kind: HabitKind.good,
          areaKeys: ['growth', 'career'],
          xpDelta: 5,
        ),
      ],
    ),
  ];

  static const presets = <OnboardingPreset>[
    OnboardingPreset(
      id: 'remote_athlete',
      label: 'Удалёнка + тело',
      visionHint: 'Senior remote + сильное тело',
      templateIds: ['health_train_3x', 'career_remote_4k', 'lang_english_b2'],
    ),
    OnboardingPreset(
      id: 'balanced_reader',
      label: 'Баланс + книги',
      visionHint: 'Спокойный рост и чтение',
      templateIds: ['health_sleep_8h', 'books_12_year', 'rel_contact_loved'],
    ),
    OnboardingPreset(
      id: 'money_stability',
      label: 'Финансовая опора',
      visionHint: 'Подушка и ясность по деньгам',
      templateIds: [
        'finance_emergency_fund',
        'finance_expense_track',
        'career_daily_log',
      ],
    ),
    OnboardingPreset(
      id: 'career_climb',
      label: 'Карьерный шаг',
      visionHint: 'Junior→Middle + практика',
      templateIds: [
        'career_junior_middle',
        'career_daily_log',
        'lang_english_b2',
      ],
    ),
    OnboardingPreset(
      id: 'health_reset',
      label: 'Здоровье с нуля',
      visionHint: 'Сон, вес, движение без фанатизма',
      templateIds: ['health_sleep_8h', 'health_train_3x', 'health_lose_5kg'],
    ),
  ];

  static GoalTemplate? byId(String id) {
    for (final t in templates) {
      if (t.id == id) return t;
    }
    return null;
  }

  static OnboardingPreset? presetById(String id) {
    for (final p in presets) {
      if (p.id == id) return p;
    }
    return null;
  }
}
