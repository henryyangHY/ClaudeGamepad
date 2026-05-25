# ClaudeGamepad Phase 2 — Remove Combo Mode + LT+LB Overlay Hint (施工圖)

> **給協調者 (Henry) 的說明：** 接續 `SUBAGENT-IMPLEMENTATION-PLAN.md`。兩個需求：
> (1) **完整移除 Combo/Command Mode**，LT+RT 改成直接 toggle mouse mode on/off；
> (2) **LT 的快捷鍵 overlay 底部加一行** `LB → ⌘⌥ Typeless` 提示。
> 一樣循序執行、每步 commit。Claude 寫的標 `(by Claude)`。

**Goal:** 拔掉 Combo Mode 整套（runtime + Settings 分頁 + overlay + model 資料），LT+RT 變成單純的 mouse-mode 開關；並讓 LT cheat sheet 顯示 LT+LB 功能。

**為什麼有嚴格順序（編譯依賴）：** Combo 資料型別（`ComboEntry`/`ComboStyle`/`mapping.combos`/`mapping.comboStyle`）被 3 個 consumer 引用：GamepadManager、OverlayPanel、SettingsWindow。**必須先移除全部 consumer，最後才移除 model 欄位**，否則中間任何一個 commit 都編不過。`ComboInput` enum **保留**（d-pad 處理 `onDpadPress` 還在用它當方向型別）。

---

## ⚠️ 每個 session 的開場（沿用 Plan 1 的 preamble）

把 `SUBAGENT-IMPLEMENTATION-PLAN.md` 開頭那段 preamble 完整貼進每個 session。重點重申：

```
- 工作目錄 ~/Documents/Claude/projects/ClaudeGamepad；先 git status（clean）+ git log --oneline -3。
- 只做這一個 Task。照我給的 old_string→new_string / 刪除指示精準執行，不要「改良」、不要換寫法、不要加額外 commit。若覺得有錯，停下來回報。
- 驗證：swift build -c release 2>&1 | tail -5 必須 Build complete!；再跑我列的 grep 驗證刪乾淨。
- 不要執行 app、不要測手把（沒手把、沒 AX）。
- 不要動 ~/Library/Application Support/ClaudeGamepad/ 下的檔。
- 驗證綠燈後用我給的 commit message 做一個 commit。回報：改了哪些檔 / build 結果 / Henry 要測什麼。
```

> **Edit tool 是用「字串內容」比對，不是行號。** 下面引用的行號只是幫你定位；只要 old_string 唯一就能正確替換，行號位移不影響後續 edit。

### 執行順序與建議 model

| 順序 | Task | 風險 | 建議 model |
|------|------|------|-----------|
| 1 | GamepadManager：LT+RT→toggle、拔 command-mode runtime | 中（多處 edit） | Haiku 可，Sonnet 較穩 |
| 2 | OverlayPanel：刪 `showCommandMode` | 低（刪一個 method） | Haiku |
| 3 | SettingsWindow：刪 Command Combos 分頁 + `ComboInputEditor` | **高（大段刪除）** | **Sonnet/Opus 強烈建議** |
| 4 | ButtonMapping + default_config：刪 model 欄位 | 中（Codable 多處） | Haiku 可，Sonnet 較穩 |
| 5 | req 2：LT+LB overlay hint | 中（動手排佈局） | Haiku 可，Sonnet 較穩 |

**測試在 Task 5 之後一次做**（附錄）。Task 1 完成後就可先測 LT+RT toggle 是否取代了 combo mode。

---

## Task 1: GamepadManager — LT+RT 改 toggle mouse mode、移除 command-mode runtime

**File:** `Sources/ClaudeGamepad/GamepadManager.swift`（只此一檔）

- [ ] **Step 1: 移除 command-mode 狀態屬性**

old_string:
```swift
    private var isInCommandMode = false
    private var comboBuffer: [ComboInput] = []
    private var comboTimer: Timer?
    private var lastPartialText = ""
```
new_string:
```swift
    private var lastPartialText = ""
```

- [ ] **Step 2: 移除 Task 5 留下的 command-mode 計時屬性**

old_string:
```swift
    private var ltHeld = false
    private var rtHeld = false
    private var commandModeEnteredAt: TimeInterval = 0
    private let mouseTapThreshold: TimeInterval = 0.30
```
new_string:
```swift
    private var ltHeld = false
    private var rtHeld = false
```

- [ ] **Step 3: 整段重寫 `onTriggerChanged`（LT+RT→toggle mouse mode）**

把整個 `onTriggerChanged` method 換掉。

