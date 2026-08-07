import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/templates/catalog.dart';
import '../../domain/models/enums.dart';

Future<void> showTemplatePicker(BuildContext context, WidgetRef ref) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (ctx, scroll) {
          return ListView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Text(
                'Добавить из шаблона',
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Реалистичные цифры (не toxic hustle). См. docs/TEMPLATES.md',
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              for (final t in TemplateCatalog.templates)
                Card(
                  child: ListTile(
                    title: Text(t.title),
                    subtitle: Text('${t.lifeArea} · ${t.description}'),
                    isThreeLine: true,
                    onTap: () async {
                      await ref.read(repositoryProvider).applyTemplate(t.id);
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Добавлено: ${t.title}')),
                        );
                      }
                    },
                  ),
                ),
            ],
          );
        },
      );
    },
  );
}

Future<void> showCoachDraft(
  BuildContext context,
  WidgetRef ref, {
  required CoachMode mode,
}) async {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );
  try {
    final builder = ref.read(coachContextBuilderProvider);
    final provider = ref.read(coachProvider);
    final ctx = await builder.build(mode: mode);
    final response = await provider.advise(ctx);
    if (!context.mounted) return;
    Navigator.pop(context); // loading
    if (response.warning != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.warning!)),
      );
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetCtx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          builder: (sheetCtx, scroll) {
            return ListView(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Text(
                  response.headline,
                  style: Theme.of(sheetCtx).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(response.summary),
                const SizedBox(height: 12),
                Text('Инсайты', style: Theme.of(sheetCtx).textTheme.titleSmall),
                for (final i in response.insights)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text('• $i'),
                  ),
                const SizedBox(height: 12),
                Text(
                  'Предложения',
                  style: Theme.of(sheetCtx).textTheme.titleSmall,
                ),
                for (final a in response.suggestedActions)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(a.title),
                    subtitle: a.why != null ? Text(a.why!) : null,
                  ),
                const SizedBox(height: 8),
                Text(
                  response.disclaimer,
                  style: Theme.of(sheetCtx).textTheme.bodySmall,
                ),
              ],
            );
          },
        );
      },
    );
  } catch (e) {
    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Коуч недоступен: $e')),
      );
    }
  }
}
