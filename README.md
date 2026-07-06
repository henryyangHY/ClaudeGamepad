# ClaudeGamepad 

[![macOS](https://img.shields.io/badge/macOS-14.0%2B-orange)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5.9+-red)](https://swift.org/)
[![License](https://img.shields.io/badge/License-MIT-blue)](LICENSE)
[![GitHub Stars](https://img.shields.io/github/stars/henryyangHY/ClaudeGamepad?style=social)](https://github.com/henryyangHY/ClaudeGamepad)

A native macOS menu bar app that lets you control [Claude Code](https://claude.ai/claude-code) with a game controller. Lean back, vibe code from your couch.

Supports Xbox, PS5 DualSense, and any MFi-compatible controller. Includes voice input Typeless or other local voice-to-text model like whisper with additional settings.

## Why Claude Gamepad?

Ever wanted to code from your couch? Claude Gamepad brings the comfort of game controllers to AI-assisted coding. No more hunching over your keyboard—use a controller to navigate Claude Code while standing, stretching, or relaxing.

**Perfect for:**
- Developers with RSI or mobility considerations
- Standing desk setups
- Living room coding sessions
- Voice-first workflows with hands-free control

## Table of Contents

- [Quick Start](#quick-start)
- [Features](#features)
- [Demo](#demo)
- [Screenshots](#screenshots)
- [Default Button Mapping](#default-button-mapping)
- [Installation](#installation)
- [Usage](#usage)
- [Configuration](#configuration)
- [Architecture](#architecture)
- [License](#license)

## Quick Start

Get up and running in under 5 minutes:

```bash
# 1. Clone and build
git clone https://github.com/henryyangHY/ClaudeGamepad.git
cd ClaudeGamepad
swift build -c release

# 2. Run the app
swift run

# 3. Grant permissions when prompted
# - Accessibility (required, for keyboard / mouse simulation)
# - Microphone (optional, only if you wire a button to Voice Input)
```

Connect your controller, focus your Claude Code terminal, and start coding!

## Features

- **Menu bar app** - runs in the background, no Dock icon
- **Plug and play** - auto-detects Xbox / PS5 / MFi controllers via `GCController`
- **Xbox / PS5 style toggle** - switch button labels and colors across the entire UI
- **Full button mapping** - every button configurable via GUI settings
- **Quick prompts** - LT/RT + face button sends preset prompts (cheat sheet shows on trigger hold)
- **LT+LB chord** - fires `⌘⌥` for Typeless or any overlay voice trigger, single-hand reachable
- **LT+RT toggle** - tap both triggers to toggle left-stick mouse-cursor mode for click-driven UI
- **L3 left click** - press the left stick to click wherever the cursor is
- **Overlay navigation** - any button can be assigned a `Combo` action (e.g. `⌘W` close, `⌘⇧]` next tab) to drive shortcuts directly
- **Voice input** - optional, wire any button to the Voice Input action
  - Local whisper.cpp (offline, higher quality)
  - Optional LLM refinement (Ollama / OpenAI compatible)
- **Preset menu** - configurable menu of preset prompts navigated by D-pad
- **Floating HUD** - non-intrusive overlay shows button feedback and transcription
- **macOS native** - pure Swift + AppKit, no Electron, no Python

## Demo

<!--
  HOW TO EMBED THE DEMO VIDEO
  ---------------------------
  GitHub does NOT render a player for an .mp4 committed to the repo, and it
  rejects any single file larger than 100 MB. So do this instead:

    1. Compress the source clip to < 100 MB (aim for < 10 MB so the README
       loads fast), e.g.:
         ffmpeg -i "0703.mp4" -vf scale=-2:720 -c:v libx264 -crf 28 \
                -preset veryfast -c:a aac -b:a 96k demo.mp4
    2. Open this README on github.com and click the pencil (edit) icon.
    3. Drag demo.mp4 into the editor. GitHub uploads it and inserts a
       https://github.com/user-attachments/assets/<id> URL.
    4. Replace the placeholder line below with that URL (a bare URL on its
       own line renders as an inline player), then commit.

  The video lives on GitHub's CDN, not in the repo's git history.
-->

<!-- Replace this line with the user-attachments URL from the drag-and-drop upload -->
_Demo video coming soon — see the comment above for how to embed it._

## Screenshots

### Button Mapping

Configure your controller with an intuitive visual editor. All buttons are grouped by region—shoulders, face buttons, navigation, and system controls—for quick scanning and reassignment.

![Button Mapping](screenshots/button-mapping.png)

### Preset Prompts

Build your command palette. Edit all trigger combos from one focused workspace. Pick a preset or write custom text, with live character count and preview before you save.

![Preset Prompts](screenshots/quick-prompts.png)

### Speech Recognition

See the full voice pipeline at a glance. Check engine status, binary installation state, model download progress, and LLM cleanup toggle without opening multiple windows.

![Speech Recognition](screenshots/speech-recognition.png)

### Menu Bar

The app lives in your menu bar. A green indicator means your controller is connected and ready; gray means no controller detected.

![Menu Bar](screenshots/menu-bar.png)

## Default Button Mapping

| Button (Xbox / PS5) | Default Action |
|----------------------|----------------|
| A / ✕ | Enter (confirm) |
| B / ○ | Ctrl+C (interrupt) |
| X / □ | Accept (y + Enter) |
| Y / △ | Reject (n + Enter) |
| D-pad | Arrow keys |
| LB / L1 | `⌘W` (close window/tab) |
| RB / R1 | Escape |
| L3 (left stick click) | Left mouse click |
| R3 (right stick click) | `⌘W` (close window/tab) |
| Start / Options | `⌘⇧]` (next terminal tab) |
| Select / Create | `⌘T` (new tab) |
| LT / L2 + Face | Quick prompt (configurable) |
| RT / R2 + Face | Quick prompt (configurable) |
| LT + LB | `⌘⌥` (Typeless / overlay trigger) |
| LT + RT (tap) | Toggle mouse-cursor mode for left stick |
| LT + RT + Select | Quit (safety override) |

All mappings are fully customizable in Settings.

> **Note:** macOS reserves the hardware Guide / Home / PS button. If you want to open Vibe Island or another overlay from the controller, map any capturable button to the `Combo` action instead.

## Installation

### Requirements

- macOS 14.0 (Sonoma) or later
- A game controller (Xbox, PS5 DualSense, or MFi compatible)
- For Whisper (optional): `brew install whisper-cpp`

### Option A: .app Bundle (Recommended)

Build a proper macOS app bundle that lives in `/Applications/` and can auto-launch on login — no terminal required after the first build.

```bash
git clone https://github.com/henryyangHY/ClaudeGamepad.git
cd ClaudeGamepad
./build-app.sh
cp -R ClaudeGamepad.app /Applications/
```

Then open the app once and grant **Accessibility** when prompted.

**Auto-launch on login:** System Settings → General → Login Items → add ClaudeGamepad.

> **Note:** Every time you rebuild and copy a new binary to `/Applications/`, macOS will revoke the existing Accessibility grant. Go to System Settings → Privacy & Security → Accessibility, toggle ClaudeGamepad off and back on after each update.

### Option B: Build from Source (CLI)

```bash
git clone https://github.com/henryyangHY/ClaudeGamepad.git
cd ClaudeGamepad
swift build -c release
# Binary at .build/release/ClaudeGamepad
```

### Run (CLI)

```bash
swift run
```

Or build and copy to your PATH:

```bash
swift build -c release
cp .build/release/ClaudeGamepad /usr/local/bin/
```

## First Launch

1. Open `ClaudeGamepad.app` (or run `swift run` for CLI mode)
2. If Accessibility is not granted, the menu bar icon shows **「⚠️ Grant Accessibility to enable buttons」** — click it to jump directly to System Settings
3. Grant **Accessibility** permission (needed for keyboard simulation)
4. Grant **Speech Recognition** permission if using voice input
5. Connect your controller — the menu bar icon turns active
6. Focus your terminal running Claude Code
7. Start pressing buttons!

## Usage

### Basic Controls

| Action | Controller Input |
|--------|------------------|
| Navigate / select | D-pad |
| Accept suggestion | X / □ |
| Reject suggestion | Y / △ |
| Send / Confirm | A / ✕ |
| Cancel / Interrupt | B / ○ |
| Close window / tab | LB / L1 or R3 (`⌘W`) |
| Next terminal tab | Start / Options (`⌘⇧]`) |
| Mouse click | L3 (after enabling mouse mode) |
| Toggle mouse mode | Tap LT + RT together |
| Trigger Typeless / overlay | Hold LT, tap LB (`⌘⌥`) |

### Voice Input (optional)

Voice input is no longer mapped by default. To enable it:

1. Open **Settings → Button Mapping** and assign any spare button to `Voice Input`.
2. Press that button — the floating HUD shows "Listening..." with a live waveform.
3. Speak your prompt (auto-detects Chinese and English).
4. HUD shows transcription with confirm/cancel options.
5. Press **A / ✕** to paste to terminal, or **B / ○** to cancel.

> Backend is `whisper.cpp` (install with `brew install whisper-cpp`). The system `SFSpeechRecognizer` path is currently stubbed.

### Quick Prompts

Hold a trigger (LT or RT) and press a face button for instant commands. The HUD pops a cheat sheet as soon as you hold the trigger.

| Trigger | Button | Command |
|---------|--------|---------|
| LT | A | `codex` |
| LT | B | `claude` |
| LT | X | `copilot` |
| LT | Y | `gemini` |
| RT | A | `run the tests` |
| RT | B | `show me the diff` |
| RT | X | `looks good, commit this and push` |
| RT | Y | `refactor this to be cleaner` |

LT is the "switch AI assistant" trigger; RT is the dev workflow trigger. Both are fully editable in **Settings → Prompts**.

### Trigger Chords

| Chord | Effect |
|-------|--------|
| **LT + LB** | Fires `⌘⌥` — summons Typeless or any overlay that listens for the modifier-only chord |
| **LT + RT** (tap together) | Toggles left-stick mouse-cursor mode on/off; persisted across launches |
| **LT + RT + Select** | Quits the app (safety override regardless of other mappings) |

## Configuration

Click the menu bar icon > **Settings** to open the settings window. The settings panel uses a dark-themed card layout with four tabs: **General**, **Button Mapping**, **Prompts**, and **Speech**.

### General

Choose your **controller style** — Xbox or PS5. This changes all button labels and colors across the UI, overlays, and settings panels.

### Button Mapping

All button bindings organized by region: Shoulders, Face Buttons, Navigation, and System & Sticks. Each button has a dropdown to pick its action. LT/RT (L2/R2) serve as modifier keys, so their quick prompts are managed in the Prompts tab. If you assign a button to `Combo`, the row expands to show the keyboard shortcut that button will fire (e.g. `⌘W`, `⌘⇧]`).

### Prompts

The left panel lists all quick prompt slots (LT+A, LT+B, RT+A, etc.); the right panel is a focused editor. Each slot can use a preset prompt or custom text, with live character count and preview.

**Default Quick Prompts:**

| Trigger | Prompt |
|---------|--------|
| LT + A | `codex` |
| LT + B | `claude` |
| LT + X | `copilot` |
| LT + Y | `gemini` |
| RT + A | `run the tests` |
| RT + B | `show me the diff` |
| RT + X | `looks good, commit this and push` |
| RT + Y | `refactor this to be cleaner` |


### Testing

1. Test with both Xbox and PS5 controllers if possible
2. Test voice input with both system speech and whisper.cpp
3. Test all button mappings after making changes
4. Verify the app works with Claude Code in a real terminal session

## Architecture

For detailed system architecture, module relationships, and data flow documentation, see [ARCHITECTURE.md](ARCHITECTURE.md).

```
Sources/ClaudeGamepad/
├── main.swift              # Entry point (NSApplication.shared.run())
├── AppDelegate.swift       # Menu bar icon, permission handling
├── AppResources.swift      # Bundle-aware resource loader (.app vs CLI)
├── GamepadManager.swift    # Central coordinator, input routing
├── KeySimulator.swift      # Keyboard + mouse event generation (CGEvent)
├── OverlayPanel.swift      # Floating HUD + WaveformView
├── SpeechEngine.swift      # SFSpeechRecognizer wrapper (stubbed / disabled)
├── WhisperEngine.swift     # whisper.cpp CLI wrapper
├── LLMRefiner.swift        # OpenAI-compatible API client
├── ButtonMapping.swift     # Configuration data model
├── SpeechSettings.swift    # Voice configuration model
├── GamepadConfigView.swift # Visual button editor component
└── SettingsWindow.swift    # Settings UI (4 tabs)
```

## License

MIT