old_string（從 `private func onTriggerChanged` 到它的結尾 `}`，即現在約 161–221 行）:
```swift
    private func onTriggerChanged(isLT: Bool, value: Float, pressed: Bool) {
        let held = value > 0.1
        let wasLT = ltHeld
        let wasRT = rtHeld
        if isLT { ltHeld = held } else { rtHeld = held }

        let bothNow = ltHeld && rtHeld
        let bothBefore = wasLT && wasRT

        // L2+R2 together → enter command mode
        if bothNow && !bothBefore {
            enterCommandMode()
            return
        }

        // Leaving command mode: one trigger released
        if !bothNow && bothBefore && isInCommandMode {
            // A quick LT+RT tap with no combo input → toggle mouse mode.
            let heldDuration = ProcessInfo.processInfo.systemUptime - commandModeEnteredAt
            let wasTap = comboBuffer.isEmpty && heldDuration < mouseTapThreshold
            exitCommandMode()
            if wasTap {
                toggleMouseMode()
                return
            }
            // If the other trigger is still held, show its cheat sheet
            if ltHeld || rtHeld {
                let useLeft = ltHeld
                let prompts = useLeft ? mapping.ltPrompts : mapping.rtPrompts
                let labels = mapping.labels
                let triggerLabel = useLeft ? labels.lt : labels.rt
                overlay.showPromptSheet(label: triggerLabel, labels: labels, prompts: [
                    ("a", prompts.a),
                    ("b", prompts.b),
                    ("x", prompts.x),
                    ("y", prompts.y),
                ])
            }
            return
        }

        // Single trigger → show cheat sheet (only if not in command mode)
        if !isInCommandMode {
            if held && (isLT ? !wasLT : !wasRT) && !bothNow {
                let prompts = isLT ? mapping.ltPrompts : mapping.rtPrompts
                let labels = mapping.labels
                let triggerLabel = isLT ? labels.lt : labels.rt
                overlay.showPromptSheet(label: triggerLabel, labels: labels, prompts: [
                    ("a", prompts.a),
                    ("b", prompts.b),
                    ("x", prompts.x),
                    ("y", prompts.y),
                ])
            }

            // Hide when both triggers are released
            if !ltHeld && !rtHeld && (wasLT || wasRT) {
                overlay.fadeOut()
            }
        }
    }
```
new_string:
```swift
    private func onTriggerChanged(isLT: Bool, value: Float, pressed: Bool) {
        let held = value > 0.1
        let wasLT = ltHeld
        let wasRT = rtHeld
        if isLT { ltHeld = held } else { rtHeld = held }

        let bothNow = ltHeld && rtHeld
        let bothBefore = wasLT && wasRT

        // LT+RT pressed together → toggle mouse mode (once, on entering both-held)
        if bothNow && !bothBefore {
            toggleMouseMode()
            return
        }

        // Leaving both-held but one trigger still down → show that trigger's cheat sheet
        if !bothNow && bothBefore {
            if ltHeld || rtHeld {
                showTriggerCheatSheet(isLT: ltHeld)
            } else {
                overlay.fadeOut()
            }
            return
        }

        // Single trigger newly held → show its quick-prompt cheat sheet
        if held && (isLT ? !wasLT : !wasRT) && !bothNow {
            showTriggerCheatSheet(isLT: isLT)
        }

        // Hide when both triggers are released
        if !ltHeld && !rtHeld && (wasLT || wasRT) {
            overlay.fadeOut()
        }
    }

    /// Show the LT/RT quick-prompt cheat sheet for the given trigger.
    private func showTriggerCheatSheet(isLT: Bool) {
        let prompts = isLT ? mapping.ltPrompts : mapping.rtPrompts
        let labels = mapping.labels
        let triggerLabel = isLT ? labels.lt : labels.rt
        overlay.showPromptSheet(label: triggerLabel, labels: labels, prompts: [
            ("a", prompts.a),
            ("b", prompts.b),
            ("x", prompts.x),
            ("y", prompts.y),
        ])
    }
```

- [ ] **Step 4: 移除 `onLB()` 裡的 `isInCommandMode` 條件**（Task 2 of Plan 1 留下的）

old_string:
```swift
        if ltHeld && !isInCommandMode {
            overlay.showMessage("⚡ ⌘⌥ Typeless")
```
new_string:
```swift
        if ltHeld {
            overlay.showMessage("⚡ ⌘⌥ Typeless")
```

- [ ] **Step 5: 移除 `handleFaceButton` 開頭的 command-mode 分支，並拿掉 `comboInput` 參數**

old_string:
```swift
    private func handleFaceButton(action: ButtonAction, ltPrompt: String, rtPrompt: String, comboInput: ComboInput) {
        // Command mode: feed into combo buffer
        if isInCommandMode {
            comboAppend(comboInput)
            return
        }
        // Voice mode: A = confirm, B = cancel
```
new_string:
```swift
    private func handleFaceButton(action: ButtonAction, ltPrompt: String, rtPrompt: String) {
        // Voice mode: A = confirm, B = cancel
```

- [ ] **Step 6: 更新 4 個 caller（移除 `comboInput:` 引數）**

