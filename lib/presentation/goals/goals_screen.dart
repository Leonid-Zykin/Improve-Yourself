import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/models/models.dart';
import '../common/artifact_sheet.dart';
import '../common/coach_sheet.dart';
import '../common/widgets.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsProvider);
    final areas = ref.watch(lifeAreasProvider);
    final visions = ref.watch(visionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Цели'),
        actions: [
          IconButton(
            tooltip: 'Из шаблона',
            icon: const Icon(Icons.library_add_outlined),
            onPressed: () => showTemplatePicker(context, ref),
          ),
          IconButton(
            tooltip: 'Коуч: разобрать цель',
            icon: const Icon(Icons.psychology_outlined),
            onPressed: () => showCoachDraft(
              context,
              ref,
              mode: CoachMode.goalDecompose,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _addGoal(context, ref),
          ),
        ],
      ),
      body: goals.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Ошибка: $e')),
        data: (goalList) {
          final areaList = areas.asData?.value ?? [];
          final byArea = <String, List<Goal>>{};
          for (final g in goalList) {
            byArea.putIfAbsent(g.lifeAreaId, () => []).add(g);
          }
          final visionTitle = visions.asData?.value.isNotEmpty == true
              ? visions.asData!.value.first.title
              : null;

          if (goalList.isEmpty) {
            return EmptyState(
              title: 'Нет целей',
              subtitle:
                  'Добавь цель или выбери шаблон (иконка библиотеки сверху).',
              icon: Icons.flag_outlined,
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (visionTitle != null) ...[
                Text('Видение', style: Theme.of(context).textTheme.titleSmall),
                Text(
                  visionTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
              ],
              Text('Лента артефактов',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              const ArtifactsTimeline(limit: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => showAddArtifactSheet(context, ref),
                  icon: const Icon(Icons.attachment),
                  label: const Text('Добавить артефакт'),
                ),
              ),
              const SizedBox(height: 8),
              for (final area in areaList)
                if (byArea[area.id]?.isNotEmpty == true) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(iconForArea(area.icon),
                        color: Color(area.color)),
                    title: Text(
                      area.title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  ...byArea[area.id]!.map(
                    (g) => _GoalCard(goal: g, lifeAreaId: area.id),
                  ),
                  const SizedBox(height: 8),
                ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _addGoal(BuildContext context, WidgetRef ref) async {
    final areas = await ref.read(repositoryProvider).getLifeAreas();
    if (!context.mounted || areas.isEmpty) return;
    final titleCtrl = TextEditingController();
    final targetCtrl = TextEditingController();
    final unitCtrl = TextEditingController();
    var areaId = areas.first.id;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Новая цель'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: areaId,
                  items: [
                    for (final a in areas)
                      DropdownMenuItem(value: a.id, child: Text(a.title)),
                  ],
                  onChanged: (v) => setState(() => areaId = v!),
                  decoration: const InputDecoration(labelText: 'Сфера'),
                ),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Цель'),
                ),
                TextField(
                  controller: targetCtrl,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Целевое значение'),
                ),
                TextField(
                  controller: unitCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Единица (кг, \$…)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );

    if (ok == true && titleCtrl.text.trim().isNotEmpty) {
      await ref.read(repositoryProvider).addGoal(
            lifeAreaId: areaId,
            title: titleCtrl.text.trim(),
            targetValue: double.tryParse(targetCtrl.text.replaceAll(',', '.')),
            unit: unitCtrl.text.trim().isEmpty ? null : unitCtrl.text.trim(),
          );
    }
  }
}

class _GoalCard extends ConsumerWidget {
  const _GoalCard({required this.goal, required this.lifeAreaId});
  final Goal goal;
  final String lifeAreaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = goal.progressRatio;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(goal.title, style: Theme.of(context).textTheme.titleMedium),
            if (goal.targetValue != null) ...[
              const SizedBox(height: 4),
              Text(
                '${goal.currentValue.toStringAsFixed(goal.currentValue == goal.currentValue.roundToDouble() ? 0 : 1)}'
                ' / ${goal.targetValue!.toStringAsFixed(goal.targetValue == goal.targetValue!.roundToDouble() ? 0 : 1)}'
                '${goal.unit != null ? ' ${goal.unit}' : ''}',
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: progress),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => showAddArtifactSheet(
                    context,
                    ref,
                    goalId: goal.id,
                    lifeAreaId: lifeAreaId,
                  ),
                  child: const Text('Артефакт'),
                ),
                if (goal.targetValue != null)
                  TextButton(
                    onPressed: () async {
                      final ctrl = TextEditingController(
                        text: goal.currentValue.toString(),
                      );
                      final v = await showDialog<double>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Прогресс'),
                          content: TextField(
                            controller: ctrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Текущее значение',
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Отмена'),
                            ),
                            FilledButton(
                              onPressed: () {
                                final n = double.tryParse(
                                  ctrl.text.replaceAll(',', '.'),
                                );
                                Navigator.pop(ctx, n);
                              },
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                      if (v != null) {
                        await ref
                            .read(repositoryProvider)
                            .updateGoalProgress(goal.id, v);
                      }
                    },
                    child: const Text('Обновить'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
