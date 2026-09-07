# 2026-09-02 Field Trip Reviews — Extracted Findings (Demo Source)

Source: `~/.hermes/cron/output/08e2b5612fe4/2026-09-02_08-21-26.md` (OCDBot) + `~/.hermes/cron/output/eb866b4f8e66/2026-09-02_08-49-11.md` (MechanicBot). Branch `mechanic/2026-09-02-nav-perf-test-fix`. Used to re-render Telegram walls as HTML demo.

## Cron jobs (pre-migration)

- `08e2b5612fe4` OCDBot — Design System Consistency & Animation — `every day at 8am` — `deliver: telegram` — workdir `/home/khang/repos/field-trip`
- `eb866b4f8e66` MechanicBot — Code Health & Refactor — `every day at 8:05am` — same workdir
- User feedback: "not very common that I need this to run every morning, so I think it makes more sense that these are maybe skills?" + "really hard to follow everything over chat. I would like ... html website with visuals of UI or code or both. I want proper walkthrough of tradeoffs but I want it to be concise, not wordy."

## OCDBot — Top issues (condensed for HTML cards)

- **Tokens:** `app_colors.dart` 13, `app_spacing.dart` 5 (xs4 sm8 md12 lg16 xl24), `app_radii.dart` 2 (pill999 card12), `app_typography.dart` 8, `app_effects.dart` 25+, missing `AppDurations`/`AppCurves`/`AppSizes`.
- **1. No AppDurations/AppCurves:** 11 literals across 5 files — 100ms, 140ms, 180ms x6, 200ms, 250ms + SpringDescription in `date_strip.dart`. Fix: `lib/theme/app_durations.dart` (instant100 fast140 standard180 medium200 slow250) + `app_curves.dart`.
- **2. BorderRadius literals:** `location_detail_sheet.dart:137` 34 low, `:271` 6 low, `:491` 8 low, `segmented_tab_control.dart:26` 100→pill high, `:42` 1000→pill high, `context_menu_popup.dart:83,93` 20 medium, `persistent_photo_toast:28,39,44` 16/6/3 low.
- **3. Color(0x*) hardcodes:** `location_detail_sheet:290` 0xFFCCCCCC→borderSecondary, `:652` 0xFFF0F5FA/0xFFCECFD0→fillCard, `:666` overlay, `home_screen:294` barrier 0x80000000→textPrimary alpha 0.5 or AppColors.barrier.
- **4. SizedBox/raw doubles:** `section_header:47` 16→AppSpacing.lg, `location_detail_sheet:454` 4→AppSpacing.xs, `timeline_column:43` gap16→lg; need `AppSizes` for 20,36,40,44,56,58,64,79x68,18,250.
- **5/6. Durations/Animation:** same 100/140/180/200/250 split; springs keep custom but document in AppCurves; `showModalBottomSheet` barrier hardcoded.
- **7. Dashed constants duplicated:** `dashed_rrect:33-34` and `timeline_connector:34-35` both 4.0/3.0 → `AppEffects.dashLength/dashGap`.
- **Screenshots:** Not captured — Chrome/Playwright unavailable; `flutter build web --release` works but no headless instance.

## MechanicBot — Proposals (2026-09-02 branch)

- `flutter analyze --fatal-infos` clean; `dart fix --dry-run` nothing; `flutter test` blocked by pre-existing `app_header.dart:117` overflow (80px slot, "Sep 2026" overflows 50px) — file touched today so excluded.
- **1. LocationDetailSheet nav (−94 lines) ✅ analyze passes:** Remove `_SheetPage` enum, `_page`/`_openEntry`, `_goBack`/`_openDetail` setState; `_openDetail` → `Navigator.push(MaterialPageRoute, fullscreenDialog:true)` to `_ActivityDetailPage`; simplify `_SheetHeader` (drop isDetailPage/onBack/AnimatedSwitcher/Matrix4.rotationY); remove `dart:math`; `_EmptyDetailPage`→`_ActivityDetailPage` Scaffold+AppBar. Tradeoff: proper route semantics/back gesture/deep-link vs loses custom flip (re-add via PageRouteBuilder if needed).
- **2. AddLocationScreen itemExtent (+7 lines) ✅:** `ListView.separated`→`ListView.builder itemExtent: 56+AppSpacing.xs`, separator inlined. Tradeoff: O(1) scroll metrics vs O(N) layout; brittle if items become variable height.
- **3. test/widget_test.dart ⚠️ needs-human:** Counter smoke → "App builds without crashing" at 1200x800 viewport. Blocked by app_header overflow; widen slot / ellipsis / responsive fix needed first.
- Branch `mechanic/2026-09-02-nav-perf-test-fix` local only, not pushed; `git diff main..branch -- <file>` for patch review.

## Rendering guidance (HTML vs chat)

- Chat wall = lossy: walls of code in monospace, no visuals, easy to miss. HTML = dark canvas `bg:#0a0a0d surface:#131318`, sections, `diff-block` pre, `tradeoff` two-col pro/con, status `badge` (ready/derived/unavailable or pass/needs-human), inline SVG (pill swatches, spacing bar, duration timeline, donut for usage split).
- Concise = 1-2 sentences per tradeoff, not paragraphs. Max 5 issue cards + 3 proposal rows in demo — not exhaustive 7.
- Delivery: `~/.hermes/reports/field-trip-review-YYYY-MM-DD.html` + `latest.html` symlink, opened via `desktop_preview file://` — not Telegram. Pause crons (not delete) after HTML verified.