old_string:
```swift
    private func onButtonA() {
        handleFaceButton(action: mapping.buttonActions.a,
                         ltPrompt: mapping.ltPrompts.a, rtPrompt: mapping.rtPrompts.a, comboInput: .a)
    }

    private func onButtonB() {
        handleFaceButton(action: mapping.buttonActions.b,
                         ltPrompt: mapping.ltPrompts.b, rtPrompt: mapping.rtPrompts.b, comboInput: .b)
    }

    private func onButtonX() {
        handleFaceButton(action: mapping.buttonActions.x,
                         ltPrompt: mapping.ltPrompts.x, rtPrompt: mapping.rtPrompts.x, comboInput: .x)
    }

    private func onButtonY() {
        handleFaceButton(action: mapping.buttonActions.y,
                         ltPrompt: mapping.ltPrompts.y, rtPrompt: mapping.rtPrompts.y, comboInput: .y)
    }
```
new_string:
```swift
    private func onButtonA() {
        handleFaceButton(action: mapping.buttonActions.a,
                         ltPrompt: mapping.ltPrompts.a, rtPrompt: mapping.rtPrompts.a)
    }

    private func onButtonB() {
        handleFaceButton(action: mapping.buttonActions.b,
                         ltPrompt: mapping.ltPrompts.b, rtPrompt: mapping.rtPrompts.b)
    }

    private func onButtonX() {
        handleFaceButton(action: mapping.buttonActions.x,
                         ltPrompt: mapping.ltPrompts.x, rtPrompt: mapping.rtPrompts.x)
    }

    private func onButtonY() {
        handleFaceButton(action: mapping.buttonActions.y,
                         ltPrompt: mapping.ltPrompts.y, rtPrompt: mapping.rtPrompts.y)
    }
```

- [ ] **Step 7: 移除 `onDpadPress` 開頭的 command-mode 分支**

old_string:
```swift
    private func onDpadPress(_ direction: ComboInput) {
        if isInCommandMode {
            comboAppend(direction)
            return
        }

        if isInPresetMenu {
```
new_string:
```swift
    private func onDpadPress(_ direction: ComboInput) {
        if isInPresetMenu {
```

- [ ] **Step 8: 移除 command-mode 區塊（保留 `toggleMouseMode`）**

刪除 `activeCombos`、`enterCommandMode`、`exitCommandMode`、`comboAppend`，但**保留 `toggleMouseMode`**。

操作：刪除 **`// MARK: - Command Mode`（約 502 行）到 `enterCommandMode` 結尾的 `}`（約 514 行）** 這一段——即下面這整塊：

old_string:
```swift
    // MARK: - Command Mode

    private var activeCombos: [ComboEntry] {
        mapping.combos.filter { $0.style == mapping.comboStyle }
    }

    private func enterCommandMode() {
        commandModeEnteredAt = ProcessInfo.processInfo.systemUptime
        isInCommandMode = true
        comboBuffer = []
        comboTimer?.invalidate()
        overlay.showCommandMode(inputs: [], combos: activeCombos, style: mapping.comboStyle, labels: mapping.labels)
    }

    private func exitCommandMode() {
        isInCommandMode = false
        comboBuffer = []
        comboTimer?.invalidate()
        comboTimer = nil
        overlay.fadeOut()
    }

    /// Toggle the left stick between scroll and mouse-cursor mode, persisting the choice.
    private func toggleMouseMode() {
```
new_string:
```swift
    // MARK: - Mouse Mode

    /// Toggle the left stick between scroll and mouse-cursor mode, persisting the choice.
    private func toggleMouseMode() {
```

- [ ] **Step 9: 刪除整個 `comboAppend` method**

刪除從 `private func comboAppend(_ input: ComboInput) {`（約 536 行）到它結尾的 `}`（在 `// MARK: - Preset Menu` 之前，約 581 行）。讀那個區域、把整個 method 連同它前面的空行刪掉。刪完 `// MARK: - Mouse Mode`（含 toggleMouseMode）後面應直接接 `// MARK: - Preset Menu`。

- [ ] **Step 10: 驗證**

Run: `swift build -c release 2>&1 | tail -5`
Expected: `Build complete!`

Run: `grep -c "isInCommandMode\|comboBuffer\|comboAppend\|enterCommandMode\|exitCommandMode\|activeCombos\|showCommandMode" Sources/ClaudeGamepad/GamepadManager.swift`
Expected: `0`

- [ ] **Step 11: Commit**

```bash
git add Sources/ClaudeGamepad/GamepadManager.swift
git commit -m "$(cat <<'EOF'
refactor: LT+RT toggles mouse mode, remove command-mode runtime

Removes enterCommandMode/exitCommandMode/comboAppend/activeCombos and
the combo-buffer state. LT+RT now directly toggles mouse mode. Keeps
ComboInput (still used as the d-pad direction type). (by Claude)
EOF
)"
```

