import '../../domain/models/enums.dart';
import 'coach_provider.dart';

/// Deterministic offline coach — no network / API keys.
class StubCoachProvider implements CoachProvider {
  @override
  Future<CoachResponse> advise(CoachContext context) async {
    final name = context.displayName;
    final consPct = (context.consistency30d * 100).round();

    return switch (context.mode) {
      CoachMode.failureCoach => CoachResponse(
          mode: context.mode,
          headline: 'Мягкий разбор срыва',
          summary:
              '$name, за окно ${context.windowDays} дн. consistency ≈ $consPct%. '
              'Предупреждений: ${context.recoveryWarning}, срывов: ${context.recoveryBroken}. '
              'Это не про вину — про один маленький шаг сегодня.',
          insights: [
            if (context.failures.isNotEmpty)
              'В фокусе: «${context.failures.first['title']}» '
                  '(${context.failures.first['missed_days']} пропусков подряд).'
            else
              'Явных срывов по правилу двух дней сейчас нет — можно закрепить ритм.',
            if (context.badHabitSlips > 0)
              'Срывов плохих привычек в окне: ${context.badHabitSlips}. '
                  'Полезно кратко отметить триггер (рефлексия).'
            else
              'Плохие привычки в окне почти не отмечались — хороший знак.',
            if (context.reflections.isNotEmpty)
              'Есть ${context.reflections.length} рефлексий — опирайся на них, не на идеальный план.'
            else
              'Рефлексий пока мало: один честный ответ после следующего шага уже поможет.',
          ],
          suggestedActions: [
            CoachSuggestedAction(
              title: context.failures.isNotEmpty
                  ? 'Сделать «${context.failures.first['title']}» в минимальной версии сегодня'
                  : 'Выбрать одно действие на 10 минут сегодня',
              kind: 'other',
              why: 'Правило двух дней сбрасывается одним done сегодня.',
            ),
          ],
          reflectionPrompts: const ['slip_next'],
        ),
      CoachMode.monthlyReview => CoachResponse(
          mode: context.mode,
          headline: 'Месячный обзор — черновик',
          summary:
              'За ${context.windowDays} дней: consistency ≈ $consPct%, '
              'check-in done: ${context.checkInsDone}, '
              'артефактов: ${context.artifacts.length}, '
              'рефлексий: ${context.reflections.length}.',
          insights: [
            if (context.goals.isNotEmpty)
              'Целей в контексте: ${context.goals.length}. Смотри прогресс без давления.'
            else
              'Целей мало — можно добавить шаблон на экране Цели.',
            'XP и Consistency не зависят от рефлексий: они для смысла, не для очков.',
            if (context.visions.isNotEmpty)
              'Видение: «${context.visions.first}» — сверяй месяц с ним, не с чужим hustle.',
          ],
          suggestedActions: [
            const CoachSuggestedAction(
              title: 'Выбрать 1 сферу на следующий месяц и один шаблон',
              kind: 'other',
              why: 'Уже есть каталог реалистичных шаблонов.',
            ),
          ],
        ),
      CoachMode.yearlyReview => CoachResponse(
          mode: context.mode,
          headline: 'Годовой обзор — черновик',
          summary:
              'Длинное окно (${context.windowDays} дн.): consistency ≈ $consPct%. '
              'Это черновик без живого API.',
          insights: [
            'Годовой режим готов к подключению LLM; сейчас — stub.',
            'Артефактов в выборке: ${context.artifacts.length}.',
          ],
          suggestedActions: const [
            CoachSuggestedAction(
              title: 'Отметить 3 победы года в заметке-артефакте',
              kind: 'other',
            ),
          ],
        ),
      CoachMode.goalDecompose => CoachResponse(
          mode: context.mode,
          headline: 'Разбор цели',
          summary:
              'Локальный stub: разбей цель на действие с kind и маленький артефакт.',
          insights: [
            if (context.goals.isNotEmpty)
              'Ближайшая цель: «${context.goals.first['title']}».'
            else
              'Нет активных целей — возьми шаблон.',
            'Реалистичные цифры уже в TEMPLATES.md (не toxic hustle).',
          ],
          suggestedActions: [
            CoachSuggestedAction(
              title: context.goals.isNotEmpty
                  ? 'Добавить одно ежедневное действие к «${context.goals.first['title']}»'
                  : 'Добавить цель из шаблона',
              kind: 'study',
              why: 'Маленький шаг > идеальный план.',
            ),
          ],
        ),
    };
  }
}
