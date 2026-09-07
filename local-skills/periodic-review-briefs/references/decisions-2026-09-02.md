# Decisions — 2026-09-02 Review: Cron → Skills + HTML Briefs

User reviewed the plan at `.hermes/plans/2026-09-02_194500-cron-to-skills-html-report.md` (now lives at `My Drive/00 Second Brain/10 Projects/Field Trip/plans/`) and resolved all questions including follow-ups. Final decisions:

## Resolved

1. **Two separate pages** (not one combined). Design Review (was OCDBot) + Code Review (was MechanicBot). Each skill owns one HTML file (`design-review-YYYY-MM-DD.html` + `code-review-YYYY-MM-DD.html`). Tradeoff walkthroughs stay concise (1-2 sentences + inline SVG/before-after visual) — user said Telegram walls were "really hard to follow".
2. **Append dated files forever** (never overwrite). No `latest.html` overwrite; prune manually if Drive grows. No auto-retention in v1.
3. **Triggers / names:** Design Review skill (`design-review`, was OCDBot) — trigger: `review design system`. Code Review skill (`code-review`, was MechanicBot) — triggers: `review my code health` / `code performance`. Titles/headers say Design Review / Code Review (no OCDBot). Document both in `When to Use`.
4. **New Second Brain project: Field Trip.** Reports live at `My Drive/00 Second Brain/10 Projects/Field Trip/reports/{design-review,code-review}/`, plans at `.../Field Trip/plans/`, PRDs/docs at `.../Field Trip/docs/`. Repo is code-only (`field-trip` holds only code + README/AGENTS); PRDs (`docs/PRD.md`, `engineering-brief.md`) moved to `.../Field Trip/docs/` via `gws drive upload` then `git rm`. macOS mount: `~/Library/CloudStorage/GoogleDrive-leekg97@gmail.com/My Drive/00 Second Brain/10 Projects/Field Trip/...`. Linux ZimaBoard has no local Drive mount — `gws drive` returned `invalid_grant` on 2026-09-02 — so `desktop_preview` on `~/.hermes/reports/` is the verification gate; upload retries from macOS or after re-auth. Stage locally, verify preview, then upload — never block on Drive. Check repo cleanliness with `git status --porcelain | grep -E "reports/|\.html|docs/PRD"` and ensure `.gitignore` has `.hermes/`.
5. **Fully on-demand.** No scheduled fallback. Remove both crons (`08e2b5612fe4` + `eb866b4f8e66`) after demo verification; don't pause. Prompts are now captured in the skills.
6. **Report style correction (2026-09-02 follow-up):** User asked: "point to what specifically within it that is nonn-compliant" + "just showing code changes is hard to understand — use a more visual way". Each card now renders the exact component with a callout dot→tag on the bad value (`circular(100) ✕ pill is 999`, `#CCCCCC ✕→#DBDFE4 ✓`) and mirrored `✕ Before (literal, red)` vs `✓ After (token, green)` tables. Raw diff alone is insufficient.

## Preference signals (embedded in skill)

- "I want proper walkthrough of tradeoffs but I want it to be concise, not wordy." → Cap each tradeoff at 1-2 sentences + tiny visual. Walls of bullet prose are the failure mode.
- "It's actually really hard to follow everything over chat. I would like to change the output format from texts to a html website with visuals of UI or code or both." → HTML dark-mode report is the default for any periodic review that currently emits a chat wall. Derive template from `clickable-brief/references/template.html` but strip selection JS — report is read-only, with component mocks + before/after.
- "I want to keep the repo with just the code, any skills, artifacts, reports generated should be saved on my second brain in google drive instead. Figure out the best place." → New project `10 Projects/Field Trip` (not `learn-flutter`); `~/.hermes/reports/` is staging only; canonical is `.../Field Trip/{reports,plans,docs}/`.
- "we shouldn't call it ocd review, it should be design review now" / "move all the PRDs we've made into second brain as well" → Renamed `ocd-review→design-review` everywhere (skills, reports, Drive folders); PRDs are not code, they belong in Second Brain docs.

## Implications for future sessions

- When proposing a review, list both triggers explicitly (`review design system` vs `review my code health`) so the user can pick one stream without running the other.
- When generating HTML, always produce two dated files, verify both via `desktop_preview` + `grep OCDBot==0` + `grep before-after` + `grep callout` before claiming success.
- Don't re-introduce a daily cron without explicit user ask — the daily cadence was rejected.
- Don't write plans/reports/PRDs into `field-trip/` — upload to `.../Field Trip/` on Drive and keep the repo `.hermes/`-ignored.