**Henry 測試（重包後）：** 同時按 LT+RT → 直接 `🖱️ Mouse mode ON`；再按一次 → OFF。不再出現 Command Mode overlay。

---

## Task 2: OverlayPanel — 刪除 `showCommandMode`

**File:** `Sources/ClaudeGamepad/OverlayPanel.swift`（只此一檔）
**前置：** Task 1 完成（此時 `showCommandMode` 已無 caller）。

- [ ] **Step 1: 刪除整個 `showCommandMode` method**

刪除從註解 `/// Show command mode overlay with input sequence and available combos.`（約 326 行）到該 method 結尾的 `}`（約 457 行，在 `/// Show transcription result.` 之前）。

定位錨點：
- 起：`    /// Show command mode overlay with input sequence and available combos.`
- 該行下一行是：`    func showCommandMode(inputs: [ComboInput], combos: [ComboEntry], style: ComboStyle, labels: ControllerLabels) {`
- 終：該 func 的閉合 `}`，其後緊接空行 + `    /// Show transcription result.`

讀 326–460 區域，把這整個 method（含上方 doc 註解）刪掉。刪完 `showPromptSheet` 結尾後應直接接 `/// Show transcription result.`。

- [ ] **Step 2: 驗證**

Run: `swift build -c release 2>&1 | tail -5`
Expected: `Build complete!`

Run: `grep -c "showCommandMode\|ComboEntry\|ComboStyle" Sources/ClaudeGamepad/OverlayPanel.swift`
Expected: `0`

> 註：`ComboInput` 在 OverlayPanel 刪除後應為 0（它只在 showCommandMode 用到）。若 grep 到殘留，表示沒刪乾淨，重看。

- [ ] **Step 3: Commit**

```bash
git add Sources/ClaudeGamepad/OverlayPanel.swift
git commit -m "$(cat <<'EOF'
refactor: remove showCommandMode overlay (combo mode gone) (by Claude)
EOF
)"
```

---

## Task 3: SettingsWindow — 刪除 Command Combos 分頁 + ComboInputEditor

**File:** `Sources/ClaudeGamepad/SettingsWindow.swift`（只此一檔）
**前置：** Task 1、2 完成。
**🔴 高風險、大段刪除——強烈建議用 Sonnet/Opus 跑這個 session。**

依序做以下 6 處刪除/修改。每處都用 Edit 精準替換或刪除。

- [ ] **Step 1: 從 `SettingsSection` enum 移除 `.combos` case**

old_string:
```swift
        case general
        case buttons
        case prompts
        case combos
        case speech
```
new_string:
```swift
        case general
        case buttons
        case prompts
        case speech
```

- [ ] **Step 2: 移除 `title` switch 的 `.combos` arm**

old_string:
```swift
            case .prompts: return "Preset Prompts"
            case .combos: return "Command Combos"
            case .speech: return "Speech Recognition"
```
new_string:
```swift
            case .prompts: return "Preset Prompts"
            case .speech: return "Speech Recognition"
```

- [ ] **Step 3: 移除 `subtitle` switch 的 `.combos` arm**

old_string:
```swift
            case .combos:
                return "Configure command mode: combo style and input sequences."
            case .speech:
                return "See the whole voice pipeline at a glance: engine, model, install state, and LLM cleanup."
```
new_string:
```swift
            case .speech:
                return "See the whole voice pipeline at a glance: engine, model, install state, and LLM cleanup."
```

- [ ] **Step 4: 移除 `symbolName` switch 的 `.combos` arm**

old_string:
```swift
            case .prompts: return "text.bubble"
            case .combos: return "bolt.circle"
            case .speech: return "waveform.and.mic"
```
new_string:
```swift
            case .prompts: return "text.bubble"
            case .speech: return "waveform.and.mic"
```

- [ ] **Step 5: 移除 summary switch 的 `.combos` arm**

old_string:
```swift
        case .prompts:
            return "\(promptSlots.count) quick prompts"
        case .combos:
            return "\(mapping.combos.count) combos · \(mapping.comboStyle == .helldivers ? "Helldivers" : "Fighting")"
        case .speech:
            return selectedEngineType == .system ? "System speech" : "Whisper local"
```
new_string:
```swift
        case .prompts:
            return "\(promptSlots.count) quick prompts"
        case .speech:
            return selectedEngineType == .system ? "System speech" : "Whisper local"
```

- [ ] **Step 6: 移除 `buildSectionView` switch 的 `.combos` arm**

old_string:
```swift
        case .prompts:
            return buildPromptsTab()
        case .combos:
            return buildCombosTab()
        case .speech:
            return buildSpeechTab()
```
new_string:
```swift
        case .prompts:
            return buildPromptsTab()
        case .speech:
            return buildSpeechTab()
```

