# Claude Gamepad Architecture

A native macOS menu bar application that enables game controller input for Claude Code, built with pure Swift and AppKit.

## Overview

Claude Gamepad transforms game controller input into keyboard events and text, allowing developers to control Claude Code hands-free. The application runs as a menu bar (Dock-less) app, detecting controllers automatically and providing voice input capabilities.

## Technology Stack

| Component | Technology |
|-----------|------------|
| Language | Swift 5.9+ |
| Platform | macOS 14.0 (Sonoma)+ |
| UI Framework | AppKit |
| Controller API | GameController.framework |
| Voice Input | whisper.cpp (external CLI) |
| Keyboard Simulation | CGEvent ( HID events), AppleScript |
| Build System | Swift Package Manager |

### Key System Frameworks

- **GameController** - GCController for gamepad input handling
- **AVFoundation** - Audio capture for voice input
- **AppKit** - All UI components (NSPanel, NSWindow, NSStatusBar)
- **Carbon.HIToolbox** - Virtual keycode constants for key simulation

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Claude Gamepad                            │
│                    (Menu Bar Application)                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐     ┌─────────────────────────────────────┐  │
│  │  AppDelegate │────▶│         GamepadManager                │  │
│  │  (Entry)    │     │  - GCController lifecycle            │  │
│  └──────────────┘     │  - Button event routing              │  │
│                       │  - Voice input orchestration         │  │
│                       └───────────────┬─────────────────────┘  │
│                                       │                          │
│        ┌──────────────────────────────┼──────────────────────┐  │
│        │                              │                      │  │
│        ▼                              ▼                      ▼  │
│  ┌─────────────┐            ┌──────────────┐        ┌─────────┐ │
│  │ KeySimulator│            │  OverlayPanel │        │ Speech  │ │
│  │             │            │   (HUD)      │        │ Engines │ │
│  │ - CGEvent   │            │              │        │         │ │
│  │ - AppleScript│           │ - Waveform   │        │ -Speech │ │
│  │ - Focus     │            │ - Messages   │        │ -Whisper│ │
│  │   routing   │            │ - Combo UI   │        │ -LLM    │ │
│  └─────────────┘            └──────────────┘        └─────────┘ │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                    Settings Subsystem                      │  │
│  │  ┌──────────────┐  ┌────────────────┐  ┌──────────────┐  │  │
│  │  │ButtonMapping │  │ SpeechSettings │  │SettingsWindow│  │  │
│  │  │ (Config)     │  │   (Config)     │  │   (UI)       │  │  │
│  │  └──────────────┘  └────────────────┘  └──────────────┘  │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │  Claude Code    │
                    │  (Terminal)     │
                    └─────────────────┘
```

## Core Modules

### 1. GamepadManager (Central Coordinator)

**File**: `GamepadManager.swift`

The orchestrator that coordinates all subsystems. Acts as the single point of control for gamepad input.

**Responsibilities**:
- GCController discovery and lifecycle management
- Input event routing based on current mode (normal, voice, preset menu)
- Mode state management (voice active, preset menu open)
- Callback orchestration for the voice engine

**Key States**:
```swift
isVoiceActive: Bool      // Voice input in progress
isInPresetMenu: Bool     // Preset prompt browser open
ltHeld / rtHeld: Bool    // Trigger modifier keys
```

**Input Flow**:
1. GCController button press detected
2. Handler invoked based on button (onButtonA, onDpadPress, etc.)
3. Mode-aware routing determines action
4. Execute via KeySimulator or voice subsystem

### 2. KeySimulator (Output Layer)

**File**: `KeySimulator.swift`

Converts controller input into keyboard events for Claude Code control.

**Mechanisms**:

| Method | Use Case | Mechanism |
|--------|----------|-----------|
| `pressKey()` | Single keys | CGEvent HID tap |
| `pressCombo()` | Modifier combos | AppleScript System Events |
| `pasteString()` | Text paste | Clipboard + Cmd+V |
| `typeString()` | Commands | Paste + Enter |
| `typeAccept/Reject()` | Claude suggestions | y/n + Enter |

**Overlay Navigation**:
- Monitors frontmost application PID
- Routes D-pad arrows to overlay windows temporarily
- 3-second capture window after combo fires

### 3. OverlayPanel (Feedback UI)

**File**: `OverlayPanel.swift`

Floating HUD that displays feedback without stealing terminal focus.

**Presentation Modes**:
- **Standard** - Brief action confirmations (2s auto-dismiss)
- **Listening** - Voice input with waveform visualization
- **Transcription** - Recognition result with confirm/cancel
- **PromptSheet** - Trigger cheat sheet (radial button layout)

**Design**:
- `NSPanel` with `.nonactivatingPanel` style
- `NSVisualEffectView` with vibrancy
- Positioned at screen bottom center
- Auto-positions to main screen

### 4. Voice Subsystem

**Files**: `WhisperEngine.swift`, `LLMRefiner.swift`, `SpeechEngine.swift`

Local voice-to-text pipeline built on whisper.cpp. The legacy system-speech
path (SpeechEngine) is disabled — see below.

```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐
│  Microphone │───▶│  whisper.cpp │───▶│ LLM Refiner │
│  Input      │    │    (CLI)     │    │  (Optional) │
└─────────────┘    └──────────────┘    └─────────────┘
```

**WhisperEngine** (Local, active):
- External whisper.cpp CLI process
- Model management (tiny to large-v3)
- Fully offline operation

**LLMRefiner** (Optional):
- OpenAI-compatible API (Ollama, LM Studio)
- Transcription post-processing/correction

**SpeechEngine** (disabled stub):
- No-op. The original SFSpeechRecognizer path is disabled: linking
  Speech.framework into an unbundled binary crashes on macOS 26 (TCC requires
  `NSSpeechRecognitionUsageDescription` from an Info.plist the CLI lacks).
- Voice input routes through WhisperEngine or an external tool (e.g. Typeless).

### 5. Configuration System

**Files**: `ButtonMapping.swift`, `SpeechSettings.swift`

**ButtonMapping**:
- All button action bindings
- Trigger prompt presets (LT/RT + face)
- Controller style (Xbox/PS5 label theme)
- JSON persistence to `~/Library/Application Support/ClaudeGamepad/config.json`

**SpeechSettings**:
- Engine selection
- Whisper model and binary paths
- LLM refinement configuration
- Persisted alongside button mapping

### 6. SettingsWindow (Configuration UI)

**File**: `SettingsWindow.swift`

Dark-themed card-based settings interface with sidebar navigation.

**Sections**:
1. **General** - Controller style selection (Xbox/PS5)
2. **Button Mapping** - Visual button editor
3. **Preset Prompts** - Trigger combo editor with preset picker
4. **Speech Recognition** - Whisper model + LLM configuration

## Data Flow

### Button Press to Action

```
Controller Button
       │
       ▼
