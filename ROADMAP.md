# ClaudeGamepad — Roadmap

This document captures planned features for future sessions. Each item includes motivation and enough implementation context to resume without re-deriving.

---

## 1. L3 Mouse Click (Left Stick Press → Left Click)

**Status:** Not started  
**Motivation:** Left stick is currently used to simulate mouse cursor movement. Pressing L3 should trigger a left mouse click so the user can interact with UI elements without lifting from the controller.

**Implementation notes:**
- `KeySimulator.swift` already has `simulateMouseMove`. Add `simulateMouseClick(button: .left)` using `CGEvent(mouseEventSource:mouseType:mouseCursorPosition:mouseButton:)`.
- In `GamepadManager.swift`, the L3 press handler currently triggers voice input. This needs to be conditional: if mouse mode is active → left click; otherwise → voice input.
- Need a way to distinguish "mouse mode is active" — likely a boolean flag on `GamepadManager` that gets set when left-stick-as-mouse is engaged.

---

## 2. LT+LB = Command+Option (Typeless Trigger)

**Status:** Not started  
**Motivation:** [Typeless](https://typeless.app) (or similar voice-to-text overlays) is triggered by `⌘⌥` on macOS. The left-hand grip position naturally uses LT and LB simultaneously. This combo should fire `Command+Option` to summon the Typeless shortcut picker.

**Implementation notes:**
- `LT+LB` is currently unassigned. Add it as a recognized combo in `GamepadManager.swift`.
- In `KeySimulator.swift`, add `simulateKeyCombo(modifiers: [.command, .option])` — send a keydown event with both modifier flags and no key code (bare modifier chord).
- The HUD overlay (`OverlayPanel.swift`) should show a hint when LT is held: add a line showing `LB → ⌘⌥ (Typeless)` alongside existing LT+face-button hints.

**Context (2.5):** The overall goal is to enable complete left-hand-only vibe coding:

| Action | Combo |
|--------|-------|
| New tab (terminal) | TBD (see item 3) |
| Trigger voice input (Typeless) | LT + LB |
| Confirm / Enter | A |
| Navigate up/down to select | D-pad ↑↓ |
| Mouse click for edge cases | L3 (see item 1) |

---

## 3. Menu Key → Terminal Tab Switching

**Status:** Not started  
**Motivation:** The Menu/Start button currently opens the preset prompt list. Consider repurposing it (or adding a modifier combo) to switch between terminal tabs, enabling single-hand tab navigation.

**Implementation notes:**
- Current tool is **tmux** (`cmux` is a tmux wrapper). tmux tab (window) shortcuts: `Ctrl+B n` (next), `Ctrl+B p` (prev), `Ctrl+B <num>` (by index).
- Other common terminals for reference: iTerm2 uses `⌘Shift]` / `⌘Shift[`; Terminal.app uses `⌘Shift→` / `⌘Shift←`.
- Decision needed: should this detect the active terminal and adapt, or hardcode tmux shortcuts? Suggested approach: config option in Settings (terminal type selector: tmux / iTerm2 / Terminal.app / custom).
- Candidate binding: `Menu` alone → next tmux window (`Ctrl+B n`); or `Select+D-pad →/←` for tab prev/next.

---

## 4. R3 → Command+W (Close Window/Tab)

**Status:** Not started  
**Motivation:** R3 currently triggers voice input (same as L3). With L3 → mouse click (item 1), R3 is freed up. `⌘W` is the universal macOS "close" shortcut.

**Implementation notes:**
- In `GamepadManager.swift`, change R3 action from voice input to `simulateKeyPress(.w, modifiers: .command)`.
- Voice input needs a new home — likely a dedicated combo (e.g. `Select` long-press, or a dedicated Settings option).
- Update default_config.json to reflect the new R3 default.
- Update README and README-zh button mapping table.

---

## 5. LT+RT Combined Action (TBD)

**Status:** Idea phase — no implementation yet  
**Motivation:** `LT+RT` currently enters command/combo mode. A distinct `LT+RT` *tap* (without subsequent D-pad input) could trigger a dedicated action. Candidate ideas:
- Toggle mouse mode (enables left-stick-as-mouse)
- Open a quick-access HUD or app switcher
- `⌘Tab` (app switcher)
- Save/snapshot current state

**Decision needed:** Pick one action before implementing. Recommend **toggle mouse mode** as it directly supports the left-hand vibe-coding workflow (items 1 & 2).

---

## 6. Controller Layout Diagram in README

**Status:** Not started  
**Motivation:** A visual controller schematic (like a game manual "controls" page) makes the button mapping immediately scannable. Text tables require the reader to mentally map button names to physical positions.

**Implementation notes:**
- Use an SVG diagram of an Xbox/PS5 controller outline with callout labels for each button's current default action.
- Two variants: Xbox style and PS5 style (matching the existing `xbox.svg` / `ps5.svg` in Resources).
- Place in `screenshots/controller-layout-xbox.png` and `screenshots/controller-layout-ps5.png`.
- Add to README.md and README-zh.md under a new "Controller Layout" section, above the text mapping table.
- Tools: can be generated with Figma, Canva, or a custom SVG with `<text>` callouts layered over the existing controller outlines.

---

## Implementation Priority

Suggested order for next sessions:

1. **Item 4** (R3 → ⌘W) — simple one-liner change, immediate value  
2. **Item 1** (L3 mouse click) — enables the left-hand workflow foundation  
3. **Item 2** (LT+LB → ⌘⌥ Typeless) — completes left-hand vibe coding  
4. **Item 3** (Menu → terminal tab switch) — needs terminal detection design decision first  
5. **Item 5** (LT+RT tap) — blocked on deciding the action  
6. **Item 6** (layout diagram) — polish, do last  