- [ ] **Step 7: 移除 `applyControllerStyle` 裡的 `.combos` 快取清除行**

old_string:
```swift
        sectionViews.removeValue(forKey: .buttons)
        sectionViews.removeValue(forKey: .prompts)
        sectionViews.removeValue(forKey: .combos)
```
new_string:
```swift
        sectionViews.removeValue(forKey: .buttons)
        sectionViews.removeValue(forKey: .prompts)
```

- [ ] **Step 8: 刪除整個 Command Combos 方法區塊（約 744–979 行）**

刪除從 `    // MARK: - Command Combos`（約 744 行）到 `editComboInputs` 方法結尾的 `}`（約 978 行），其後緊接 `    // MARK: - Speech`（約 980 行）。

這段包含這些成員，全部刪除：
`comboStylePopup`、`comboTableContainer` 兩個屬性；`buildCombosTab()`、`filteredComboIndices()`、`comboPrefixConflicts(for:)`、`rebuildComboRows()`、`comboStyleChanged(_:)`、`comboNameChanged`、`comboPromptChanged`、`addCombo()`、`deleteCombo(_:)`、`editComboInputs(_:)`。

讀 744–981 區域確認邊界後，把整段刪掉。刪完前一個 method 的 `}` 後應直接接 `// MARK: - Speech`。

- [ ] **Step 9: 刪除整個 `ComboInputEditor` class（約 1475–1667 行）**

刪除從 `private final class ComboInputEditor: NSObject {`（約 1475 行）到它的閉合 `}`（約 1667 行），其後緊接空行 + `private final class SurfaceCardView: FlippedView {`（約 1669 行）。讀 1475 及 1660–1670 區域確認邊界後刪除整個 class。

- [ ] **Step 10: 驗證**

Run: `swift build -c release 2>&1 | tail -5`
Expected: `Build complete!`

> ⚠️ **驗證 grep 要精確**：`SettingsWindow.swift:1377` 有 `mapping.guideKeyCombosMap`（鍵盤快捷鍵系統，**必須保留**，它含大寫 "Combos"）。所以**不要** grep 泛用的 `Combo`/`combos`，改用下面這串只針對 Command-Combo 專屬識別字（case-sensitive）：

Run:
```bash
grep -nE "ComboEntry|ComboStyle|ComboInputEditor|comboStyle|buildCombosTab|comboTable|comboStylePopup|rebuildComboRows|filteredComboIndices|editComboInputs|addCombo|deleteCombo|comboPrefixConflicts|comboNameChanged|comboPromptChanged|mapping\.combos|case \.combos" Sources/ClaudeGamepad/SettingsWindow.swift
```
Expected: **無任何輸出**（全部刪乾淨）。若有輸出，看是哪一行漏刪，修到無輸出為止。確認 `mapping.guideKeyCombosMap`（line 1377）**仍在**。

- [ ] **Step 11: Commit**

```bash
git add Sources/ClaudeGamepad/SettingsWindow.swift
git commit -m "$(cat <<'EOF'
refactor: remove Command Combos settings tab and ComboInputEditor (by Claude)
EOF
)"
```

---

## Task 4: ButtonMapping + default_config — 移除 model 欄位

**Files:**
- `Sources/ClaudeGamepad/ButtonMapping.swift`
- `Sources/ClaudeGamepad/Resources/default_config.json`

**前置：** Task 1、2、3 完成（此時已無任何 consumer 引用 `combos`/`comboStyle`/`ComboEntry`/`ComboStyle`）。
**保留 `ComboInput` enum 不動。**

- [ ] **Step 1: 刪除 `ComboStyle` enum**

old_string:
```swift
/// Command combo input style.
enum ComboStyle: String, Codable, CaseIterable {
    case fighting = "Fighting Game"
    case helldivers = "Helldivers 2"
}

```
new_string:（空字串，整段刪除）
```swift

```

- [ ] **Step 2: 刪除 `ComboEntry` struct**

old_string:
```swift
/// A command combo: a sequence of inputs that triggers a prompt.
struct ComboEntry: Codable {
    var name: String
    var inputs: [ComboInput]
    var prompt: String
    var style: ComboStyle

    /// Display string for the input sequence.
    var inputDisplay: String {
        inputs.map(\.rawValue).joined(separator: " ")
    }
}

```
new_string:（整段刪除）
```swift

```

- [ ] **Step 3: 刪除 `defaultCombos` static**

