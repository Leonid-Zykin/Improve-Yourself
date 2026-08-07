import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../domain/models/models.dart';
import '../../services/notification_service.dart';
import '../common/coach_sheet.dart';
import '../common/reflection_sheet.dart';
import '../common/widgets.dart';

class RecoveryScreen extends ConsumerWidget {
  const RecoveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recovery = ref.watch(recoveryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Возврат'),
        actions: [
          TextButton(
            onPressed: () => showCoachDraft(
              context,
              ref,
              mode: CoachMode.failureCoach,
            ),
            child: const Text('Разобрать срыв'),
          ),
        ],
      ),
      body: recovery.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Ошибка: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              title: 'Всё спокойно',
              subtitle:
                  'Нет действий с предупреждением или срывом по правилу двух дней.',
              icon: Icons.verified_outlined,
            );
          }

          final warnings =
              items.where((i) => i.twoDay.state == TwoDayState.warning).toList();
          final broken =
              items.where((i) => i.twoDay.state == TwoDayState.broken).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (warnings.isNotEmpty) ...[
                Text('Остался 1 день',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...warnings.map((i) => _RecoveryCard(item: i)),
                const SizedBox(height: 16),
              ],
              if (broken.isNotEmpty) ...[
                Text('Мягкий срыв — вернись сегодня',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...broken.map((i) => _RecoveryCard(item: i)),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _RecoveryCard extends ConsumerWidget {
  const _RecoveryCard({required this.item});
  final RecoveryItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TwoDayBadge(result: item.twoDay),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Пропусков подряд: ${item.twoDay.missedDays}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () async {
                  final repo = ref.read(repositoryProvider);
                  await repo.checkIn(
                    subjectType: item.subjectType,
                    subjectId: item.id,
                    status: CheckInStatus.done,
                  );
                  final recovery = await repo.getRecovery();
                  await NotificationService.instance.syncDay2Warnings(recovery);
                  if (context.mounted) {
                    await maybeOfferReflection(
                      context,
                      ref,
                      subjectType: item.subjectType,
                      subjectId: item.id,
                      status: CheckInStatus.done,
                    );
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Отмечено на сегодня')),
                    );
                    context.go('/today');
                  }
                },
                child: const Text('Вернуться сегодня'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
