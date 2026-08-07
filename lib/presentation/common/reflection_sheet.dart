import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/models/enums.dart';
import '../../domain/reflection/prompts.dart';

/// Soft reflection bottom sheet — Skip / Save.
Future<void> showReflectionSheet(
  BuildContext context,
  WidgetRef ref, {
  required ReflectionPrompt prompt,
  required ReflectionTrigger trigger,
  required SubjectType subjectType,
  required String subjectId,
  ActionKind? actionKind,
}) async {
  final answerCtrl = TextEditingController();
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      final bottom = MediaQuery.viewInsetsOf(ctx).bottom;
      return Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Короткий вопрос',
              style: Theme.of(ctx).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(prompt.text),
            const SizedBox(height: 12),
            TextField(
              controller: answerCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Можно коротко…',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton(
                  onPressed: () async {
                    await ref.read(repositoryProvider).saveReflection(
                          promptKey: prompt.key,
                          promptText: prompt.text,
                          trigger: trigger,
                          skipped: true,
                          subjectType: subjectType,
                          subjectId: subjectId,
                          actionKind: actionKind,
                        );
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Пропустить'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () async {
                    await ref.read(repositoryProvider).saveReflection(
                          promptKey: prompt.key,
                          promptText: prompt.text,
                          trigger: trigger,
                          answer: answerCtrl.text.trim().isEmpty
                              ? null
                              : answerCtrl.text.trim(),
                          skipped: false,
                          subjectType: subjectType,
                          subjectId: subjectId,
                          actionKind: actionKind,
                        );
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Сохранить'),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
  answerCtrl.dispose();
}

Future<void> maybeOfferReflection(
  BuildContext context,
  WidgetRef ref, {
  required SubjectType subjectType,
  required String subjectId,
  required CheckInStatus status,
}) async {
  final repo = ref.read(repositoryProvider);
  final offer = await repo.shouldOfferReflection(
    subjectType: subjectType,
    subjectId: subjectId,
    status: status,
  );
  if (!offer || !context.mounted) return;
  final prompt = await repo.reflectionPromptFor(
    subjectType: subjectType,
    subjectId: subjectId,
  );
  if (prompt == null || !context.mounted) return;

  ActionKind? actionKind;
  final ReflectionTrigger trigger;
  if (subjectType == SubjectType.action) {
    trigger = ReflectionTrigger.actionKind;
    final plan = await repo.getTodayPlan();
    if (!context.mounted) return;
    actionKind = plan
        .where((s) => s.id == subjectId && s.subjectType == SubjectType.action)
        .map((s) => s.actionKind)
        .firstOrNull;
  } else {
    trigger = ReflectionTrigger.badHabitSlip;
  }

  if (!context.mounted) return;
  await showReflectionSheet(
    context,
    ref,
    prompt: prompt,
    trigger: trigger,
    subjectType: subjectType,
    subjectId: subjectId,
    actionKind: actionKind,
  );
}