old_string（從 `    static let defaultCombos: [ComboEntry] = [` 到該陣列結尾的 `]`，約 284–298 行）:
```swift
    static let defaultCombos: [ComboEntry] = [
        // Helldivers-style (d-pad only)
        ComboEntry(name: "Reinforce", inputs: [.up, .down, .right, .left, .up], prompt: "fix all the errors", style: .helldivers),
        ComboEntry(name: "Resupply", inputs: [.down, .down, .up, .right], prompt: "add the missing dependencies", style: .helldivers),
        ComboEntry(name: "Air Strike", inputs: [.up, .right, .down, .right], prompt: "delete all unused code", style: .helldivers),
        ComboEntry(name: "Shield", inputs: [.down, .up, .left, .right], prompt: "add error handling to this", style: .helldivers),
        ComboEntry(name: "Orbital", inputs: [.right, .right, .up], prompt: "refactor this completely", style: .helldivers),
        ComboEntry(name: "EAT", inputs: [.up, .down, .left, .up, .right], prompt: "write comprehensive tests", style: .helldivers),
        // Fighting-game-style (directions + face button finisher)
        ComboEntry(name: "Hadouken", inputs: [.down, .right, .a], prompt: "run the tests", style: .fighting),
        ComboEntry(name: "Shoryuken", inputs: [.right, .down, .right, .a], prompt: "fix the bug", style: .fighting),
        ComboEntry(name: "Tatsumaki", inputs: [.down, .left, .b], prompt: "explain this code", style: .fighting),
        ComboEntry(name: "Sonic Boom", inputs: [.left, .right, .x], prompt: "looks good, commit this", style: .fighting),
        ComboEntry(name: "Super", inputs: [.down, .right, .down, .right, .a], prompt: "find and fix all bugs in this file", style: .fighting),
    ]

```
new_string:（整段刪除）
```swift

```

- [ ] **Step 4: 移除 `.default` static fallback 裡的 combo 引數**

old_string:
```swift
            buttonActions: .default,
            guideKeyCombosMap: [
                "start": [KeyCombo(key: "G", command: true)],
                "select": [KeyCombo(key: "T", command: true)],
                "lb": [KeyCombo(key: "W", command: true)],
            ],
            controllerStyle: .ps5,
            comboStyle: .helldivers,
            combos: defaultCombos
        )
```
new_string:
```swift
            buttonActions: .default,
            guideKeyCombosMap: [
                "start": [KeyCombo(key: "G", command: true)],
                "select": [KeyCombo(key: "T", command: true)],
                "lb": [KeyCombo(key: "W", command: true)],
            ],
            controllerStyle: .ps5
        )
```

- [ ] **Step 5: 移除 model 屬性宣告 `comboStyle` / `combos`**

old_string:
```swift
    // MARK: - Command Combos

    var comboStyle: ComboStyle
    var combos: [ComboEntry]

    // MARK: - Left Stick
```
new_string:
```swift
    // MARK: - Left Stick
```

- [ ] **Step 6: 移除 `init(...)` 的 combo 參數與賦值**

old_string:
```swift
         buttonActions: ButtonActions, guideKeyCombosMap: [String: [KeyCombo]],
         controllerStyle: ControllerStyle,
         comboStyle: ComboStyle, combos: [ComboEntry],
         leftStickMode: LeftStickMode = .scroll, mouseSpeed: Float = 1200) {
```
new_string:
```swift
         buttonActions: ButtonActions, guideKeyCombosMap: [String: [KeyCombo]],
         controllerStyle: ControllerStyle,
         leftStickMode: LeftStickMode = .scroll, mouseSpeed: Float = 1200) {
```

old_string:
```swift
        self.controllerStyle = controllerStyle
        self.comboStyle = comboStyle
        self.combos = combos
        self.leftStickMode = leftStickMode
```
new_string:
```swift
        self.controllerStyle = controllerStyle
        self.leftStickMode = leftStickMode
```

- [ ] **Step 7: 移除 `CodingKeys` 的 combo keys**

old_string:
```swift
        case controllerStyle, comboStyle, combos
        case leftStickMode, mouseSpeed
```
new_string:
```swift
        case controllerStyle
        case leftStickMode, mouseSpeed
```

- [ ] **Step 8: 移除 `encode(to:)` 的 combo 編碼**

old_string:
```swift
        try container.encode(controllerStyle, forKey: .controllerStyle)
        try container.encode(comboStyle, forKey: .comboStyle)
        try container.encode(combos, forKey: .combos)
        try container.encode(leftStickMode, forKey: .leftStickMode)
```
new_string:
```swift
        try container.encode(controllerStyle, forKey: .controllerStyle)
        try container.encode(leftStickMode, forKey: .leftStickMode)
```

- [ ] **Step 9: 移除 `init(from:)` 的 combo 解碼**

old_string:
```swift
        controllerStyle = try container.decodeIfPresent(ControllerStyle.self, forKey: .controllerStyle) ?? .xbox
        comboStyle = try container.decode(ComboStyle.self, forKey: .comboStyle)
        combos = try container.decode([ComboEntry].self, forKey: .combos)
        leftStickMode = try container.decodeIfPresent(LeftStickMode.self, forKey: .leftStickMode) ?? .scroll
```
new_string:
```swift
        controllerStyle = try container.decodeIfPresent(ControllerStyle.self, forKey: .controllerStyle) ?? .xbox
        leftStickMode = try container.decodeIfPresent(LeftStickMode.self, forKey: .leftStickMode) ?? .scroll
```

