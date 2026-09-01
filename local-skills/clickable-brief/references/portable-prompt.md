# Clickable brief — portable prompt

Paste this into any LLM chat (ChatGPT, Gemini, etc.) to get the same
"clickable brief" pattern without any special tooling. It only relies on
generating a file and reading a clipboard paste back — nothing Claude-specific.

---

**Prompt to paste:**

> When I ask you to give me options to choose from — design concepts, metadata
> fields, plan variants, anything with more than ~6 items — don't list them as
> text. Instead, generate a single self-contained HTML file and tell me to open
> it in my browser. The page must:
>
> 1. **Be dark mode**, near-black background (`#0a0a0d`), card surfaces one
>    shade lighter (`#131318`), subtle 1px borders.
> 2. **Show each option as a clickable card** with: a title, a one-line
>    description, a visual representation of its data (a big number, a small
>    bar/donut/sparkline chart, tag pills — whatever fits that option; use real
>    numbers/data I've given you, never fabricate stats), a small status badge
>    (colored dot + label, e.g. "Available now" / "Derived" / "Unavailable"),
>    and a monospace source/provenance string in the corner.
> 3. **Group cards into sections** with a short header explaining why those
>    cards are grouped together.
> 4. **Let me click a card to select it** — selected cards get a colored left
>    border/glow and a filled checkmark circle in the corner. Keep a running
>    "N of TOTAL marked" counter in a sticky bottom bar.
> 5. **Include a "Copy shortlist" button** in that bottom bar that copies a
>    JSON array of the full data for every selected card to my clipboard
>    (`navigator.clipboard.writeText`, with a `document.execCommand('copy')`
>    fallback for browsers that block it).
> 6. Give me the file, tell me to open it, click what I want, hit "Copy
>    shortlist", and paste the result back into this chat. When I paste it,
>    parse the JSON and use it as the basis for the next step — don't ask me to
>    retype what I picked.
>
> Keep the HTML/CSS/JS self-contained in one file — no external dependencies,
> no build step, no CDN links.

---

## Notes for whoever's driving this

- This is the same contract as `references/template.html` in this skill,
  minus the browser-automation read-back path (most chat UIs can't drive a
  browser, so copy/paste is the only reliable channel).
- If the target LLM has file-write + browser-open + DOM-read tools of its own
  (agentic coding tools, computer-use), it can skip step 6's manual paste and
  read `window.__briefSelections` directly instead — mention that if relevant.
- Works best when you also hand the LLM the real data up front (metadata
  values, research findings, option attributes) so it doesn't invent numbers
  to fill the cards.
