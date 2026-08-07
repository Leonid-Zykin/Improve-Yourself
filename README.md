# Improve Yourself

Local-first Flutter app for self-improvement around **life areas → goals → actions**, with the **two-day rule**, Consistency Score, and XP. No backend in the MVP.

App id: `com.improveyourself.app`

## Requirements

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.22+ / Dart 3)
- A device/emulator, or Chrome for web smoke tests

If Flutter is installed elsewhere (e.g. `~/flutter`), ensure it is on your `PATH`:

```bash
export PATH="$PATH:$HOME/flutter/bin"
```

## Run

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # Drift codegen
flutter run
```

Useful targets:

```bash
flutter run -d chrome    # web
flutter run -d linux     # needs desktop toolchain + libsecret-1-dev
```

Linux desktop (OpenRouter settings / secure storage):

```bash
sudo apt-get install -y libsecret-1-dev
```

## Test

```bash
flutter test
flutter analyze
```

## Project layout

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for layers, domain rules, and the sync-contract notes.

Product specs:

- [docs/ARTIFACTS_AND_REFLECTION.md](docs/ARTIFACTS_AND_REFLECTION.md) — artifacts, reflections, anti-nag
- [docs/TEMPLATES.md](docs/TEMPLATES.md) — goal templates + onboarding presets
- [docs/COACH.md](docs/COACH.md) — mentor modes, context JSON, stub vs live API

```
lib/
  domain/          # models + two-day / XP / consistency / wheel / reflection
  data/db/         # Drift schema + seed life areas
  data/templates/  # goal template catalog
  data/repositories/
  services/        # notifications, photo store, coach providers
  presentation/    # Calendar, Wheel, Goals, Progress, Settings, Onboarding
  app/             # theme, router, providers
```

### Live coach (optional)

Enter an OpenRouter API key in-app: **Прогресс / Колесо → ⚙ → Настройки**. Key stays on device. See [docs/COACH.md](docs/COACH.md).

```bash
# optional developer override
flutter run --dart-define=OPENROUTER_API_KEY=sk-or-...
```
