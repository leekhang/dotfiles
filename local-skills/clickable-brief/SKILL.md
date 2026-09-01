---
name: clickable-brief
description: >-
  Build a clickable, dark-mode "brief board" — a grid of selectable cards
  (visual stat/chart per option, status badge, source annotation) — instead of
  dumping a wall of text when the user needs to pick from many options,
  metadata fields, design concepts, or plan variants. Reads the user's
  selections back by having them paste a copied JSON shortlist and folds them
  into the next step. Trigger on: "give me options
  to pick from", "show me the metadata/concepts available", "let me choose
  which ones to use", or any time you're about to present >5 options as a
  bulleted list and ask the user to reply with which ones they want.
---

# Clickable Brief

A clickable brief replaces a wall of enumerated options ("1. X, 2. Y, 3. Z —
which do you want?") with a scannable, dark-mode card grid the user clicks
through like a product surface. They mark what they want, you read the marks
back, and the conversation continues with exactly that context — no
retyping a list back at you.

Origin: this pattern is adapted from a workflow described publicly by
@ridd_design on X — generating a metadata/concept picker as an HTML page,
selecting visually, and having Claude read the selections out of the browser.
This skill generalizes it beyond that one use case.

## When to use it

Reach for this whenever you're about to ask the user to choose from a set of
things and a chat list would undersell the options:

- Research output with many candidate items (metadata fields, API endpoints,
  design tokens, competitor features, content ideas) where the user needs to
  triage down to a shortlist.
- Multiple concept/design directions that each have a visual or numeric
  identity (charts, counts, distributions, palettes).
- Plan variants or scope options where each option has enough attributes
  (cost, risk, coverage) that a table would still bury the comparison.

Skip it for: fewer than ~6 options, options with no visual/quantitative
identity (plain yes/no choices), or anything where the user just wants a fast
text answer. A wall of 4 bullet points doesn't need a UI.

## Workflow

1. **Gather the raw material first.** Research or compute whatever backs each
   card — the real numbers, the real field names, the real options — before
   writing any HTML. Never invent placeholder stats; a card with a fabricated
   number is worse than a text list.
2. **Shape each item into the card schema** (below) and group items into
   sections with a short "why this group" subtitle, mirroring how you'd narrate
   it in a design review.
3. **Generate the page from `references/template.html`.** Read that file, then
   write a filled-in copy to disk (scratchpad or wherever the user keeps
   working files) with your real sections/cards substituted in. Keep the CSS
   and selection JS verbatim — see "Design spec" below for what's load-bearing
   and what's decorative.
4. **Open it.** Tell the user the local file path (or use the `Artifact` tool
   to publish it) and let them open it themselves. Do not reach for
   `mcp__claude-in-chrome__*` browser automation to open or read this page —
   clipboard is the default read-back path for now (see step 6); only use
   browser automation here if the user asks for it in a given conversation.
5. **Let the user click.** Don't poll or narrate — say what you're waiting for
   ("mark whichever ones you want, then hit Copy shortlist and paste it back
   here") and stop there.
6. **Read the selections back via clipboard paste.** The template's "Copy
   shortlist" button puts a JSON array of the selected cards' full data on the
   user's clipboard — ask them to paste it back into chat, then parse that
   JSON. Don't guess from a description or screenshot. (The template also
   keeps the same data live at `window.__briefSelections` for a
   browser-automation read-back — that path exists and works, see the
   "Read-back paths" note below, but is not the default; use it only if asked.)
7. **Fold the selections into the task** and proceed (e.g. "exploring 5
   variations based on the metadata you selected"). Name what was selected
   back to the user in one line so they know you read it correctly.

## Card schema

Each card is one selectable unit. Keep this shape when generating data —
the template's JS and layout depend on it:

```js
{
  id: "commits-authored",       // stable, kebab-case, unique
  title: "Commits authored",
  description: "Individual commits across their PRs — a finer-grained cadence signal.",
  visual: {
    kind: "bignum" | "donut" | "bars-h" | "bars-v" | "stacked-h" | "heatmap" | "sparkline" | "pills" | "avatar",
    // shape depends on kind — see template's `renderVisual()` for the exact
    // fields each kind reads (e.g. bignum: {value, unit}; donut: {segments:[{label,pct,color}]})
  },
  badge: { label: "Available now", tone: "ready" | "derived" | "unavailable" },
  source: "pr_commits.author_login",  // monospace provenance string, or omit
  accent: "violet" | "green" | "amber" | "default"  // stat color
}
```

Sections wrap cards: `{ title, subtitle, description, cards: [...] }`.

## Design spec — what's load-bearing

Read `references/template.html` before writing a page; don't recreate this
from memory. The parts that matter if you're adapting rather than copying
verbatim:

- **Dark canvas, not a themed light mode.** Near-black background
  (`#0a0a0d`), card surface a shade up (`#131318`), 1px low-alpha white
  border. This pattern is dark-mode-first by design — the visuals (charts,
  colored numbers) read as data on a workbench, not a marketing page.
- **Card anatomy, top to bottom:** title + one-line gray description → big
  colored stat or mini chart → footer row with a status badge pill
  (colored dot + label) on the left and a monospace source string on the
  right. This footer row is what makes cards scannable in bulk — badge tells
  you availability at a glance, source tells you provenance without reading
  prose.
- **Selection affordance:** a hollow circle top-right of each card; clicking
  anywhere on the card toggles it, fills the circle with a check, and adds a
  colored left-border + subtle glow to the whole card. Selection state must be
  visible at a glance across a scrolled grid, not just on the focused card.
- **Section headers carry a "why."** Title + a short gray em-dash annotation
  (e.g. "— the 'lines of code' family") + one sentence of context. This is
  what keeps a 30-card grid legible instead of a flat wall of tiles.
- **Sticky footer bar**, not a floating button: live count ("N of TOTAL
  marked"), a Clear action, and a primary "Copy shortlist" action. Always
  visible regardless of scroll position.
- **Selection state lives in three places simultaneously:** `localStorage`
  (survives reload), `window.__briefSelections` (for a future/opt-in
  browser-automation read-back — see the note in Workflow step 6), and
  clipboard JSON via "Copy shortlist" (today's default read-back path). Keep
  all three in sync on every toggle — don't cut any to simplify.

## Portable version (for other LLMs / no Claude Code tools)

If the user wants to hand this pattern to a different LLM (ChatGPT, Gemini,
etc.) that doesn't have this skill or browser automation, give them
`references/portable-prompt.md` — a self-contained instruction block they can
paste into any chat. It specifies the same card schema and the clipboard-JSON
read-back path (the only path that needs no special tooling), without
referencing Claude-specific tools.
