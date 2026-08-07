import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/models/models.dart';
import '../../services/notification_service.dart';
import '../common/reflection_sheet.dart';
import '../common/widgets.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(todayPlanProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Сегодня'),
        actions: [
          IconButton(
            tooltip: 'Добавить действие',
            onPressed: () => _showAddSheet(context, ref),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: plan.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Ошибка: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              title: 'Пока пусто',
              subtitle:
                  'Добавь действия или привычки — или пройди онбординг заново через цели.',
              icon: Icons.checklist_rtl,
            );
          }

          final actions =
              items.where((i) => i.subjectType == SubjectType.action).toList();
          final habits =
              items.where((i) => i.subjectType == SubjectType.habit).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              if (actions.isNotEmpty) ...[
                Text('Действия', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...actions.map((s) => _TodayTile(subject: s)),
                const SizedBox(height: 16),
              ],
              if (habits.isNotEmpty) ...[
                Text('Привычки', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...habits.map((s) => _TodayTile(subject: s)),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _showAddSheet(BuildContext context, WidgetRef ref) async {
    final areas = await ref.read(repositoryProvider).getLifeAreas();
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _AddSubjectSheet(areas: areas),
    );
  }
}

class _TodayTile extends ConsumerWidget {
  const _TodayTile({required this.subject});

  final TodaySubject subject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final done = subject.isDoneToday;
    final isBad = subject.habitKind == HabitKind.bad;
    final kindLabel = subject.actionKind != null &&
            subject.actionKind != ActionKind.other
        ? ' · ${subject.actionKind!.name}'
        : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          done
              ? Icons.check_circle
              : (isBad ? Icons.warning_amber : Icons.circle_outlined),
          color: done
              ? (isBad ? Colors.red : Colors.green)
              : Theme.of(context).colorScheme.outline,
        ),
        title: Text(
          subject.title,
          style: TextStyle(
            decoration: done ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          isBad
              ? 'Плохая привычка · ${subject.xp} XP при срыве'
              : '+${subject.xp} XP$kindLabel',
        ),
        trailing: TwoDayBadge(result: subject.twoDay),
        onTap: () async {
          final repo = ref.read(repositoryProvider);
          final next = done ? CheckInStatus.skipped : CheckInStatus.done;
          await repo.checkIn(
            subjectType: subject.subjectType,
            subjectId: subject.id,
            status: next,
          );
          final recovery = await repo.getRecovery();
          await NotificationService.instance.syncDay2Warnings(recovery);
          if (!context.mounted) return;
          if (next == CheckInStatus.done) {
            await maybeOfferReflection(
              context,
              ref,
              subjectType: subject.subjectType,
              subjectId: subject.id,
              status: next,
            );
          }
        },
      ),
    );
  }
}

class _AddSubjectSheet extends ConsumerStatefulWidget {
  const _AddSubjectSheet({required this.areas});
  final List<LifeArea> areas;

  @override
  ConsumerState<_AddSubjectSheet> createState() => _AddSubjectSheetState();
}

class _AddSubjectSheetState extends ConsumerState<_AddSubjectSheet> {
  final _title = TextEditingController();
  var _isHabit = false;
  var _bad = false;
  String? _areaId;
  var _kind = ActionKind.other;

  @override
  void initState() {
    super.initState();
    _areaId = widget.areas.isNotEmpty ? widget.areas.first.id : null;
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Добавить', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Действие')),
              ButtonSegment(value: true, label: Text('Привычка')),
            ],
            selected: {_isHabit},
            onSelectionChanged: (s) => setState(() => _isHabit = s.first),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Название'),
            autofocus: true,
          ),
          const SizedBox(height: 12),
          if (!_isHabit && widget.areas.isNotEmpty)
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _areaId,
              items: widget.areas
                  .map((a) =>
                      DropdownMenuItem(value: a.id, child: Text(a.title)))
                  .toList(),
              onChanged: (v) => setState(() => _areaId = v),
              decoration: const InputDecoration(labelText: 'Сфера'),
            ),
          if (!_isHabit) ...[
            const SizedBox(height: 8),
            DropdownButtonFormField<ActionKind>(
              // ignore: deprecated_member_use
              value: _kind,
              items: [
                for (final k in ActionKind.values)
                  DropdownMenuItem(value: k, child: Text(k.name)),
              ],
              onChanged: (v) => setState(() => _kind = v ?? _kind),
              decoration: const InputDecoration(labelText: 'Kind (рефлексия)'),
            ),
          ],
          if (_isHabit)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Плохая привычка'),
              value: _bad,
              onChanged: (v) => setState(() => _bad = v),
            ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              final title = _title.text.trim();
              if (title.isEmpty) return;
              final repo = ref.read(repositoryProvider);
              if (_isHabit) {
                final areaIds = widget.areas.map((a) => a.id).toList();
                await repo.addHabit(
                  title: title,
                  kind: _bad ? HabitKind.bad : HabitKind.good,
                  lifeAreaIds: areaIds.isEmpty ? [] : [areaIds.first],
                );
              } else if (_areaId != null) {
                await repo.addAction(
                  lifeAreaId: _areaId!,
                  title: title,
                  kind: _kind,
                );
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }
}
