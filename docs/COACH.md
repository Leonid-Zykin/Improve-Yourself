# Coach (mentor)

Local-first AI mentor foundation. **No API keys required in MVP.** Live providers are pluggable later.

Related: [ARTIFACTS_AND_REFLECTION.md](ARTIFACTS_AND_REFLECTION.md), [TEMPLATES.md](TEMPLATES.md).

## Current status (important)

- The app ships **`StubCoachProvider`** only — deterministic offline text, **no network**.
- Riverpod wires `coachProvider` → `StubCoachProvider` in `lib/app/providers.dart`.
- Yellow/black Flutter debug stripes on Calendar are **layout overflow**, not a coach/design feature.

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
| `StubCoachProvider` | **NOW** — deterministic structured suggestion from local context (no network) |
| `OpenRouterCoachProvider` / `HttpCoachProvider` | **Planned** — see integration plan below |

App wires `CoachProvider` via Riverpod; default = stub.

---

## Free / cheap LLM API options (research, 2026)

For a Flutter **local-first** coach (goal decompose, failure coach, monthly review): need a real HTTP API, Russian-capable models, and **no hardcoded API keys** in the mobile binary.

**Key safety rule:** never ship a secret in the client. Prefer (1) user-pasted key in local settings / secure storage, (2) `--dart-define=COACH_API_KEY=…` for personal builds, or (3) a tiny authenticated proxy you control. Direct mobile → provider CORS is usually fine for native apps; web builds may need a proxy.

### Comparison (MVP-oriented)

