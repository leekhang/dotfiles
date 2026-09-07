# Explaining With Diagrams — templates

User signal: "I'm confused", "I don't get it", paragraphs too dense. Switch to diagrams.

## Layer Diagram (durable vs ephemeral)

```
Durable — outside git (survives pull)        Ephemeral — inside git clone (wiped on pull)
~/.hermes/skins/plain.yaml                     ~/.hermes/hermes-agent/
~/.hermes/config.yaml (display.skin)            cli.py
                                                agent/display.py
                                                hermes_cli/skin_engine.py
```

## Path Diagram (which code path a skin can vs cannot reach)

```
 Skin path (what plain CAN control)          Hard-coded path (what plain CANNOT reach)
 terminal → get_tool_emoji("terminal")        tool complete → display.py:_get_cute_tool_message
   plain " " → invisible ✓                      if tool=="terminal": return "┊ 💻 $ ..."  (literal)
```

## Before/After Wrap

```
BEFORE                          AFTER (hanging indent)
• 💻 $         cat file ...     • cat file ...
  detail continues at col 0  →    detail continues
                                  ↳ subsequent_indent="  "  (2 spaces)
```

## Timeline Diagram

```
T0 patch display.py + cli.py  →  emojis gone, pill gray
T1 gateway restart → git pull --ff-only origin main (63279301)
                      display.py mtime 07:19:50 → pristine
                      plain.yaml stays gray (outside git)
now new hermes = pristine code + gray plain → hard-coded leaks return
```
