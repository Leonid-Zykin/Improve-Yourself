import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../app/providers.dart';
import '../../domain/models/models.dart';
import '../../services/photo_store.dart';

Future<void> showAddArtifactSheet(
  BuildContext context,
  WidgetRef ref, {
  String? goalId,
  String? lifeAreaId,
  String? actionId,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _AddArtifactSheet(
      goalId: goalId,
      lifeAreaId: lifeAreaId,
      actionId: actionId,
    ),
  );
}

class _AddArtifactSheet extends ConsumerStatefulWidget {
  const _AddArtifactSheet({
    this.goalId,
    this.lifeAreaId,
    this.actionId,
  });

  final String? goalId;
  final String? lifeAreaId;
  final String? actionId;

  @override
  ConsumerState<_AddArtifactSheet> createState() => _AddArtifactSheetState();
}

class _AddArtifactSheetState extends ConsumerState<_AddArtifactSheet> {
  var _type = ArtifactType.genericNote;
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _metric = TextEditingController();
  final _unit = TextEditingController();
  String? _pickedPath;
  var _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _metric.dispose();
    _unit.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file != null) setState(() => _pickedPath = file.path);
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      final repo = ref.read(repositoryProvider);
      String? localPath;
      if (_type == ArtifactType.photo) {
        if (_pickedPath == null) return;
        final id = const Uuid().v4();
        localPath = await PhotoStore().savePhoto(
          id: id,
          sourcePath: _pickedPath!,
        );
      }
      await repo.addArtifact(
        type: _type,
        title: _title.text.trim().isEmpty ? null : _title.text.trim(),
        body: _body.text.trim().isEmpty ? null : _body.text.trim(),
        metricValue: double.tryParse(_metric.text.replaceAll(',', '.')),
        metricUnit: _unit.text.trim().isEmpty ? null : _unit.text.trim(),
        localPath: localPath,
        goalId: widget.goalId,
        lifeAreaId: widget.lifeAreaId,
        actionId: widget.actionId,
      );
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Артефакт', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            DropdownButtonFormField<ArtifactType>(
              // ignore: deprecated_member_use
              value: _type,
              items: [
                for (final t in ArtifactType.values)
                  DropdownMenuItem(
                    value: t,
                    child: Text(t.dbValue),
                  ),
              ],
              onChanged: (v) => setState(() => _type = v ?? _type),
              decoration: const InputDecoration(labelText: 'Тип'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Заголовок'),
            ),
            if (_type == ArtifactType.photo) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickPhoto,
                icon: const Icon(Icons.photo),
                label: Text(
                  _pickedPath == null ? 'Выбрать фото' : 'Фото выбрано',
                ),
              ),
              if (_pickedPath != null) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(_pickedPath!),
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ] else if (_type == ArtifactType.metric) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _metric,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Значение'),
              ),
              TextField(
                controller: _unit,
                decoration: const InputDecoration(labelText: 'Единица'),
              ),
            ] else ...[
              const SizedBox(height: 8),
              TextField(
                controller: _body,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Текст'),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }
}

class ArtifactsTimeline extends ConsumerWidget {
  const ArtifactsTimeline({super.key, this.goalId, this.limit = 20});

  final String? goalId;
  final int limit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artifacts = ref.watch(artifactsProvider(goalId));
    return artifacts.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Ошибка: $e'),
      data: (list) {
        final items = list.take(limit).toList();
        if (items.isEmpty) {
          return Text(
            'Пока нет артефактов',
            style: Theme.of(context).textTheme.bodySmall,
          );
        }
        return Column(
          children: [
            for (final a in items) _ArtifactTile(artifact: a),
          ],
        );
      },
    );
  }
}

class _ArtifactTile extends StatelessWidget {
  const _ArtifactTile({required this.artifact});
  final Artifact artifact;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        dense: true,
        leading: Icon(switch (artifact.type) {
          ArtifactType.photo => Icons.photo,
          ArtifactType.metric => Icons.straighten,
          ArtifactType.dailyLog => Icons.notes,
          ArtifactType.chapterNote => Icons.menu_book,
          ArtifactType.genericNote => Icons.sticky_note_2_outlined,
        }),
        title: Text(
          artifact.title ??
              (artifact.metricValue != null
                  ? '${artifact.metricValue} ${artifact.metricUnit ?? ''}'
                  : artifact.type.dbValue),
        ),
        subtitle: Text(
          [
            artifact.localDate,
            if (artifact.body != null && artifact.body!.isNotEmpty)
              artifact.body!,
          ].join(' · '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: artifact.localPath != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.file(
                  File(artifact.localPath!),
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Icon(Icons.broken_image),
                ),
              )
            : null,
      ),
    );
  }
}