- [ ] **Step 10: 從 `default_config.json` 移除 `comboStyle` 與 `combos`**

讀 `Sources/ClaudeGamepad/Resources/default_config.json` 結尾。把 `controllerStyle` 之後的 `comboStyle` 與整個 `combos` 陣列刪掉，並確保 `controllerStyle` 變成最後一個 key（去掉它後面的逗號）。

old_string:
```json
  "controllerStyle": "PS5",
  "comboStyle": "Helldivers 2",
  "combos": [
```
…到檔案結尾的 `]` 與 `}`。實際操作：用 Edit 把
```json
  "controllerStyle": "PS5",
```
和其後到結尾 `}` 之前的所有 combo 內容，整理成：
```json
  "controllerStyle": "PS5"
}
```
（即 `controllerStyle` 後面不要逗號，直接接 `}`，中間的 `comboStyle` 行與 `combos: [...]` 整塊刪除。）

- [ ] **Step 11: 驗證**

Run: `python3 -m json.tool Sources/ClaudeGamepad/Resources/default_config.json > /dev/null && echo JSON_OK`
Expected: `JSON_OK`

Run: `swift build -c release 2>&1 | tail -5`
Expected: `Build complete!`

Run: `grep -rc "ComboEntry\|ComboStyle\|comboStyle\|\.combos\b\|defaultCombos" Sources/ClaudeGamepad/*.swift | grep -v ":0" || echo ALL_ZERO`
Expected: `ALL_ZERO`（`ComboInput` 不算，它保留）

- [ ] **Step 12: Commit**

```bash
git add Sources/ClaudeGamepad/ButtonMapping.swift Sources/ClaudeGamepad/Resources/default_config.json
git commit -m "$(cat <<'EOF'
refactor: drop combos/comboStyle from model and default config

ComboEntry and ComboStyle removed; ComboInput kept as the d-pad
direction type. Existing user configs with combo keys decode fine
(ignored). (by Claude)
EOF
)"
```

---

## Task 5: req 2 — LT 的 cheat sheet 底部加 `LB → ⌘⌥ Typeless`

**Files:**
- `Sources/ClaudeGamepad/OverlayPanel.swift`（`showPromptSheet` 加 `extraHint`）
- `Sources/ClaudeGamepad/GamepadManager.swift`（`showTriggerCheatSheet` 傳 hint）

**前置：** Task 1（建立了 `showTriggerCheatSheet`）、Task 2 完成。

- [ ] **Step 1: `showPromptSheet` 加 `extraHint` 參數**

old_string:
```swift
    func showPromptSheet(label: String, labels: ControllerLabels, prompts: [(button: String, prompt: String)]) {
```
new_string:
```swift
    func showPromptSheet(label: String, labels: ControllerLabels, prompts: [(button: String, prompt: String)], extraHint: String? = nil) {
```

- [ ] **Step 2: 在版面常數區加 hint 尺寸**

old_string:
```swift
            let sideCardMaxW: CGFloat = 200
            let tbCardMaxW: CGFloat = 260
```
new_string:
```swift
            let sideCardMaxW: CGFloat = 200
            let tbCardMaxW: CGFloat = 260
            let hintH: CGFloat = 18
            let hintGap: CGFloat = 8
            let hintExtra: CGFloat = extraHint == nil ? 0 : (hintH + hintGap)
```

- [ ] **Step 3: panelHeight 與 cyBase 預留 hint 空間**

old_string:
```swift
            let panelHeight = outerPad + titleH + titleGap + cardY.size.height + cardGap + sideRowH + cardGap + cardA.size.height + outerPad
```
new_string:
```swift
            let panelHeight = outerPad + titleH + titleGap + cardY.size.height + cardGap + sideRowH + cardGap + cardA.size.height + hintExtra + outerPad
```

old_string:
```swift
            let cyBase = outerPad + cardA.size.height + cardGap
```
new_string:
```swift
            let cyBase = outerPad + hintExtra + cardA.size.height + cardGap
```

- [ ] **Step 4: 在 cards 都加完之後、設定 container frame 之前，加上 hint label**

old_string:
```swift
            promptSheetContainer.frame = NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight)
            setContentSize(NSSize(width: panelWidth, height: panelHeight))
            effectView.frame = NSRect(origin: .zero, size: NSSize(width: panelWidth, height: panelHeight))

            positionOnScreen()
            orderFrontRegardless()
            alphaValue = 1
        }
    }

    /// Show command mode overlay
```

