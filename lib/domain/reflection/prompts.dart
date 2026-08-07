import '../models/enums.dart';

/// Catalog of reflection prompts (stable keys).
class ReflectionPrompt {
  const ReflectionPrompt({required this.key, required this.text});

  final String key;
  final String text;
}

class ReflectionPrompts {
  static const workoutFeel = ReflectionPrompt(
    key: 'workout_feel',
    text: 'Как прошла тренировка? Что было тяжело?',
  );
  static const readingTakeaway = ReflectionPrompt(
    key: 'reading_takeaway',
    text: 'Одна мысль из прочитанного?',
  );
  static const careerBlocker = ReflectionPrompt(
    key: 'career_blocker',
    text: 'Что мешало / что сдвинуло поиск вперёд?',
  );
  static const studyFocus = ReflectionPrompt(
    key: 'study_focus',
    text: 'Сколько минут реально в фокусе?',
  );
  static const languagePractice = ReflectionPrompt(
    key: 'language_practice',
    text: 'Что практиковал(а): speaking / listening / vocab?',
  );
  static const slipTrigger = ReflectionPrompt(
    key: 'slip_trigger',
    text: 'Что было триггером срыва?',
  );
  static const slipNext = ReflectionPrompt(
    key: 'slip_next',
    text: 'Что поможет в следующий раз (микрошаг)?',
  );

  static const all = <ReflectionPrompt>[
    workoutFeel,
    readingTakeaway,
    careerBlocker,
    studyFocus,
    languagePractice,
    slipTrigger,
    slipNext,
  ];

  static ReflectionPrompt? byKey(String key) {
    for (final p in all) {
      if (p.key == key) return p;
    }
    return null;
  }

  static ReflectionPrompt forActionKind(ActionKind kind) {
    return switch (kind) {
      ActionKind.workout => workoutFeel,
      ActionKind.reading => readingTakeaway,
      ActionKind.career => careerBlocker,
      ActionKind.study => studyFocus,
      ActionKind.language => languagePractice,
      ActionKind.other => workoutFeel, // unused when other
    };
  }

  static ReflectionPrompt forBadHabitSlip() => slipTrigger;
}
