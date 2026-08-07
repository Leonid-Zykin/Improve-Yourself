# Coach (mentor)

Local-first AI mentor. Stub works offline; live OpenRouter is optional via a **user-entered API key in Settings**.

Related: [ARTIFACTS_AND_REFLECTION.md](ARTIFACTS_AND_REFLECTION.md), [TEMPLATES.md](TEMPLATES.md).

## Current status

- Default: **`StubCoachProvider`** — deterministic offline text, no network.
- If an OpenRouter API key is present (Settings or `--dart-define`), Riverpod wires **`OpenRouterCoachProvider`** with stub fallback.
- Key is **not** a GitHub secret and must **never** be committed. Runtime key lives on the device.

## Modes

| Mode | Purpose | Typical entry |
|------|---------|---------------|
| `goal_decompose` | Break a goal into next actions / habits | Goals |
| `failure_coach` | Soft analysis after slip / two-day break | Calendar — «Почему выпал?» |
| `monthly_review` | 30-day draft review | Progress — «месячный обзор — черновик» |
| `yearly_review` | Longer window review (stub-ready) | Progress (later) |

Modes share one context builder + one response JSON shape.

## CoachContextBuilder (NOW)

Pure-ish application service over repository / DB:

1. Choose `mode` + window (default 30d; yearly 365d)
2. Load profile, visions, goals, recovery items, consistency, recent check-in counts
3. Attach recent **artifacts** (metadata only) and **reflections** (non-skipped preferred)
4. Emit `Map` / JSON matching the contract in ARTIFACTS_AND_REFLECTION.md

Context never includes raw photo bytes. Reflections do not affect XP/Consistency; they are context only.

## Structured AI response JSON

Providers must return (or stub) this shape:

```json
{
  "schema_version": 1,
  "mode": "failure_coach",
  "headline": "Короткий заголовок",
  "summary": "2–4 предложения эмпатичного разбора",
  "insights": [ "…", "…" ],
  "suggested_actions": [
    { "title": "Микрошаг на сегодня", "kind": "other", "why": "…" }
  ],
  "reflection_prompts": [ "slip_next" ],
  "tone": "supportive",
  "disclaimer": "Черновик от локального stub-коуча; не медицинский совет."
}
```

UI shows headline, summary, insights, suggested actions. Applying suggested actions to DB is optional / later.

## Provider abstraction

```dart
abstract class CoachProvider {
  Future<CoachResponse> advise(CoachContext context);
}
```

| Implementation | Status |
|----------------|--------|
| `StubCoachProvider` | **NOW** — offline fallback |
| `OpenRouterCoachProvider` | **NOW** — OpenAI-compatible chat completions |

### Provider selection (Riverpod)

```dart
// lib/app/providers.dart
// 1) API key from flutter_secure_storage (Settings; SharedPreferences fallback)
// 2) else optional --dart-define=OPENROUTER_API_KEY=...
// 3) else StubCoachProvider
```

UI path: **Прогресс or Колесо → ⚙ Настройки (`/settings`)** → поле «API-ключ OpenRouter».

Default model id: **`openrouter/free`** (free-model router). User can override in Settings.

On HTTP / parse failure, OpenRouter falls back to stub and shows a Russian snackbar notice.

---

## User settings flow (runtime)

1. Open **Настройки** from the gear on Прогресс or Колесо.
2. Paste OpenRouter key from https://openrouter.ai/keys (obscured field).
3. Optionally set model (default `openrouter/free`).
4. **Сохранить** — key + model persist in `flutter_secure_storage` (falls back to SharedPreferences if needed).
5. Indicator: «Живой коуч» when a key is present, else «Локальный stub».
6. **Очистить ключ** returns to stub.

Developer override (local runs only, not for end users):

```bash
flutter run --dart-define=OPENROUTER_API_KEY=sk-or-...
```

Settings key wins over dart-define when both are set.

**Do not** put the key in GitHub Actions secrets for the mobile runtime, and do not hardcode it in source.

---

## Free / cheap LLM API options (research, 2026)

For a Flutter **local-first** coach: real HTTP API, Russian-capable models, **no hardcoded keys** in the binary.

### Comparison (MVP-oriented)

| Provider | Free / cheap | Limits (approx.) | Auth | Russian | Recommended model id | Fit for CoachProvider |
|----------|--------------|------------------|------|---------|----------------------|------------------------|
| **OpenRouter** | 20+ `:free` models, $0 tokens | ~20 RPM; **50 RPD** free account, **1000 RPD** after ≥$10 credits ever purchased | Bearer API key | Good if model is multilingual (Gemma / Nemotron / gpt-oss); free catalog churns | `openrouter/free` (router) or pin a live `:free` id from [openrouter.ai/models](https://openrouter.ai/models) | **Wired in MVP** — one OpenAI-compatible endpoint |
| **Groq** | Free tier, no card | Per-model RPM/RPD | Bearer | Solid with Llama / Qwen | `llama-3.3-70b-versatile` | Optional later |
| **Google Gemini** | Free AI Studio tier | Check AI Studio limits | API key | Strong multilingual | Flash-class id | Optional later |

Sources: [OpenRouter free router](https://openrouter.ai/docs/guides/routing/routers/free-router), [OpenRouter limits](https://openrouter.ai/docs/api/reference/limits).

Coach usage is low volume (a few calls per day), so OpenRouter’s 50 RPD free cap is enough for a solo MVP.

### OpenRouter request

```http
POST https://openrouter.ai/api/v1/chat/completions
Authorization: Bearer <USER_KEY>
Content-Type: application/json
HTTP-Referer: https://github.com/improve-yourself/app
X-Title: Improve Yourself

{
  "model": "openrouter/free",
  "response_format": { "type": "json_object" },
  "messages": [
    { "role": "system", "content": "…" },
    { "role": "user", "content": "<CoachContext JSON>" }
  ]
}
```

## Platform notes

| Platform | Storage | Caveat |
|----------|---------|--------|
| Android | `flutter_secure_storage` (EncryptedSharedPreferences) | Needs `INTERNET` permission (declared) |
| iOS / macOS | Keychain | Standard plugin setup |
| Linux desktop | libsecret via `flutter_secure_storage` | Build needs `libsecret-1-dev`; runtime needs Secret Service. Falls back to SharedPreferences if secure storage fails |

Prefer secure storage over plain SharedPreferences for API keys.

## Privacy

- Stub: context stays on device
- Live OpenRouter: redacted CoachContext JSON (no photo bytes) is sent to the model; user opts in by pasting a key
- Prefer providers / plans that do not train on API data when possible — check current ToS
