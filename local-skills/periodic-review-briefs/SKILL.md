---
name: periodic-review-briefs
description: Turn periodic cron reviews into on-demand visual briefs.
version: 0.1.0
author: Khang Le (leekhang), Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [reviews, cron, html, briefs]
    related_skills: [plan, clickable-brief]
---

# Periodic Review Briefs

Convert low-frequency scheduled review bots (daily cron → Telegram walls) into on-demand Hermes skills that emit a concise visual HTML report (code diffs + UI visuals + 1-2 sentence tradeoffs) instead of chat text.

## When to Use

- User says daily/every-morning cron is too frequent, wants on-demand or "maybe skills?" — migrate the cron prompt into a skill.
- Any periodic review (design-system consistency, animation tokens, code health / perf / redundancy) where the current output is a long chat wall and the user says "hard to follow over chat" or asks for HTML/website with visuals.
- You need to re-render a prior cron output as a demo HTML before changing delivery.
- Don't use for: truly time-sensitive alerts that must push, or one-off tasks with no repeat value.

## Prerequisites

- Hermes cron jobs inspected via `cronjob action=list` and `~/.hermes/cron/jobs.json` + `~/.hermes/cron/output/<job_id>/`.
- Skills infra: user-local skills at `~/.hermes/skills/<name>/SKILL.md` via `skill_manage`, listed via `skills_list`, viewed via `skill_view`.
- HTML delivery via `desktop_preview action=open url=file://...` or `MEDIA:` path; template derived from `clickable-brief/references/template.html` (dark vars `--bg:#0a0a0d`, `--surface:#131318`, `--accent:#8b7cf6`).
- Repo is code-only — never write `field-trip/reports/*.html` or `field-trip/docs/PRD.md` to the repo; stage locally to `~/.hermes/reports/` then upload to Second Brain project `Field Trip` at `My Drive/00 Second Brain/10 Projects/Field Trip/{reports/design-review, reports/code-review, plans, docs}/` via `gws drive upload` (macOS mount: `~/Library/CloudStorage/GoogleDrive-leekg97@gmail.com/My Drive/00 Second Brain/10 Projects/Field Trip/...`). Plans/PRDs live in Drive, repo is `.hermes/`-gitignored.
- Flutter/web screenshot is best-effort — `flutter build web` works but headless Chrome may be absent; report must degrade to code/diff visuals.

## How to Run

```bash
# 1. Inspect crons
cronjob action=list
cat ~/.hermes/cron/jobs.json | python3 -m json.tool | head -n 120
ls ~/.hermes/cron/output/<job_id>/

# 2. Create on-demand skills from cron prompts (OCDBot design review + MechanicBot code review)
skill_manage action=create name=design-review      # trigger: "review design system" (was OCDBot)
skill_manage action=create name=code-review  # triggers: "review my code health" / "code performance" (was MechanicBot)

# 3. Generate HTML — TWO separate pages, append mode (never overwrite)
python3 ~/.hermes/skills/design-review/scripts/generate-report.py --fixture fixtures/2026-09-02.json --out ~/.hermes/reports/design-review-2026-09-02.html
python3 ~/.hermes/skills/code-review/scripts/generate-report.py --fixture fixtures/2026-09-02.json --out ~/.hermes/reports/code-review-2026-09-02.html
# Stage -> upload to Second Brain project Field Trip (repo stays code-only)
gws drive mkdir "My Drive/00 Second Brain/10 Projects/Field Trip/reports/design-review"
gws drive upload ~/.hermes/reports/design-review-2026-09-02.html --parent "My Drive/00 Second Brain/10 Projects/Field Trip/reports/design-review"
gws drive upload ~/.hermes/reports/code-review-2026-09-02.html --parent "My Drive/00 Second Brain/10 Projects/Field Trip/reports/code-review"

# 4. Preview (two pages)
# via tool: desktop_preview action=open url=file:///home/khang/.hermes/reports/design-review-2026-09-02.html
# via tool: desktop_preview action=open url=file:///home/khang/.hermes/reports/code-review-2026-09-02.html

# 5. Remove crons after verification (fully on-demand, no scheduled fallback)
cronjob action=remove job_id=<id>
```

