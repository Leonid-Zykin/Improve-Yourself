# Goal templates

Catalog of realistic starter goals for Improve Yourself. Numbers are intentionally **sustainable**, not hustle-max.

Template **ids are stable** — agents and onboarding presets must keep them.

Related: [ARTIFACTS_AND_REFLECTION.md](ARTIFACTS_AND_REFLECTION.md), [COACH.md](COACH.md).

## Research notes (brief citations)

| Topic | Realistic baseline used in templates | Sources |
|-------|--------------------------------------|---------|
| Training frequency | Beginners: **2–3×/week** full-body, non-consecutive days | [ACSM resistance training](https://acsm.org/resistance-training-guidelines-update-2026/); NSCA novice 2–3 days/week |
| Weight loss | **~0.5–1 kg/week**; −5 kg ≈ **6–12 weeks**, not a crash | [CDC](https://www.cdc.gov/healthy-weight-growth/losing-weight/index.html); Mayo Clinic / Harvard Health |
| Sleep | Adults **7–9 h/night** (NSF); “8h” as a friendly target inside that band | [National Sleep Foundation](https://www.thensf.org/how-many-hours-of-sleep-do-you-really-need/) |
| Job search | Prefer **quality**: ~**3–5 tailored apps/day** if full-time, or **5–10 targeted/week** remote; avoid spray-and-pray | Industry application-rate analyses 2025–26 (e.g. Huntr-style tracking); remote guides stressing 70%+ fit |
| Reading | **~10 pages/day ≈ 12 books/year** (~300 pp/book); 20 pages/day is ambitious but common | Aggregation math / StoryGraph-style studies; Pew median US reader is far lower — 12 books/year is already solid |
| Emergency fund | Starter **$1k** then **3–6 months** essential expenses; automate small transfers | [Fidelity](https://www.fidelity.com/learning-center/smart-money/emergency-fund); Vanguard / Ramsey consensus |
| English → B2 | Roughly **500–600 guided hours** from zero; **~30–60 min/day** sustainable → multi-year if starting low; B1→B2 often **150–200 h** | Cambridge / British Council CEFR hour bands |

Anti-hustle stance: daily actions are small; weekly cadence for training; job search emphasizes tailored volume; language is minutes, not “8 hours immersion”.

---

## JSON shape (for agents / assets)

```json
{
  "schema_version": 1,
  "templates": [
    {
      "id": "health_train_3x",
      "life_area": "health",
      "title": "…",
      "description": "…",
      "target": { "value": 12, "unit": "тренировок/мес", "deadline_weeks": null },
      "actions": [
        {
          "title": "…",
          "kind": "workout",
          "schedule": "weekly",
          "xp": 15,
          "artifact_hints": ["photo", "generic_note"],
          "reflection_prompt_keys": ["workout_feel"]
        }
      ],
      "habits": [
        { "title": "…", "kind": "good", "xp_delta": 5, "area_keys": ["health"] }
      ]
    }
  ],
  "onboarding_presets": [
    {
      "id": "remote_athlete",
      "label": "…",
      "vision_hint": "…",
      "template_ids": ["health_train_3x", "career_remote_4k", "…"]
    }
  ]
}
```

`kind` on actions: `workout` | `reading` | `career` | `study` | `language` | `other`.

Runtime source of truth in MVP: Dart catalog `lib/data/templates/catalog.dart` (+ optional `assets/templates/catalog.json` mirror).

---

## Catalog (12 templates)

### Health

#### `health_train_3x`
- **Area:** health  
- **Title:** Тренировки 3× в неделю  
- **Target:** 12 тренировок / месяц (≈3×/week)  
- **Actions:** «Силовая / тело» · `kind=workout` · weekly · hints: photo, generic_note · prompts: `workout_feel`  
- **Habits:** (optional) «Разминка 5 мин» good  

#### `health_lose_5kg`
- **Area:** health  
- **Title:** −5 кг устойчиво  
- **Target:** 5 кг за **10–12 недель** (~0.5 кг/нед) — deadline hint 12 weeks  
- **Actions:** «Взвешивание + короткий лог еды» · `kind=other` · 2–3×/week · hints: metric · (no auto reflection — kind other)  
- **Habits:** «Прогулка 20–30 мин» good  

#### `health_sleep_8h`
- **Area:** health  
- **Title:** Сон ~8 часов  
- **Target:** 8 часов / ночь (внутри NSF 7–9)  
- **Actions:** «Отбой по плану» · `kind=other` · daily · hints: metric (часы сна)  
- **Habits:** «Экраны за 30 мин до сна» good; optional bad «Кофе после 16:00»  

### Career

#### `career_remote_4k`
- **Area:** career  
- **Title:** Удалёнка $4000+  
- **Target:** оффер ≥ 4000 USD/мес  
- **Actions:**  
  - «2–3 точечных отклика» · `kind=career` · daily · hints: daily_log · prompts: `career_blocker`  
  - «English 30 мин (собес)» · `kind=language` · daily · prompts: `language_practice`  
  - «Портфолио / кейс 45 мин» · `kind=career` · 3×/week · hints: generic_note  

#### `career_junior_middle`
- **Area:** career  
- **Title:** Junior → Middle  
- **Target:** уровень Middle (самооценка / грейд)  
- **Actions:** «Глубокая практика 45–60 мин» · `kind=study` · daily · prompts: `study_focus` · hints: generic_note  

#### `career_daily_log`
- **Area:** career  
- **Title:** Ежедневный work log  
- **Target:** 20 рабочих логов / месяц  
- **Actions:** «Work log 5–10 мин» · `kind=career` · daily · hints: daily_log · prompts: `career_blocker`  

### Books / growth

#### `books_12_year`
- **Area:** growth  
- **Title:** 12 книг в год  
- **Target:** 12 книг; implied **~10 страниц/день**  
- **Actions:** «10 страниц» · `kind=reading` · daily · hints: chapter_note, metric · prompts: `reading_takeaway`  

#### `books_finish_one`
- **Area:** growth  
- **Title:** Дочитать одну книгу  
- **Target:** 1 книга (~3–5 недель at 10–15 стр/день)  
- **Actions:** «15 страниц текущей книги» · `kind=reading` · daily · hints: chapter_note · prompts: `reading_takeaway`  

### Finance

#### `finance_emergency_fund`
- **Area:** finance  
- **Title:** Подушка безопасности  
- **Target:** этап 1 — **1000** (валюта пользователя); затем 3 месяца расходов (пользователь задаёт сумму)  
- **Actions:** «Перевод в подушку» · `kind=other` · weekly · hints: metric  

#### `finance_expense_track`
- **Area:** finance  
- **Title:** Учёт расходов  
- **Target:** 30 дней подряд с записью  
- **Actions:** «Записать расходы дня» · `kind=other` · daily · hints: daily_log, metric  

### Relationships

#### `rel_contact_loved`
- **Area:** relationships  
- **Title:** Связь с близкими  
- **Target:** 4 контакта / месяц (≈1×/week)  
- **Actions:** «Созвон / сообщение близким» · `kind=other` · weekly · hints: generic_note  

### Language

#### `lang_english_b2`
- **Area:** growth (language path; career may also link)  
- **Title:** English → B2  
- **Target:** CEFR B2; **30–45 мин/день** (~3.5–5 ч/нед). From zero: multi-year; from B1: often months of steady hours  
- **Actions:** «English 30 мин» · `kind=language` · daily · hints: generic_note · prompts: `language_practice`  
- **Habits:** «Listening в дороге 15 мин» good  

---

## Onboarding vision → template bundles

| Preset id | Label (RU) | Vision hint | Template ids |
|-----------|------------|-------------|--------------|
| `remote_athlete` | Удалёнка + тело | Senior remote + сильное тело | `health_train_3x`, `career_remote_4k`, `lang_english_b2` |
| `balanced_reader` | Баланс + книги | Спокойный рост и чтение | `health_sleep_8h`, `books_12_year`, `rel_contact_loved` |
| `money_stability` | Финансовая опора | Подушка и ясность по деньгам | `finance_emergency_fund`, `finance_expense_track`, `career_daily_log` |
| `career_climb` | Карьерный шаг | Junior→Middle + практика | `career_junior_middle`, `career_daily_log`, `lang_english_b2` |
| `health_reset` | Здоровье с нуля | Сон, вес, движение без фанатизма | `health_sleep_8h`, `health_train_3x`, `health_lose_5kg` |

Onboarding may still allow free-text edits; presets only **seed** goals/actions/habits from templates.

---

## Applying a template (app behaviour)

1. Resolve `life_area` key → existing `life_areas.id`
2. Create `goal` with title / target / unit / optional deadline
3. Create `actions` with `kind`, schedule, xp; link `goal_id`
4. Create `habits` + `habit_area_effects`
5. Do not auto-create reflections/artifacts — only hints for UI

UI entry points:

- Onboarding: pick a preset (or keep manual goals)
- Goals: **«Добавить из шаблона»**
