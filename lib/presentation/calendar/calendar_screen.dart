import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/models/models.dart';
import '../../domain/rules/two_day.dart';
import '../../services/notification_service.dart';
import '../common/coach_sheet.dart';
import '../common/reflection_sheet.dart';
import '../common/widgets.dart';

const _ruMonths = [
  'Январь',
  'Февраль',
  'Март',
  'Апрель',
  'Май',
  'Июнь',
  'Июль',
  'Август',
  'Сентябрь',
  'Октябрь',
  'Ноябрь',
  'Декабрь',
];

const _ruWeekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _visibleMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedCalendarDateProvider);
    final dateKey = formatLocalDate(selected);
    final plan = ref.watch(dayPlanProvider(dateKey));
    final recovery = ref.watch(recoveryProvider);
    final monthKey =
        '${_visibleMonth.year}-${_visibleMonth.month.toString().padLeft(2, '0')}';
    final markers = ref.watch(calendarMonthProvider(monthKey));

    final isToday = selected == _today;
    final isFuture = selected.isAfter(_today);
    final titleDate = isToday
        ? 'Сегодня'
        : '${selected.day} ${_ruMonths[selected.month - 1].toLowerCase()}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Календарь'),
        actions: [
          if (!isToday)
            TextButton(
              onPressed: () {
                ref.read(selectedCalendarDateProvider.notifier).state = _today;
                setState(() {
                  _visibleMonth = DateTime(_today.year, _today.month);
                });
              },
              child: const Text('Сегодня'),
            ),
          IconButton(
            tooltip: 'Добавить действие',
            onPressed: () => _showAddSheet(context, ref),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // TOP: compact month calendar (intrinsic height, never Expanded)
          Material(
            elevation: 1,
            color: Theme.of(context).colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: markers.when(
                loading: () => const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => SizedBox(
                  height: 80,
                  child: Center(child: Text('Календарь: $e')),
                ),
                data: (map) => _MonthGrid(
                  visibleMonth: _visibleMonth,
                  selected: selected,
                  today: _today,
                  markers: map,
                  onMonthChanged: (m) => setState(() => _visibleMonth = m),
                  onDaySelected: (day) {
                    ref.read(selectedCalendarDateProvider.notifier).state = day;
                  },
                ),
              ),
            ),
          ),
          // BOTTOM: at-risk banner + scrollable day plan for selected date
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              children: [
                recovery.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (items) {
                    if (items.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _AtRiskSection(items: items),
                    );
                  },
                ),
                Text(
                  titleDate,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (isFuture)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 8),
                    child: Text(
                      'Запланированные ежедневные действия',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  )
                else
                  const SizedBox(height: 8),
                plan.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Text('Ошибка: $e'),
                  data: (items) {
                    if (items.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: EmptyState(
                          title: 'Пока пусто',
                          subtitle:
                              'Добавь действия или привычки — или пройди онбординг.',
                          icon: Icons.checklist_rtl,
                        ),
                      );
                    }
                    final actions = items
                        .where((i) => i.subjectType == SubjectType.action)
                        .toList();
                    final habits = items
                        .where((i) => i.subjectType == SubjectType.habit)
                        .toList();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (actions.isNotEmpty) ...[
                          Text(
                            'Действия',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          ...actions.map(
                            (s) => _DayTile(
                              subject: s,
                              localDate: dateKey,
                              allowCheckIn: !isFuture,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (habits.isNotEmpty) ...[
                          Text(
                            'Привычки',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          ...habits.map(
                            (s) => _DayTile(
                              subject: s,
                              localDate: dateKey,
                              allowCheckIn: !isFuture,
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
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

class _AtRiskSection extends ConsumerWidget {
  const _AtRiskSection({required this.items});
  final List<RecoveryItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final warnings =
        items.where((i) => i.twoDay.state == TwoDayState.warning).toList();
    final broken =
        items.where((i) => i.twoDay.state == TwoDayState.broken).toList();
    final scheme = Theme.of(context).colorScheme;

    return Card(
      color: scheme.errorContainer.withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: scheme.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    broken.isNotEmpty
                        ? 'Есть срывы по правилу двух дней'
                        : 'Остался 1 день до срыва',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final i in [...warnings, ...broken])
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${i.title} · ${i.twoDay.missedDays} дн.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    TwoDayBadge(result: i.twoDay),
                  ],
                ),
              ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => showCoachDraft(
                    context,
                    ref,
                    mode: CoachMode.failureCoach,
                  ),
                  child: const Text('Почему выпал?'),
                ),
                FilledButton(
                  onPressed: () async {
                    final today = DateTime.now();
                    final day = DateTime(today.year, today.month, today.day);
                    ref.read(selectedCalendarDateProvider.notifier).state = day;
                    final repo = ref.read(repositoryProvider);
                    for (final i in items) {
                      await repo.checkIn(
                        subjectType: i.subjectType,
                        subjectId: i.id,
                        status: CheckInStatus.done,
                      );
                    }
                    final recovery = await repo.getRecovery();
                    await NotificationService.instance
                        .syncDay2Warnings(recovery);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Отмечено на сегодня')),
                      );
                    }
                  },
                  child: const Text('Вернуться сегодня'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DayTile extends ConsumerWidget {
  const _DayTile({
    required this.subject,
    required this.localDate,
    required this.allowCheckIn,
  });

  final TodaySubject subject;
  final String localDate;
  final bool allowCheckIn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final done = subject.isDone;
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
        onTap: !allowCheckIn
            ? null
            : () async {
                final repo = ref.read(repositoryProvider);
                final next =
                    done ? CheckInStatus.skipped : CheckInStatus.done;
                await repo.checkIn(
                  subjectType: subject.subjectType,
                  subjectId: subject.id,
                  status: next,
                  localDate: localDate,
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

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.visibleMonth,
    required this.selected,
    required this.today,
    required this.markers,
    required this.onMonthChanged,
    required this.onDaySelected,
  });

  final DateTime visibleMonth;
  final DateTime selected;
  final DateTime today;
  final Map<String, CalendarDayMarker> markers;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime> onDaySelected;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(visibleMonth.year, visibleMonth.month, 1);
    final daysInMonth = DateTime(visibleMonth.year, visibleMonth.month + 1, 0)
        .day;
    // Monday = 1 … Sunday = 7 in DateTime.weekday
    final leading = first.weekday - 1;
    final totalCells = ((leading + daysInMonth + 6) ~/ 7) * 7;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Предыдущий месяц',
              onPressed: () => onMonthChanged(
                DateTime(visibleMonth.year, visibleMonth.month - 1),
              ),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                '${_ruMonths[visibleMonth.month - 1]} ${visibleMonth.year}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton(
              tooltip: 'Следующий месяц',
              onPressed: () => onMonthChanged(
                DateTime(visibleMonth.year, visibleMonth.month + 1),
              ),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        Row(
          children: [
            for (final w in _ruWeekdays)
              Expanded(
                child: Center(
                  child: Text(
                    w,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        // Fixed cell height keeps the grid compact on wide desktop windows
        // (default square aspect ratio would grow with width and overflow).
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisExtent: 40,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
          ),
          itemCount: totalCells,
          itemBuilder: (context, index) {
            final dayNum = index - leading + 1;
            if (dayNum < 1 || dayNum > daysInMonth) {
              return const SizedBox.shrink();
            }
            final day = DateTime(visibleMonth.year, visibleMonth.month, dayNum);
            final key = formatLocalDate(day);
            final marker = markers[key];
            final isSelected = day == selected;
            final isToday = day == today;
            return _DayCell(
              day: dayNum,
              isSelected: isSelected,
              isToday: isToday,
              marker: marker,
              onTap: () => onDaySelected(day),
            );
          },
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendDot(color: Colors.green.shade600, label: 'Активность'),
            const SizedBox(width: 12),
            _LegendDot(color: Colors.orange.shade800, label: 'День 2'),
            const SizedBox(width: 12),
            _LegendDot(color: Colors.red.shade700, label: 'Срыв'),
          ],
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isSelected,
    required this.isToday,
    required this.marker,
    required this.onTap,
  });

  final int day;
  final bool isSelected;
  final bool isToday;
  final CalendarDayMarker? marker;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Color? markColor;
    if (marker?.hasBroken == true) {
      markColor = Colors.red.shade700;
    } else if (marker?.hasWarning == true) {
      markColor = Colors.orange.shade800;
    } else if (marker?.hasActivity == true) {
      markColor = Colors.green.shade600;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isSelected
              ? scheme.primaryContainer
              : (isToday ? scheme.secondaryContainer.withValues(alpha: 0.5) : null),
          borderRadius: BorderRadius.circular(8),
          border: isToday && !isSelected
              ? Border.all(color: scheme.primary, width: 1.5)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$day',
              style: TextStyle(
                fontSize: 13,
                fontWeight: isToday || isSelected ? FontWeight.w700 : null,
                color: isSelected ? scheme.onPrimaryContainer : null,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 2),
            SizedBox(
              height: 5,
              child: markColor == null
                  ? null
                  : Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: markColor,
                        shape: BoxShape.circle,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
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