| Provider | Free / cheap | Limits (approx.) | Auth | Russian | Recommended model id | Fit for CoachProvider |
|----------|--------------|------------------|------|---------|----------------------|------------------------|
| **OpenRouter** | 20+ `:free` models, $0 tokens | ~20 RPM; **50 RPD** free account, **1000 RPD** after ≥$10 credits ever purchased | Bearer API key | Good if model is multilingual (Gemma / Nemotron / gpt-oss); free catalog churns | `openrouter/free` (router) or pin a live `:free` id from [openrouter.ai/models](https://openrouter.ai/models) | **Best MVP glue** — one OpenAI-compatible endpoint, swap models without code changes |
| **Groq** | Free tier, no card | Per-model; e.g. Llama 3.3 70B ~30 RPM / ~1k RPD; Llama 3.1 8B more generous | Bearer key → `https://api.groq.com/openai/v1` | Solid for RU with Llama / Qwen | `llama-3.3-70b-versatile` or `qwen/qwen3-32b` | Excellent speed; good secondary / direct option |
| **Google Gemini** | Free AI Studio tier | Flash-class often ~10–15 RPM, hundreds–~1500 RPD (check [AI Studio rate limits](https://aistudio.google.com/rate-limit); values change) | API key | Strong multilingual / RU | `gemini-2.5-flash` or current Flash id | Generous for personal use; free-tier prompts may be used for training |
| **DeepSeek** | Cheap + signup credits (not always unlimited free) | Pay-as-you-go after credits; concurrency varies | Bearer → `https://api.deepseek.com` | Strong RU/CJK | `deepseek-chat` (check current id on platform) | Great quality/$ when paid; not ideal as “forever free” |
| **Together / Fireworks** | Trial credits ($1–small); rarely long free | Card often required | OpenAI-compatible | Depends on hosted model (Qwen good for RU) | Qwen3 / Llama variants on each console | Better as paid fallback than free MVP |
| **Hugging Face Inference** | Free/community rate-limited | Shared / cold starts | HF token | Via model choice (Qwen etc.) | Serverless endpoint for a Qwen instruct model | Fragile for product UX; OK for experiments |
| **Mistral** | Limited experiment / free trial | Card / verification common | API key | Decent EU multilingual | `mistral-small-latest` | Secondary |
| **Qwen (DashScope / Alibaba)** | Region + trial dependent | Not a stable global free HTTP tier | DashScope key | **Best native RU/CJK quality** among open families | DashScope chat model or Qwen via Groq/OpenRouter | Prefer Qwen **via Groq or OpenRouter** for simpler western signup |

Sources (limits change): [OpenRouter free router](https://openrouter.ai/docs/guides/routing/routers/free-router), [OpenRouter limits](https://openrouter.ai/docs/api/reference/limits), [Gemini rate limits](https://ai.google.dev/gemini-api/docs/rate-limits), Groq console limits, provider pricing pages. Always re-check live quotas before shipping.

### Best pick for MVP

**OpenRouter + free router / a pinned `:free` model**, with **StubCoachProvider fallback**:

1. Single base URL: `https://openrouter.ai/api/v1/chat/completions`
2. Model: `openrouter/free` (auto-picks a free model) — or pin e.g. `google/gemma-*-it:free` / `openai/gpt-oss-20b:free` after checking the live catalog
3. User supplies API key in settings (or dart-define for personal builds)
4. On missing key, 429, or parse failure → fall back to `StubCoachProvider`
5. Optional later: Groq as speed path; Gemini as high free RPD; DeepSeek/Qwen when quality matters more than $0

Coach usage is low volume (a few calls per day per user), so OpenRouter’s 50 RPD free cap is enough for a solo MVP.

---

## Integration plan (not wired yet)

Live HTTP provider was **not** added in code (no `http` dependency / settings UI yet). When implementing:

1. Add `http` (or `dio`) dependency.
2. Settings fields: `coach_provider` (`stub` \| `openrouter` \| `groq` \| `gemini`), `coach_api_key`, `coach_model`.
3. Implement `OpenRouterCoachProvider implements CoachProvider`:
   - System prompt: supportive Russian coach; **JSON-only** matching the schema above; no medical advice.
   - User message: `jsonEncode(context.toJson())`.
   - Parse `choices[0].message.content` (strip markdown fences if needed) → `CoachResponse`.
   - On failure: rethrow or delegate to `StubCoachProvider`.
4. Wire in `lib/app/providers.dart`:

```dart
final coachProvider = Provider<CoachProvider>((ref) {
  final key = /* settings or String.fromEnvironment('COACH_API_KEY') */;
  if (key == null || key.isEmpty) return StubCoachProvider();
  return OpenRouterCoachProvider(
    apiKey: key,
    model: 'openrouter/free',
    fallback: StubCoachProvider(),
  );
});
```

5. Never commit keys. Prefer local secure storage for user-entered keys; thin backend proxy if you later need shared quotas without exposing keys.
6. Do **not** hard-depend on one vendor in domain code — keep `CoachProvider` abstract.

### Example OpenRouter request shape

```http
POST https://openrouter.ai/api/v1/chat/completions
Authorization: Bearer <USER_KEY>
Content-Type: application/json

{
  "model": "openrouter/free",
  "response_format": { "type": "json_object" },
  "messages": [
    { "role": "system", "content": "…" },
    { "role": "user", "content": "<CoachContext JSON>" }
  ]
}
```

## What is implemented now vs later

| Piece | Now | Later |
|-------|-----|-------|
| `CoachContextBuilder` | Yes | Enrich with more stats |
| `StubCoachProvider` | Yes | Keep as offline fallback |
| UI: Calendar «Почему выпал?» | Yes | Richer chat |
| UI: Progress monthly draft | Yes | Yearly + share |
| Live LLM API | No | OpenRouter first, then Groq/Gemini |
| Auto-apply suggested actions | No | Confirm sheet → insert actions |
| Streaming / multi-turn chat | No | Optional |

## Privacy

- Local context stays on device for stub
- Future API: send redacted context (no photo paths/bytes by default); user opt-in
- Prefer providers that do not train on API data when possible (Groq / OpenRouter paid paths; Gemini free tier may use prompts for training — check current ToS)
