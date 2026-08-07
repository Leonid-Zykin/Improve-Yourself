# Artifacts & Reflection

Evidence and soft self-check for Improve Yourself. Local-first; no backend.

## Locked product decisions

| Decision | Rule |
|----------|------|
| When to reflect | Only after actions with a reflective `kind`, or after a **bad-habit slip** — not every check-in |
| Photos | App documents + optional thumbnails; **no cloud** |
| Identities | Stay as Vision strings for now |
| XP / Consistency | Do **not** depend on reflections or artifacts |

## Artifact

Evidence attached to a goal, life area, action, and/or check-in.

### Fields

| Field | Type | Notes |
|-------|------|-------|
| `id` | UUID | Primary key |
| `type` | enum | See types below |
| `title` | string? | Short label |
| `body` | string? | Note / log / chapter text |
| `metric_value` | double? | For `metric` |
| `metric_unit` | string? | e.g. `кг`, `стр`, `$` |
| `local_path` | string? | Full photo under app documents |
| `thumbnail_path` | string? | Optional smaller copy |
| `goal_id` | UUID? | Optional link |
| `life_area_id` | UUID? | Optional link |
| `action_id` | UUID? | Optional link |
| `check_in_id` | UUID? | Optional link |
| `local_date` | `YYYY-MM-DD` | Local calendar day |
| `created_at` | datetime | UTC |
| `updated_at` | datetime | UTC |
| `deleted_at` | datetime? | Soft delete |
| `sync_status` | string | `pending` / `synced` / `conflict` (contract only) |

### Types (MVP)

| `type` | Use |
|--------|-----|
| `photo` | Progress / form / workspace photo (local file) |
| `metric` | Weight, savings balance, pages, sleep hours, etc. |
| `daily_log` | Short work / study day log |
| `chapter_note` | Reading: chapter / takeaway |
| `generic_note` | Free-form note |

### Where users add artifacts

1. **Goals** — per-goal / area timeline + “добавить артефакт”
2. **After check-in** — soft suggestion when action `kind` implies evidence (workout photo, pages read, job log…)
3. **Manual** from Goals / Calendar suggestion sheet

Photos are copied into `{appDocuments}/artifacts/{id}.jpg` (and optional `…_thumb.jpg`). Never uploaded.

---

## Reflection

Optional soft prompt after a meaningful event. Answers are stored for coach context; they never change XP or Consistency.

### Fields

| Field | Type | Notes |
|-------|------|-------|
| `id` | UUID | |
| `prompt_key` | string | Stable key from catalog |
| `prompt_text` | string | Snapshot of text shown (locale-safe) |
| `answer` | string? | Null if skipped |
| `trigger` | enum | `action_kind` \| `bad_habit_slip` \| `manual` |
| `subject_type` | `action` \| `habit` \| null | |
| `subject_id` | UUID? | |
| `action_kind` | string? | Copied from action when relevant |
| `check_in_id` | UUID? | |
| `skipped` | bool | User tapped Skip |
| `local_date` | `YYYY-MM-DD` | |
| `created_at` / `updated_at` / `deleted_at` / `sync_status` | | Same sync contract as other tables |

### When to ask (auto)

Show a soft bottom sheet **after** a successful check-in when:

1. **Action with reflective kind** — `workout`, `reading`, `career`, `study`, `language` (not `other`), status `done`; **or**
2. **Bad-habit slip** — habit `kind=bad`, status `done` (user logged a slip).

Do **not** ask for:

- Skip / undo of a check-in
- Good habits without a reflective action kind
- Actions with `kind=other` (unless later product changes)

### Anti-nag (MVP)

| Rule | Default |
|------|---------|
| Max auto reflections per local day | **3** (saved or skipped both count) |
| Soft UI | Bottom sheet, Skip primary-secondary; never blocking dialog |
| Settings | `max_auto_reflections_per_day`, `reflections_enabled` on settings row |

XP/Consistency calculation must ignore reflection rows entirely.

### Prompt catalog (keys)

| `prompt_key` | Typical trigger | Example copy (RU) |
|--------------|-----------------|-------------------|
| `workout_feel` | workout done | Как прошла тренировка? Что было тяжело? |
| `reading_takeaway` | reading done | Одна мысль из прочитанного? |
| `career_blocker` | career done | Что мешало / что сдвинуло поиск вперёд? |
| `study_focus` | study done | Сколько минут реально в фокусе? |
| `language_practice` | language done | Что практиковал(а): speaking / listening / vocab? |
| `slip_trigger` | bad habit slip | Что было триггером срыва? |
| `slip_next` | bad habit slip | Что поможет в следующий раз (микрошаг)? |

Catalog lives in code (`lib/domain/reflection/prompts.dart`); templates may reference keys.

---

## CoachContext JSON (contract)

Built locally by `CoachContextBuilder` (see [COACH.md](COACH.md)). Minimal shape:

```json
{
  "schema_version": 1,
  "mode": "failure_coach",
  "generated_at": "2026-08-07T21:00:00Z",
  "window": { "from": "2026-07-08", "to": "2026-08-07", "days": 30 },
  "profile": { "display_name": "Я", "timezone": "…" },
  "visions": ["…"],
  "stats": {
    "consistency_30d": 0.62,
    "recovery_warning": 1,
    "recovery_broken": 0,
    "check_ins_done": 40,
    "bad_habit_slips": 2
  },
  "goals": [ { "id": "…", "title": "…", "life_area_key": "health", "progress": 0.4 } ],
  "failures": [ { "subject_id": "…", "title": "…", "missed_days": 3, "state": "broken" } ],
  "artifacts": [ { "id": "…", "type": "metric", "title": "Вес", "metric_value": 78.2, "local_date": "…" } ],
  "reflections": [ { "prompt_key": "slip_trigger", "answer": "…", "local_date": "…", "skipped": false } ]
}
```

Artifacts in context include metadata only — **no raw photo bytes**. Paths may be omitted for privacy when sending to a future API.

---

## MVP slice (implemented)

- Drift tables `artifacts`, `reflections`; `actions.kind`
- Prompt catalog + anti-nag (max 3/day)
- Soft reflection sheet after qualifying check-ins
- Artifact types above; add from Goals; photo pick → local documents
- Simple artifact timeline on Goals
- Coach stub consumes real local context (see COACH.md)

### Deferred

- Cloud photo sync / CDN
- Rich identity model beyond Vision strings
- Reflection → XP / Consistency coupling (explicitly out of scope)
- Full-screen reflection journal UI
- Image compression / gallery browser polish
