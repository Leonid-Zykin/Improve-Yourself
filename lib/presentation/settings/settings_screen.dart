import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../services/settings/coach_settings_store.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _keyController = TextEditingController();
  final _modelController = TextEditingController();
  var _obscure = true;
  var _saving = false;
  var _loaded = false;

  @override
  void dispose() {
    _keyController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  void _hydrate(CoachSettings settings) {
    if (_loaded) return;
    _loaded = true;
    _keyController.text = settings.apiKey ?? '';
    _modelController.text = settings.modelId;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final store = ref.read(coachSettingsStoreProvider);
      final model = _modelController.text.trim().isEmpty
          ? CoachSettingsStore.defaultModelId
          : _modelController.text.trim();
      await store.save(
        apiKey: _keyController.text,
        modelId: model,
      );
      ref.invalidate(coachSettingsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Настройки коуча сохранены')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось сохранить: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _clearKey() async {
    setState(() => _saving = true);
    try {
      final store = ref.read(coachSettingsStoreProvider);
      await store.clearApiKey();
      _keyController.clear();
      ref.invalidate(coachSettingsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ключ удалён. Коуч снова stub.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось очистить: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(coachSettingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Не удалось загрузить настройки: $e\n'
              'На Linux нужен libsecret (пакет libsecret-1-dev для сборки).',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (settings) {
          _hydrate(settings);
          final live = ref.watch(coachIsLiveProvider);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Коуч (OpenRouter)', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Ключ хранится только на устройстве. Получите ключ на '
                'https://openrouter.ai/keys — там же есть бесплатные модели (:free).',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(
                      const ClipboardData(text: 'https://openrouter.ai/keys'),
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ссылка скопирована')),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Скопировать ссылку на ключи'),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: Icon(
                    live ? Icons.bolt : Icons.offline_bolt_outlined,
                    color: live
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                  ),
                  title: Text(live ? 'Живой коуч' : 'Локальный stub'),
                  subtitle: Text(
                    live
                        ? 'Ключ задан — ответы через OpenRouter'
                        : 'Без ключа — офлайн-черновик без сети',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _keyController,
                obscureText: _obscure,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  labelText: 'API-ключ OpenRouter',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    tooltip: _obscure ? 'Показать' : 'Скрыть',
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure ? Icons.visibility : Icons.visibility_off,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _modelController,
                decoration: const InputDecoration(
                  labelText: 'Модель',
                  hintText: CoachSettingsStore.defaultModelId,
                  helperText:
                      'По умолчанию openrouter/free — роутер бесплатных моделей',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('Сохранить'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _saving ? null : _clearKey,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Очистить ключ'),
              ),
            ],
          );
        },
      ),
    );
  }
}
