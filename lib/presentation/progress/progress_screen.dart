import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/providers.dart';
import '../../domain/models/models.dart';
import '../common/coach_sheet.dart';
import '../common/widgets.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final series = ref.watch(progressSeriesProvider);
    final consistency = ref.watch(consistencyProvider);
    final wheel = ref.watch(wheelProvider);
    final areas = ref.watch(lifeAreasProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Прогресс'),
        actions: [
          IconButton(
            tooltip: 'Настройки',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
          IconButton(
            tooltip: 'Месячный обзор — черновик',
            icon: const Icon(Icons.psychology_outlined),
            onPressed: () => showCoachDraft(
              context,
              ref,
              mode: CoachMode.monthlyReview,
            ),
          ),
          IconButton(
            tooltip: 'Экспорт JSON',
            icon: const Icon(Icons.ios_share),
            onPressed: () => _exportBackup(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          OutlinedButton.icon(
            onPressed: () => showCoachDraft(
              context,
              ref,
              mode: CoachMode.monthlyReview,
            ),
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Месячный обзор — черновик'),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Consistency (30д)',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    '${((consistency.asData?.value ?? 0) * 100).round()}%',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Активность 30 дней',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SizedBox(
            height: 140,
            child: series.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('$e'),
              data: (points) => _Bars(points: points),
            ),
          ),
          const SizedBox(height: 24),
          Text('XP по сферам', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ..._xpRows(wheel.asData?.value ?? [], areas.asData?.value ?? []),
        ],
      ),
    );
  }

  List<Widget> _xpRows(List<WheelSlice> slices, List<LifeArea> areas) {
    if (slices.isEmpty) {
      return [
        const EmptyState(title: 'Пока нет XP', icon: Icons.star_outline),
      ];
    }
    return slices
        .map(
          (s) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(iconForArea(s.lifeArea.icon),
                  color: Color(s.lifeArea.color)),
              title: Text(s.lifeArea.title),
              subtitle: Text('Уровень ${s.level}'),
              trailing: Text(
                '${s.xp} XP',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        )
        .toList();
  }

  Future<void> _exportBackup(BuildContext context, WidgetRef ref) async {
    try {
      final data = await ref.read(repositoryProvider).exportBackupJson();
      final dir = await getTemporaryDirectory();
      final file = File(
        p.join(
          dir.path,
          'improve_yourself_backup_${DateTime.now().millisecondsSinceEpoch}.json',
        ),
      );
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(data),
      );
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'Improve Yourself backup',
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось экспортировать: $e')),
        );
      }
    }
  }
}

class _Bars extends StatelessWidget {
  const _Bars({required this.points});
  final List<ProgressPoint> points;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final p in points)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: FractionallySizedBox(
                heightFactor: (p.ratio * 0.9 + 0.05).clamp(0.05, 1.0),
                alignment: Alignment.bottomCenter,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(
                          alpha: 0.35 + p.ratio * 0.65,
                        ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