## Procedure

1. **Capture source of truth (read-only).** Read `jobs.json` and both `output/<id>/*.md` files. Save copies to `/tmp/` — don't edit crons yet. Done when you have the two markdown reports and job IDs/schedules.
2. **Decide skill shape (DRY).** Use two skills — `design-review` (Design Review, trigger: "review design system", was OCDBot) and `code-review` (Code Review, triggers: "review my code health" / "code performance", was MechanicBot) — sharing one `references/report-template.html` + `scripts/generate-report.py` via symlink. They produce two separate HTML pages (one per skill), never a combined page. Done when names, triggers, and shared paths chosen.
3. **Create shared HTML template (read-only, not a picker).** Copy `clickable-brief/references/template.html` dark vars, strip selection JS (`selected`, `.check`, `localStorage`, `__briefSelections`, footer Copy/Clear), add `<!-- INJECT:REPORT_BODY -->`, `.diff-block`, `.tradeoff` two-col, `.badge`. Done when `report-template.html` exists and has no selection code.
4. **Create skills from cron prompts.** Each `SKILL.md` frontmatter: `name` ≤64 chars, `description` ≤60 chars ending with period, `platforms: [linux, macos, windows]`. Body must have `When to Use` (with "Don't use for"), `Procedure` with checkable steps, `Pitfalls`, `Verification`. Reports are "Design Review" / "Code Review" (never "OCDBot" in title/header/meta). Migrate cron prompt Steps verbatim into Procedure. Done when `skill_view` renders and `skills_list` shows them.
5. **Add shared generator (stdlib only, ≤80 lines).** `scripts/generate-report.py` with `--out`, `--fixture`, `--live` flags, `render_diff_block`, `render_tradeoff`, `build_report` (injects into template). Fixture mode makes demo deterministic without `flutter analyze`. Done when `--help` works.
6. **Re-render prior output as TWO demo HTML pages (user explicitly asked to "try doing that with this morning's output" — concise, not wordy, with visuals).** Build two fixtures (`design-review/fixtures/2026-09-02.json` + `code-review/fixtures/2026-09-02.json`) from the cron markdowns — Design Review 5 cards (token inventory + BorderRadius/Color/SizedBox/durations/dash) and Code Review 3 proposals (Navigator, itemExtent, widget_test) — each with file:line table, unified diff block, 1-2 sentence Pro/Con tradeoff, and tiny inline SVG visual (pill swatches, spacing bar, duration timeline). Generate two dated HTML files (`design-review-YYYY-MM-DD.html`, `code-review-YYYY-MM-DD.html`) append-only (never overwrite), stage to `~/.hermes/reports/`, upload to `My Drive/00 Second Brain/10 Projects/Field Trip/reports/{design-review,code-review}/`. Each card must show the exact component with a callout dot→tag on the non-compliant value and mirrored `✕ Before (literal)` vs `✓ After (token)` tables — not just a diff. Done when smoke test passes (`grep OCDBot == 0`, `grep before-after ≥ cards`, `grep callout ≥ cards`) and `desktop_preview` shows two dark pages.
7. **Remove crons (fully on-demand).** `cronjob action=remove` both jobs; verify absent via `cronjob action=list` / `jobs.json` (count 0 or without those IDs). Repo is code-only so no HTML is committed; Drive holds history (append dated files). Done when both removed and Telegram stops.
8. **Wire live scan (optional).** Add thin `scripts/run.py` wrappers that run real scans (`flutter analyze --fatal-infos`, token grep) and call generator with `--live`. Done when `/tmp/*-live.html` builds.

## Pitfalls

