# ClaudeGamepad — Claude Code Instructions

## Build Commands

```bash
# Debug build (for development)
swift build

# Release CLI run
swift run

# Package as .app bundle (recommended for daily use)
./build-app.sh
# → produces ClaudeGamepad.app in the project root

# Install to /Applications/
cp -R ClaudeGamepad.app /Applications/
```

> After replacing the binary in /Applications/, macOS revokes Accessibility.
> Toggle it off/on in System Settings → Privacy & Security → Accessibility.

## Project Structure

```
ClaudeGamepad/
├── Info.plist                  # App bundle metadata (LSUIElement, Accessibility usage)
├── build-app.sh                # Packages SPM output into a signed .app bundle
├── Package.swift               # SPM manifest — executableTarget, no Xcode project
└── Sources/ClaudeGamepad/
    ├── main.swift              # Entry: sets .accessory policy, runs NSApplication
    ├── AppDelegate.swift       # Menu bar icon, Accessibility permission flow
    ├── AppResources.swift      # Bundle-aware resource loader (see below)
    ├── GamepadManager.swift    # Central coordinator: GCController → actions
    ├── KeySimulator.swift      # CGEvent keyboard/mouse simulation (needs AX)
    ├── OverlayPanel.swift      # Floating HUD (NSPanel, non-activating)
    ├── ButtonMapping.swift     # Config model, loads default_config.json
    ├── SpeechSettings.swift    # Voice config model
    ├── SpeechEngine.swift      # No-op stub (Speech.framework disabled, see below)
    ├── WhisperEngine.swift     # whisper.cpp CLI wrapper
    ├── LLMRefiner.swift        # OpenAI-compatible API client
    ├── GamepadConfigView.swift # Visual button editor
    ├── SettingsWindow.swift    # Settings UI
    └── Resources/
        ├── default_config.json
        ├── default_speech_settings.json
        ├── xbox.svg
        └── ps5.svg
```

## Key Architecture Decisions

### Resource Loading — AppResources.swift

SPM's auto-generated `Bundle.module` looks for a `.bundle` file at
`Bundle.main.bundleURL/<name>.bundle`. For `.app` bundles this path lands at the
app root, which codesign rejects as "unsealed contents".

**Solution:** `AppResources` tries `Bundle.main` first (resources flat in
`Contents/Resources/` when running as `.app`), then falls back to `Bundle.module`
(the SPM `.bundle`, used for CLI/debug builds). All three call sites
(`ButtonMapping`, `SpeechSettings`, `SettingsWindow`) use `AppResources.url()`.

`build-app.sh` copies resources flat from the SPM bundle into `Contents/Resources/`.

### Accessibility vs Gamepad Detection

`GCController` does not require Accessibility. `CGEvent` key simulation does.

`AppDelegate.requestPermissions()` always calls `setupGamepad()` immediately so
controllers are detected regardless of AX state. AX is checked separately; if
missing, `AXIsProcessTrustedWithOptions` triggers the system dialog and a timer
polls until granted, hiding the ⚠️ menu item when done.

### SpeechEngine Stub

`Speech.framework` (`SFSpeechRecognizer`) is disabled — linking it into a
non-bundled executable crashes on macOS 26 due to a missing
`NSSpeechRecognitionUsageDescription` in the Info.plist at TCC check time.
`SpeechEngine` is a no-op stub; voice input routes through `WhisperEngine` instead.
If re-enabling system speech, add the plist key and restore the implementation.

### macOS 26 Notes

- `GCController.shouldMonitorBackgroundEvents = true` is required for a menu bar
  app (`.accessory` activation policy) to receive controller input.
- Creating `NSPanel` at launch (OverlayPanel) is safe in a bundled `.app`; the
  original CLI deferral was only needed for unbundled executables.
- `CGWarpMouseCursorPosition` (mouse movement) does not require Accessibility.
  All keyboard CGEvents do.

## Permissions Required

| Permission | When needed | Info.plist key |
|---|---|---|
| Accessibility | Key simulation (all buttons except mouse) | `NSAccessibilityUsageDescription` |
| Microphone | Voice input (WhisperEngine) | add `NSMicrophoneUsageDescription` if re-enabling |
| Speech Recognition | System speech (stub, currently disabled) | add `NSSpeechRecognitionUsageDescription` if re-enabling |

## .app Bundle Layout

```
ClaudeGamepad.app/
└── Contents/
    ├── Info.plist
    ├── _CodeSignature/
    ├── MacOS/
    │   └── ClaudeGamepad          ← release binary
    └── Resources/
        ├── default_config.json
        ├── default_speech_settings.json
        ├── xbox.svg
        └── ps5.svg
```

Ad-hoc signed (`codesign --sign -`). No Developer ID required for local use.