> ⚠️ 注意：Task 2 已刪掉 `showCommandMode`，所以上面 old_string 最後一行 `/// Show command mode overlay` 已不存在。**改用下面這個較短的 old_string**（只匹配 showPromptSheet 結尾，不含後面註解）：

old_string:
```swift
            promptSheetContainer.frame = NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight)
            setContentSize(NSSize(width: panelWidth, height: panelHeight))
            effectView.frame = NSRect(origin: .zero, size: NSSize(width: panelWidth, height: panelHeight))

            positionOnScreen()
            orderFrontRegardless()
            alphaValue = 1
        }
    }
```
new_string:
```swift
            if let extraHint {
                let hintField = NSTextField(labelWithString: extraHint)
                hintField.font = NSFont.systemFont(ofSize: 12, weight: .medium)
                hintField.textColor = NSColor.white.withAlphaComponent(0.6)
                hintField.alignment = .center
                hintField.frame = NSRect(x: outerPad, y: outerPad, width: panelWidth - outerPad * 2, height: hintH)
                promptSheetContainer.addSubview(hintField)
            }

            promptSheetContainer.frame = NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight)
            setContentSize(NSSize(width: panelWidth, height: panelHeight))
            effectView.frame = NSRect(origin: .zero, size: NSSize(width: panelWidth, height: panelHeight))

            positionOnScreen()
            orderFrontRegardless()
            alphaValue = 1
        }
    }
```

> 註：這個 old_string 在檔案中應為唯一（showPromptSheet 是唯一這樣結尾的 method）。若 Edit 報「not unique」，把 old_string 往前多帶幾行（例如連同前一個 `promptSheetContainer.addSubview(cardB.view)`）以確保唯一。

- [ ] **Step 5: GamepadManager 的 `showTriggerCheatSheet` 對 LT 傳入 hint**

old_string:
```swift
    /// Show the LT/RT quick-prompt cheat sheet for the given trigger.
    private func showTriggerCheatSheet(isLT: Bool) {
        let prompts = isLT ? mapping.ltPrompts : mapping.rtPrompts
        let labels = mapping.labels
        let triggerLabel = isLT ? labels.lt : labels.rt
        overlay.showPromptSheet(label: triggerLabel, labels: labels, prompts: [
            ("a", prompts.a),
            ("b", prompts.b),
            ("x", prompts.x),
            ("y", prompts.y),
        ])
    }
```
new_string:
```swift
    /// Show the LT/RT quick-prompt cheat sheet for the given trigger.
    private func showTriggerCheatSheet(isLT: Bool) {
        let prompts = isLT ? mapping.ltPrompts : mapping.rtPrompts
        let labels = mapping.labels
        let triggerLabel = isLT ? labels.lt : labels.rt
        // Only LT has the LB → ⌘⌥ chord; show it as a footer hint on the LT sheet.
        let hint = isLT ? "\(labels.lb) → ⌘⌥ Typeless" : nil
        overlay.showPromptSheet(label: triggerLabel, labels: labels, prompts: [
            ("a", prompts.a),
            ("b", prompts.b),
            ("x", prompts.x),
            ("y", prompts.y),
        ], extraHint: hint)
    }
```

- [ ] **Step 6: 驗證**

Run: `swift build -c release 2>&1 | tail -5`
Expected: `Build complete!`

- [ ] **Step 7: Commit**

```bash
git add Sources/ClaudeGamepad/OverlayPanel.swift Sources/ClaudeGamepad/GamepadManager.swift
git commit -m "$(cat <<'EOF'
feat: show LB -> Cmd+Option hint at bottom of LT cheat sheet

LT's quick-prompt overlay now displays the LT+LB Typeless chord as a
footer line. RT's sheet is unchanged. (by Claude)
EOF
)"
```

---

## 附錄 — 測試（Task 5 後一次做）

1. 重包 + 安裝（Plan 1 附錄那套）：
   ```bash
   ./build-app.sh && cp -R ClaudeGamepad.app /Applications/
   ```
   → Accessibility 關開 → 重啟 app。
2. **Combo Mode 已消失**：開 Settings，側欄不該再有「Command Combos」分頁。
3. **LT+RT toggle**：同時按 LT+RT → `🖱️ Mouse mode ON`；再按 → OFF。不再出現任何 combo 輸入畫面。
4. **LT+LB hint**：按住 LT → cheat sheet 底部出現 `LB → ⌘⌥ Typeless`（PS5 風格會顯示 `L1 → ⌘⌥ Typeless`）。按住 RT 的 sheet 不該有這行。
5. **回歸**：LT+ABXY、RT+ABXY 的 quick prompts 正常；d-pad 方向鍵正常；LT+LB 仍會觸發 Typeless。

> 既有個人 config（`~/Library/.../config.json`）裡殘留的 `combos`/`comboStyle` key 會被忽略，不會出錯，不用手動清。