- **User prefers concise, not wordy, with visuals of UI or code or both.** Each card shows the exact component with a pinpointed callout (dot+tag on `circular(100) ✕`, `#CCCCCC ✕→#DBDFE4 ✓`) plus mirrored `✕ Before (red literal)` vs `✓ After (green token)` tables — not just a code diff. Each tradeoff = max 1-2 sentences + visual (inline SVG swatch, duration timeline). Future sessions: if the user says "hard to follow over chat" or asks for "proper walkthrough of tradeoffs but concise", this HTML pattern applies. Chat walls are the anti-pattern; two separate pages (Design Review / Code Review) beat one long combined wall. Include `OCDBot` nowhere in title/header/meta after the rename.
- **Repo is code-only.** Never write `field-trip/reports/`, `field-trip/docs/PRD.md`, or commit `*.html` to the repo; stage to `~/.hermes/reports/` then `gws drive upload` to `My Drive/00 Second Brain/10 Projects/Field Trip/{reports/design-review, reports/code-review, plans, docs}/`. PRDs/engineering-briefs move to `.../Field Trip/docs/` then `git rm` from `field-trip/docs/`. Verify with `git status --porcelain | grep -E "reports/|\.html|docs/PRD"` and ensure `.gitignore` has `.hermes/` + `node_modules/`.
- **Append, never overwrite.** Each run writes a new dated file (`design-review-YYYY-MM-DD.html`, `code-review-YYYY-MM-DD.html`). No `latest.html` overwrite. Prune manually if Drive grows; no auto-retention in v1.
- **Drive auth on Linux may be stale.** This ZimaBoard host returned `invalid_grant` on `gws drive`; the Second Brain vault is reliably mounted only on macOS (`~/Library/CloudStorage/GoogleDrive-leekg97@gmail.com/...`). Don't block verification on upload failure — `desktop_preview` on the staged file is the gate; upload retries from macOS or after `gws` re-auth.
- **Screenshots may be unavailable.** `browser_exec`/`chrome --headless` was absent on 2026-09-02 runs — don't fail the report; use code diffs + SVG placeholders and note "Screenshots unavailable".
- **Skill discovery is cached at session start.** New skills won't appear in `skills_list`/`skill_view` until gateway restart or new session — document reload step.
- **Fully on-demand.** User chose no scheduled fallback — remove crons, don't pause with a monthly nudge. Deletion is intentional; prompts are now captured in the skills.
- **Template is read-only.** Don't re-add `clickable-brief` selection JS (circles, localStorage, Copy shortlist) — these briefs are reports, not pickers.
- **`flutter test` may be blocked by pre-existing layout bugs** (e.g., `app_header.dart` 80px overflow). Treat as amber badge, don't abort generation.

## Verification

- `skills_list` shows `design-review` + `code-review`; `skill_view(name=...)` parses YAML, description ≤60 chars ending with period; `When to Use` triggers are "review design system" and "review my code health" / "code performance"; titles say Design Review / Code Review (no OCDBot).
- `grep -c "INJECT:REPORT_BODY" report-template.html` == 1 and `grep -c "localStorage"` == 0.
- `python3 -m pytest scripts/test_report_smoke.py -q` == 1 passed (asserts both demo HTMLs exist at `~/.hermes/reports/design-review-2026-09-02.html` + `code-review-2026-09-02.html` and contain AppDurations/Design Review and LocationDetailSheet/Code Review respectively, `grep OCDBot == 0`, `grep -c before-after` ≥ cards, `grep -c callout` ≥ cards).
- `desktop_preview` opens both `file:///home/khang/.hermes/reports/design-review-*.html` and `code-review-*.html` — two dark pages, Design Review with token inventory + 5 issue cards (component mock + before/after tables + pro/con), Code Review with 3 proposal rows (pass/needs-human badges).
- `gws drive list "My Drive/00 Second Brain/10 Projects/Field Trip/reports/design-review"` and `.../code-review` + `.../Field Trip/plans` + `.../Field Trip/docs` show dated files / PRD; `git status` shows no `reports/*.html` or `docs/PRD.md` leak (code-only).
- `cronjob action=list` shows both jobs removed (count 0 or without 08e2b5612fe4/eb866b4f8e66).

## References

- `references/2026-09-02-field-trip-reviews.md` — extracted OCDBot + MechanicBot findings from 2026-09-02 (the demo source).
- `references/report-template.html` — shared dark-mode template (trimmed clickable-brief).
