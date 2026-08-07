# Coach (mentor)

Local-first AI mentor foundation. **No API keys required in MVP.** Live providers are pluggable later.

Related: [ARTIFACTS_AND_REFLECTION.md](ARTIFACTS_AND_REFLECTION.md), [TEMPLATES.md](TEMPLATES.md).

## Modes

| Mode | Purpose | Typical entry |
|------|---------|---------------|
| `goal_decompose` | Break a goal into next actions / habits | Goals |
| `failure_coach` | Soft analysis after slip / two-day break | Recovery — «разобрать срыв» |
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
| `StubCoachProvider` | **NOW** — deterministic structured suggestion from local context (no network) |
| `OpenRouterCoachProvider` / `QwenCoachProvider` | **Later** — HTTP + API key from settings / env |

App wires `CoachProvider` via Riverpod; default = stub.

### Plugging OpenRouter / Qwen later

1. Add dependency (e.g. `http`) and settings fields `coach_provider`, `coach_api_key`, `coach_model`
2. Implement `CoachProvider` that:
   - POSTs system prompt + `jsonEncode(context.toJson())`
   - Asks for **JSON-only** response matching the schema above
   - Validates / falls back to stub on parse failure
3. Document key storage: local settings only; never commit keys
4. Example OpenRouter: `https://openrouter.ai/api/v1/chat/completions` with model id of choice
5. Example Qwen: DashScope / compatible OpenAI endpoint — same interface

Do **not** hard-depend on one vendor in domain code.

## What is implemented now vs later

| Piece | Now | Later |
|-------|-----|-------|
| `CoachContextBuilder` | Yes | Enrich with more stats |
| `StubCoachProvider` | Yes | Keep as offline fallback |
| UI: Recovery «разобрать срыв» | Yes | Richer chat |
| UI: Progress monthly draft | Yes | Yearly + share |
| Live LLM API | No | OpenRouter / Qwen / other |
| Auto-apply suggested actions | No | Confirm sheet → insert actions |
| Streaming / multi-turn chat | No | Optional |

## Privacy

- Local context stays on device for stub
- Future API: send redacted context (no photo paths/bytes by default); user opt-in
