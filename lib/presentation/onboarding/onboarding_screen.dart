import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/repositories/app_repository.dart';
import '../../data/templates/catalog.dart';
import '../../domain/models/enums.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _page = PageController();
  final _nameCtrl = TextEditingController(text: 'Я');
  final _visionCtrl = TextEditingController();
  var _index = 0;
  var _busy = false;
  String? _presetId;

  late final Map<String, TextEditingController> _goalCtrls = {
    'health': TextEditingController(text: 'Тренировки 3× в неделю'),
    'career': TextEditingController(text: 'Удалёнка \$4000+'),
    'finance': TextEditingController(text: 'Подушка \$1000'),
    'growth': TextEditingController(text: '12 книг в год'),
    'relationships': TextEditingController(text: 'Связь с близкими'),
  };

  @override
  void dispose() {
    _page.dispose();
    _nameCtrl.dispose();
    _visionCtrl.dispose();
    for (final c in _goalCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _applyPreset(OnboardingPreset preset) {
    setState(() {
      _presetId = preset.id;
      _visionCtrl.text = preset.visionHint;
    });
  }

  Future<void> _finish() async {
    setState(() => _busy = true);
    try {
      final repo = ref.read(repositoryProvider);
      final vision = _visionCtrl.text.trim().isEmpty
          ? 'Лучшая версия себя'
          : _visionCtrl.text.trim();

      if (_presetId != null) {
        await repo.completeOnboarding(
          displayName:
              _nameCtrl.text.trim().isEmpty ? 'Я' : _nameCtrl.text.trim(),
          visionTitles: [vision],
          goalsByAreaKey: const {},
          actions: const [],
          habits: const [
            HabitSeed(
              title: 'Алкоголь',
              kind: HabitKind.bad,
              areaKeys: ['health'],
              xpDelta: 10,
            ),
          ],
        );
        await repo.applyOnboardingPreset(_presetId!);
        return;
      }

      final goals = <String, List<GoalSeed>>{};
      for (final e in _goalCtrls.entries) {
        final t = e.value.text.trim();
        if (t.isNotEmpty) {
          goals[e.key] = [GoalSeed(title: t)];
        }
      }

      await repo.completeOnboarding(
        displayName:
            _nameCtrl.text.trim().isEmpty ? 'Я' : _nameCtrl.text.trim(),
        visionTitles: [vision],
        goalsByAreaKey: goals,
        actions: const [
          ActionSeed(
            title: 'Силовая / тело',
            areaKey: 'health',
            xp: 15,
            kind: ActionKind.workout,
            schedule: ActionSchedule.weekly,
          ),
          ActionSeed(
            title: '2–3 точечных отклика',
            areaKey: 'career',
            xp: 15,
            kind: ActionKind.career,
          ),
          ActionSeed(
            title: '10 страниц',
            areaKey: 'growth',
            xp: 10,
            kind: ActionKind.reading,
          ),
        ],
        habits: const [
          HabitSeed(
            title: 'Сон до 23:00',
            kind: HabitKind.good,
            areaKeys: ['health', 'growth'],
            xpDelta: 8,
          ),
          HabitSeed(
            title: 'Алкоголь',
            kind: HabitKind.bad,
            areaKeys: ['health'],
            xpDelta: 10,
          ),
        ],
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(value: (_index + 1) / 3),
            Expanded(
              child: PageView(
                controller: _page,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _index = i),
                children: [
                  _WelcomePage(nameCtrl: _nameCtrl),
                  _VisionPage(
                    visionCtrl: _visionCtrl,
                    presetId: _presetId,
                    onPreset: _applyPreset,
                  ),
                  _GoalsPage(goalCtrls: _goalCtrls, presetId: _presetId),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (_index > 0)
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => _page.previousPage(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOut,
                              ),
                      child: const Text('Назад'),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _busy
                        ? null
                        : () async {
                            if (_index < 2) {
                              await _page.nextPage(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOut,
                              );
                            } else {
                              await _finish();
                            }
                          },
                    child: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_index < 2 ? 'Далее' : 'Начать'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.nameCtrl});
  final TextEditingController nameCtrl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            'Improve Yourself',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Сферы жизни → цели → действия.\n'
            'Правило двух дней без наказаний.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 32),
          TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Как к тебе обращаться?',
            ),
          ),
        ],
      ),
    );
  }
}

class _VisionPage extends StatelessWidget {
  const _VisionPage({
    required this.visionCtrl,
    required this.presetId,
    required this.onPreset,
  });
  final TextEditingController visionCtrl;
  final String? presetId;
  final void Function(OnboardingPreset) onPreset;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Кем хочешь стать?',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Выбери пресет или напиши своё видение.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final p in TemplateCatalog.presets)
              ChoiceChip(
                label: Text(p.label),
                selected: presetId == p.id,
                onSelected: (_) => onPreset(p),
              ),
          ],
        ),
        const SizedBox(height: 24),
        TextField(
          controller: visionCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Например: Senior Backend + атлет',
            labelText: 'Видение',
          ),
        ),
      ],
    );
  }
}

class _GoalsPage extends StatelessWidget {
  const _GoalsPage({required this.goalCtrls, required this.presetId});
  final Map<String, TextEditingController> goalCtrls;
  final String? presetId;

  static const labels = {
    'health': 'Здоровье',
    'career': 'Карьера',
    'finance': 'Финансы',
    'growth': 'Саморазвитие',
    'relationships': 'Отношения',
  };

  @override
  Widget build(BuildContext context) {
    if (presetId != null) {
      final preset = TemplateCatalog.presetById(presetId!);
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Пресет: ${preset?.label ?? presetId}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          const Text(
            'При старте создадим цели и действия из шаблонов '
            '(реалистичные цифры из docs/TEMPLATES.md).',
          ),
          const SizedBox(height: 12),
          for (final id in preset?.templateIds ?? const <String>[])
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.check_circle_outline),
              title: Text(TemplateCatalog.byId(id)?.title ?? id),
            ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Стартовые цели',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        const Text('Можно править — позже добавим шаблоны на экране Цели.'),
        const SizedBox(height: 16),
        for (final e in goalCtrls.entries) ...[
          TextField(
            controller: e.value,
            decoration: InputDecoration(
              labelText: labels[e.key] ?? e.key,
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
