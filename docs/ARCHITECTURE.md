# Improve Yourself — Architecture

Local-first Flutter MVP: life areas → goals → actions/habits, two-day rule, Consistency Score, XP. No backend in MVP.

**Product docs:** [ARTIFACTS_AND_REFLECTION.md](ARTIFACTS_AND_REFLECTION.md) · [TEMPLATES.md](TEMPLATES.md) · [COACH.md](COACH.md)

## Stack

- Flutter + Riverpod + go_router
- Drift (SQLite), UUID primary keys
- Soft delete (`deleted_at`) + `updated_at` + `sync_status` on all tables

## Layers

| Layer | Role |
|-------|------|
| `domain/` | Pure models and rules (two-day, consistency, XP, wheel, reflection triggers) — no Flutter/Drift |
| `data/` | Drift schema, repositories, check-in transactions, template catalog |
| `application` via Riverpod providers | Streams / futures over repositories; coach context builder |
| `presentation/` | Screens: Onboarding, Calendar, Wheel, Goals, Progress + reflection/artifact sheets |

**Bottom nav:** Calendar · Wheel · Goals · Progress. At-risk / broken two-day subjects surface inside Calendar (banner + «Почему выпал?» coach), not a separate tab.


## Domain rules (summary)

- **Two-day:** consecutive misses from today backwards; warning at 2, soft break at ≥3.
- **Consistency (30d):** mean of `doneDays / expectedDays` over active non-bad subjects.
- **XP:** `level = floor(sqrt(xp / 100)) + 1`; check-in updates `area_xp` in the same transaction.
- **Wheel:** score 1–10 from consistency + goal progress − bad-habit penalty (computed, not stored as source of truth).
- **Reflection:** soft prompts only for reflective action `kind` or bad-habit slips; max ~3 auto/day; **no effect on XP/Consistency**.
- **Artifacts:** local evidence (photo/metric/notes); photos stay in app documents.

## Schema notes

- Schema version **2+**: `actions.kind`; tables `artifacts`, `reflections`; settings anti-nag fields.
- Coach: local `CoachContextBuilder` + `StubCoachProvider` (live API later — see COACH.md).

## Sync contract (fields only — not implemented)

- Client is source of truth until a server exists.
- Conflict policy (planned): last-write-wins on `updated_at`; merge `check_ins` by unique `(subject_type, subject_id, local_date)`.
- Future API sketch: `GET/POST /sync` with a cursor; payload rows include `id` (= `client_id`), `updated_at`, `deleted_at`, `sync_status`.
- Soft-deleted rows are kept locally until acknowledged by sync.

## Backup

Progress screen exports a JSON dump of all tables (`version`, `exported_at`, table arrays) via share sheet.

## Notifications

Best-effort local notification when Calendar surfaces day-2 (warning) subjects — evening reminder “вернись сегодня”. At-risk / broken items show in a Calendar banner with «Почему выпал?» (failure_coach).