GamepadManager.onButtonX()
       │
       ▼
Check State Flags
       │
       ├──▶ isVoiceActive ──▶ A=Confirm, B=Cancel
       │
       ├──▶ isInPresetMenu ──▶ D-pad navigation, A=Select
       │
       ├──▶ ltHeld ──▶ Execute LT prompt
       │
       ├──▶ rtHeld ──▶ Execute RT prompt
       │
       └──▶ Normal ──▶ ButtonMapping.buttonActions[x] → KeySimulator
```

### Voice Input Flow

```
Stick Click (L3/R3)
       │
       ▼
GamepadManager.startVoiceInput()
       │
       ▼
WhisperEngine.startListening()
       │
       ▼
Audio Capture → Recognition
       │
       ▼
onPartialResult / onFinalResult callbacks
       │
       ▼
OverlayPanel.showMessage() / showListening()
       │
       ▼
User confirms with A button
       │
       ▼
KeySimulator.pasteString(text)
```

## Directory Structure

```
Sources/ClaudeGamepad/
├── main.swift              # Entry point (NSApplication.shared.run())
├── AppDelegate.swift       # Menu bar icon, permission handling
├── GamepadManager.swift    # Central coordinator, input routing
├── KeySimulator.swift      # Keyboard event generation
├── OverlayPanel.swift      # Floating HUD + WaveformView
├── SpeechEngine.swift      # Disabled no-op stub (see Voice Subsystem)
├── WhisperEngine.swift     # whisper.cpp CLI wrapper
├── LLMRefiner.swift        # OpenAI-compatible API client
├── ButtonMapping.swift     # Configuration data model
├── SpeechSettings.swift    # Voice configuration model
├── GamepadConfigView.swift # Visual button editor component
└── SettingsWindow.swift   # Settings UI
```

## Key Design Patterns

### Singleton Pattern

All major subsystems use shared instances:
```swift
GamepadManager.shared
KeySimulator.shared
OverlayPanel.shared
SpeechEngine.shared
WhisperEngine.shared
LLMRefiner.shared
```

### Callback-based Communication

Speech engines use closures for async results:
```swift
onPartialResult: ((String) -> Void)?
onFinalResult: ((String) -> Void)?
onError: ((String) -> Void)?
onAudioLevel: ((Float) -> Void)?
```

### State Machine for Input Modes

GamepadManager maintains exclusive state flags:
- Voice mode blocks other input
- Preset menu has its own navigation

### Persistence Model

Configuration stored as JSON in Application Support:
- `~/Library/Application Support/ClaudeGamepad/config.json`
- Loaded at startup, saved on Settings window close
- Backward-compatible decoding for new fields

## Extension Points

### Adding New Button Actions

1. Add case to `ButtonAction` enum in `ButtonMapping.swift`
2. Implement handling in `GamepadManager.executeAction()`
3. Add UI option in `GamepadConfigView.swift`

### Adding New Voice Engines

1. Create an engine class following the `WhisperEngine` pattern
2. Add the engine type to the `SpeechEngineType` enum in `SpeechSettings.swift`
3. Add engine selection UI in `SettingsWindow.swift`
4. Wire it up in `GamepadManager.startVoiceInput()`

### Adding Settings Sections

1. Add case to `SettingsSection` enum
2. Implement `buildSectionView()` in `SettingsWindow.swift`
3. Add sidebar button in `buildSidebar()`
