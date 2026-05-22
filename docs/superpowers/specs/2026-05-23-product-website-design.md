# Product Website Design — Claude CodeGamepad

**Date:** 2026-05-23  
**Status:** Design approved, pending implementation

---

## Decisions Made

| Decision | Choice | Reason |
|---|---|---|
| Visual style | Dark Gamer | Dark bg + neon purple/cyan, gaming aesthetic |
| Page depth | Minimal (4 sections) | Fast to scan, perfect for social sharing traffic |
| Hero layout | Split screen | Left: tagline + CTA; Right: terminal mockup with gamepad HUD |
| Tech stack | Single HTML file | Zero dependencies, GitHub Pages ready |

---

## Page Structure

### ① Hero
- **Left side:** badge ("Controller Detected" pill), H1 "Code from Your Couch" with purple→cyan gradient on "Your Couch", subtitle, two CTAs (Download + GitHub), meta row (macOS 14+, Xbox·PS5·MFi, Swift, MIT)
- **Right side:** terminal mockup showing Claude Code session with a gamepad HUD overlay (button hints: A=Accept, B=Cancel, L3=Voice, LT+A=quick prompt)
- Sticky nav: logo with green dot, anchor links, purple CTA button

### ② Features (2×2 grid)
Four cards:
1. **Plug & Play Controllers** — GCController auto-detect, Xbox/PS5 style toggle
2. **Voice Input Pipeline** — Apple Speech + whisper.cpp + LLM refinement (Ollama)
3. **Quick Prompts** — LT/RT + face button, 8 configurable slots
4. **Command Combos** — D-pad sequences, Helldivers/fighting game style, conflict detection

### ③ Screenshots (2×2 grid + tabs)
Tabs: Button Mapping · Preset Prompts · Voice Pipeline · Menu Bar  
Images: load from `screenshots/` directory (actual project screenshots)

### ④ Install CTA
- Requirement badges (macOS 14+, Xbox/PS5/MFi, Swift 5.9+, MIT)
- Code block: `git clone` + `cd` + `swift run` + optional `brew install whisper-cpp`
- Two buttons: Download + GitHub

---

## Visual Language

- **Background:** `#070711` (near-black with slight blue tint)
- **Accent 1:** `#7c3aed` / `#a78bfa` (purple)
- **Accent 2:** `#06b6d4` / `#67e8f9` (cyan)
- **Success indicator:** `#00ff88` (green dot = controller connected)
- **Card background:** `#0d0d14` with `#1f2937` border
- **Font:** `-apple-system, SF Pro Display, Inter` — system stack
- **H1 size:** 52px, weight 900, letter-spacing -1.5px
- **Section labels:** 11px, uppercase, 2px letter-spacing, purple

---

## Files

- **Full mockup:** `.superpowers/brainstorm/59118-1779462291/content/full-page-mockup.html`
- **Target output:** `index.html` (project root, GitHub Pages ready)

---

## Next Steps (Implementation)

1. Write `index.html` at project root — copy mockup structure, clean up annotations
2. Fix screenshot paths (`screenshots/button-mapping.png` etc.)
3. Wire up real GitHub URL (`https://github.com/xargin/ClaudeGamepad`)
4. Add `.gitignore` entry for `.superpowers/`
5. Test locally: open `index.html` in browser, verify all 4 sections render, screenshots load
6. Optional: add GitHub Pages config (`gh-pages` branch or `docs/` root)
