# ClaudeGamepad ROADMAP — Subagent Implementation Plan (施工圖)

> **給協調者 (Henry) 的說明：** 這份施工圖把 `ROADMAP.md` 的 6 個 feature 拆成 6 個獨立 task。
> 你會**手動開啟不同 session**，每個 session 用 **Haiku**（Task 6 例外，見下）執行**一個** task，
> 做完 `swift build` 綠燈 + commit 後，再開下一個 session 做下一個 task（**循序執行，每步 commit**）。
> Claude 寫的內容標 `(by Claude)`。

**Goal:** 把 8BitDo Xbox 搖桿改造成更完整的 Claude Code 單手 vibe-coding 鍵盤，完成 ROADMAP 全部 6 項。

**Architecture:** App 是 SPM 純 Swift macOS menu-bar app。輸入流：`GCController` → `GamepadManager`（中央協調）→ `KeySimulator`（CGEvent / osascript 模擬鍵鼠）。按鍵綁定是 **config 驅動**：每個實體按鍵對應一個 `ButtonAction`；`.guideCombo`（顯示為 `"Combo"`）會去查 `guideKeyCombosMap[buttonKey]` 拿要送的快捷鍵。預設值放在 `Sources/ClaudeGamepad/Resources/default_config.json`，使用者個人設定覆蓋在 `~/Library/Application Support/ClaudeGamepad/config.json`。

**Tech Stack:** Swift 6 / SwiftPM、AppKit、GameController、Carbon HIToolbox、CGEvent。**無測試 target**——驗證靠 `swift build -c release` 編譯通過 + Henry 實機測試。

---

## ⚠️ 執行前必讀（每個 session 都套用）

把下面這段**完整貼進每個 Haiku session 的開場**，再貼上該 session 要做的 Task：

```
你是一個執行單一任務的工程師。背景：macOS Swift menu-bar app（SwiftPM），把遊戲手把改成 Claude Code 鍵盤。

規則：
1. 工作目錄：~/Documents/Claude/projects/ClaudeGamepad
2. 先跑 `git status`（應 clean）和 `git log --oneline -3`（確認前面的 task 已 commit）。若不 clean，停下來回報，不要硬改。
3. 只做我貼給你的「這一個 Task」。不要改其他檔案、不要 refactor、不要順手清理。
4. Swift 改動用 Edit tool 精準替換我給的 old_string → new_string。**照我給的 code 一字不差實作，不要「改良」、不要換寫法、不要加額外 commit**（例如：不要把 CGEvent 換成 osascript）。若你判斷我給的 code 有錯，停下來回報，不要默默改掉。
5. 驗證：跑 `swift build -c release 2>&1 | tail -5`，必須看到 `Build complete!`。JSON task 另外跑 `python3 -m json.tool <該檔> > /dev/null && echo JSON_OK`。
6. 【重要】不要嘗試執行 app、不要測手把輸入（這個 session 沒有手把、沒有 Accessibility 權限）。把「需要 Henry 實機測什麼」寫在回報裡。
7. 【重要】絕對不要動 ~/Library/Application Support/ClaudeGamepad/ 下的任何檔（那是使用者個人設定，由 Henry 手動處理）。
8. 驗證綠燈後，用我給的 commit message 做「一個」commit。
9. 回報格式：(a) 改了哪些檔 (b) build 結果 (c) Henry 要手動測的步驟。
```

### 🔁 實機測試前置（Henry 做，非 Haiku）

`swift build -c release` 只產出 CLI binary (`.build/release/ClaudeGamepad`)。**你日常跑的是 `.app` bundle，它不會被 `swift build` 更新**——所以任何改動 runtime 行為、或新增設定選項（例如新的 `ButtonAction`）的 task，做完後要在 app 裡看到效果，必須：

```bash
./build-app.sh                      # 重新打包 .app（含最新 binary + resources）
cp -R ClaudeGamepad.app /Applications/
# System Settings → Privacy & Security → Accessibility：把 ClaudeGamepad 關掉再打開（取代 binary 後 macOS 會撤銷 AX）
# 然後重新啟動 app
```

**教訓（Task 1 踩到）：** 只 `swift build` 後去測舊的 `.app`，會誤以為功能壞掉 / 新選項沒出現。

### 執行順序與依賴

| 順序 | Task | 性質 | 動到的檔 | 建議 model |
|------|------|------|---------|-----------|
| 1 | Task 1 — L3 Left Click | Swift + JSON | KeySimulator / ButtonMapping / GamepadManager / default_config.json | Haiku |
| 2 | Task 2 — LT+LB → ⌘⌥ Typeless | Swift | GamepadManager | Haiku |
| 3 | Task 3 — Menu → ⌘⇧] 下一個 tab | JSON | default_config.json | Haiku |
| 4 | Task 4 — R3 → ⌘W | JSON | default_config.json | Haiku |
| 5 | Task 5 — LT+RT tap → toggle mouse mode | Swift | GamepadManager | Haiku |
| 6 | Task 6 — Canva 控制器圖 + README | Canva MCP + 文件 | screenshots/ / README.md / README-zh.md | **Sonnet/Opus**（Canva 設計+匯出+嵌入，Haiku 偏吃力） |

- **必須照 1→6 順序**：Task 1/2/5 都改 `GamepadManager.swift`，循序避免衝突；Task 6 需要 1–5 的最終 mapping 才能畫圖。
- Task 1、3、4 都改 `default_config.json` 但各改不同行，循序執行零衝突。

### Branch 策略（Henry 一次性決定）

兩個選擇，擇一：
- **(預設) 直接在 `main` 上 6 個 commit。** 最簡單，適合單人。
- **開 feature branch**：執行 Task 1 前先 `git checkout -b feat/roadmap-impl`，6 個 commit 都在這條 branch，最後自行 merge / 開 PR。

下面每個 Task 的 commit 指令都用 `git commit`，不指定 branch（落在當前 branch）。

---

## Task 1: L3 → Left Click

**ROADMAP 對應：** Item 1。
**做什麼：** 新增一個可指派的 `ButtonAction.leftClick`，按下時在游標當前位置模擬一次滑鼠左鍵。並把預設 L3（左搖桿按壓）綁成這個 action。**簡化版**——不做「只有 mouse mode 啟用才 click」的條件判斷（左鍵點擊本身就泛用）。

**Files:**
- Modify: `Sources/ClaudeGamepad/KeySimulator.swift`（加 `mouseClick()`）
- Modify: `Sources/ClaudeGamepad/ButtonMapping.swift`（`ButtonAction` 加 case）
- Modify: `Sources/ClaudeGamepad/GamepadManager.swift`（`executeAction` switch 加 case）
- Modify: `Sources/ClaudeGamepad/Resources/default_config.json`（`leftStickClick` 預設改成 Left Click）

- [ ] **Step 1: 在 `KeySimulator.swift` 加 `mouseClick()`**

用 Edit。`KeySimulator.swift` 結尾有 `enum ArrowDirection`，把方法插在它前面。

> ⚠️ **照下面的 CGEvent 版實作，原封不動。** 不要改成 osascript（`tell application "System Events" to click` 沒有目標元素、會靜默失敗，根本不會在游標位置點擊）。CGEvent 才是 macOS 合成滑鼠點擊的正確做法，且和本檔其他方法（`pressKey`）一致。

old_string:
```swift
    enum ArrowDirection {
        case up, down, left, right
    }
```
new_string:
```swift
    /// Simulate a left mouse click at the current cursor position.
    /// Requires Accessibility permission (synthetic CGEvent posting).
    func mouseClick() {
        let source = CGEventSource(stateID: .hidSystemState)
        let pos = CGEvent(source: nil)?.location ?? .zero
        guard let down = CGEvent(mouseEventSource: source, mouseType: .leftMouseDown,
                                 mouseCursorPosition: pos, mouseButton: .left),
              let up = CGEvent(mouseEventSource: source, mouseType: .leftMouseUp,
                               mouseCursorPosition: pos, mouseButton: .left) else { return }
        down.post(tap: .cghidEventTap)
        usleep(12_000)
        up.post(tap: .cghidEventTap)
    }

    enum ArrowDirection {
        case up, down, left, right
    }
```

- [ ] **Step 2: 在 `ButtonMapping.swift` 的 `ButtonAction` enum 加 case**

用 Edit。

old_string:
```swift
    case guideCombo = "Combo"
    case quit = "Quit"
    case none = "None"
```
new_string:
```swift
    case guideCombo = "Combo"
    case leftClick = "Left Click"
    case quit = "Quit"
    case none = "None"
```

> 註：`ButtonAction` 是 `CaseIterable`，設定 UI（`GamepadConfigView`）用 `allCases` 自動列舉，所以這個新選項會**自動出現在設定下拉選單**，不用改 UI code。

- [ ] **Step 3: 在 `GamepadManager.swift` 的 `executeAction` switch 加 case**

用 Edit。（這是專案中唯一一個對 `ButtonAction` 做 exhaustive switch 的地方，不加會編譯失敗。）

old_string:
```swift
        case .guideCombo:
            onGuide(buttonKey: buttonKey)
```
new_string:
```swift
        case .guideCombo:
            onGuide(buttonKey: buttonKey)
        case .leftClick:
            overlay.showMessage("🖱️ Left Click", duration: 0.6)
            keys.mouseClick()
```

- [ ] **Step 4: 改 `default_config.json` 的 `leftStickClick` 預設**

用 Edit。

old_string:
```json
    "leftStickClick": "Voice Input",
```
new_string:
```json
    "leftStickClick": "Left Click",
```

- [ ] **Step 5: 驗證**

Run: `swift build -c release 2>&1 | tail -5`
Expected: `Build complete!`

Run: `python3 -m json.tool Sources/ClaudeGamepad/Resources/default_config.json > /dev/null && echo JSON_OK`
Expected: `JSON_OK`

- [ ] **Step 6: Commit**

```bash
git add Sources/ClaudeGamepad/KeySimulator.swift Sources/ClaudeGamepad/ButtonMapping.swift Sources/ClaudeGamepad/GamepadManager.swift Sources/ClaudeGamepad/Resources/default_config.json
git commit -m "$(cat <<'EOF'
feat: add Left Click action for stick-click (ROADMAP item 1)

Adds KeySimulator.mouseClick() and a new assignable ButtonAction.leftClick.
Defaults L3 (left stick click) to Left Click. (by Claude)
EOF
)"
```

**Henry 實機測試：** Settings → 把左搖桿模式設成 "Mouse Cursor"（或用 Task 5 的 LT+RT tap 開啟）→ 用左搖桿移動游標 → 按 L3 → 應在游標處點一下左鍵。

---

## Task 2: LT+LB → ⌘⌥ (Typeless 語音觸發)

**ROADMAP 對應：** Item 2。
**做什麼：** 讓「按住 LT 同時按 LB」送出 modifier-only 的 `⌘⌥`（Typeless 的喚醒熱鍵）。實作上在 `onLB()` 加一個 `ltHeld` 判斷。`KeySimulator.tapModifiers(...)` 已存在（送純 modifier chord），直接用。

> **設計取捨（已和 Henry 確認）：** `⌘⌥` 先 hardcode，不做成可設定。LT-held 時 overlay 顯示 "LB → ⌘⌥" 的 hint 先**不做**（會動到 `OverlayPanel.showPromptSheet` 那個複雜的 4-card diamond 佈局，YAGNI）；按下時的 `⚡ ⌘⌥ Typeless` 訊息已足夠回饋。

**Files:**
- Modify: `Sources/ClaudeGamepad/GamepadManager.swift`（改 `onLB()`）

- [ ] **Step 1: 改 `onLB()`**

用 Edit。

old_string:
```swift
    private func onLB() {
        executeAction(mapping.buttonActions.lb, buttonKey: "lb")
    }
```
new_string:
```swift
    private func onLB() {
        // LT + LB → ⌘⌥ (Typeless modifier-only voice trigger).
        // Only when LT is held alone (not in LT+RT command mode).
        if ltHeld && !isInCommandMode {
            overlay.showMessage("⚡ ⌘⌥ Typeless")
            keys.tapModifiers(command: true, control: false, option: true, shift: false)
            return
        }
        executeAction(mapping.buttonActions.lb, buttonKey: "lb")
    }
```

> 註：`ltHeld`、`isInCommandMode` 都是 `GamepadManager` 的 private 屬性，同檔可直接存取。`tapModifiers` 簽名為 `tapModifiers(command:control:option:shift:hold:)`，`hold` 有預設值。

- [ ] **Step 2: 驗證**

Run: `swift build -c release 2>&1 | tail -5`
Expected: `Build complete!`

- [ ] **Step 3: Commit**

```bash
git add Sources/ClaudeGamepad/GamepadManager.swift
git commit -m "$(cat <<'EOF'
feat: LT+LB fires Cmd+Option for Typeless (ROADMAP item 2)

onLB() now sends a modifier-only Cmd+Option chord when LT is held,
giving the left hand a dedicated voice-input trigger. (by Claude)
EOF
)"
```

**Henry 實機測試：** 按住 LT → 按 LB → overlay 顯示 `⚡ ⌘⌥ Typeless`，Typeless（或你綁 ⌘⌥ 的工具）被喚醒。單按 LB（不按 LT）行為不變（維持你 config 裡 lb 的動作）。

---

## Task 3: Menu (≡) → ⌘⇧] 切到下一個 tab

**ROADMAP 對應：** Item 3。
**做什麼：** 純改 `default_config.json`。`start`（Menu 鍵）的 action 已經是 `"Combo"`，只要把它的 combo 從 `⌘G` 改成 `⌘⇧]`（mirror cmux「下一個 tab」快捷鍵）。執行期 `pressCombo` 走 osascript `keystroke "]"`，所以 `]` 這個不在 keyCodeMap 的字元也能正常送。**不需改任何 Swift。**

**Files:**
- Modify: `Sources/ClaudeGamepad/Resources/default_config.json`（`guideKeyCombosMap.start`）

- [ ] **Step 1: 改 `guideKeyCombosMap` 的 `start` 項**

用 Edit。

old_string:
```json
    "start":  [{ "key": "G", "command": true, "control": false, "option": false, "shift": false }],
```
new_string:
```json
    "start":  [{ "key": "]", "command": true, "control": false, "option": false, "shift": true }],
```

- [ ] **Step 2: 驗證**

Run: `python3 -m json.tool Sources/ClaudeGamepad/Resources/default_config.json > /dev/null && echo JSON_OK`
Expected: `JSON_OK`

Run: `swift build -c release 2>&1 | tail -5`
Expected: `Build complete!`

- [ ] **Step 3: Commit**

```bash
git add Sources/ClaudeGamepad/Resources/default_config.json
git commit -m "$(cat <<'EOF'
feat: Menu key switches to next terminal tab via Cmd+Shift+] (ROADMAP item 3)

Mirrors cmux's next-tab shortcut. (by Claude)
EOF
)"
```

**Henry 實機測試：** 需先同步個人 config（見附錄 A）。在 cmux 多開幾個 tab → 按 Menu(≡) → 切到下一個 tab。

---

## Task 4: R3 → ⌘W (關閉視窗/tab)

**ROADMAP 對應：** Item 4。
**做什麼：** 純改 `default_config.json`。把 `rightStickClick`（R3）的 action 從 `"Voice Input"` 改成 `"Combo"`，並在 `guideKeyCombosMap` 加一筆 `rightStickClick` = `⌘W`。**不需改任何 Swift。**

**Files:**
- Modify: `Sources/ClaudeGamepad/Resources/default_config.json`（`buttonActions.rightStickClick` + `guideKeyCombosMap`）

- [ ] **Step 1: 改 `rightStickClick` 的 action**

用 Edit。

old_string:
```json
    "rightStickClick": "Voice Input",
```
new_string:
```json
    "rightStickClick": "Combo",
```

- [ ] **Step 2: 在 `guideKeyCombosMap` 加 `rightStickClick` 項**

用 Edit。注意：Task 3 已把 `start` 那行改過，這裡用 `select` 那行當錨點，在它後面加新項並補逗號。

old_string:
```json
    "select": [{ "key": "T", "command": true, "control": false, "option": false, "shift": false }],
    "lb":     [{ "key": "W", "command": true, "control": false, "option": false, "shift": false }]
```
new_string:
```json
    "select": [{ "key": "T", "command": true, "control": false, "option": false, "shift": false }],
    "lb":     [{ "key": "W", "command": true, "control": false, "option": false, "shift": false }],
    "rightStickClick": [{ "key": "W", "command": true, "control": false, "option": false, "shift": false }]
```

- [ ] **Step 3: 驗證**

Run: `python3 -m json.tool Sources/ClaudeGamepad/Resources/default_config.json > /dev/null && echo JSON_OK`
Expected: `JSON_OK`

Run: `swift build -c release 2>&1 | tail -5`
Expected: `Build complete!`

- [ ] **Step 4: Commit**

```bash
git add Sources/ClaudeGamepad/Resources/default_config.json
git commit -m "$(cat <<'EOF'
feat: R3 (right stick click) defaults to Cmd+W close (ROADMAP item 4)

Frees R3 from voice input now that voice lives on LT+LB. (by Claude)
EOF
)"
```

> **⚠️ 給 Henry 的旗標（不在本 task 範圍）：** `default_config.json` 裡 `lb` 也還是 `⌘W`。R3 改成 `⌘W` 後，預設出現 LB 和 R3 都是 ⌘W 的冗餘（而且你之前覺得 LB→⌘W「危險」所以個人 config 改成 Always Allow）。要不要順手改掉預設 LB，由你決定，本 task 不動它。

**Henry 實機測試：** 需先同步個人 config（見附錄 A）。按 R3 → 當前視窗/tab 關閉（⌘W）。

---

## Task 5: LT+RT「輕點」→ 切換 mouse mode

**ROADMAP 對應：** Item 5（已選定動作 = toggle mouse mode）。
**做什麼：** 目前「同時按住 LT+RT」會進 command/combo mode。新增：若 LT+RT **快速輕點後放開**（沒有輸入任何 combo），就切換 `leftStickMode`（scroll ⇄ mouse），而不是普通退出 command mode。靠在進入 command mode 時記時間戳、退出時判斷「停留很短 + combo buffer 為空」。只動 `GamepadManager.swift`。

**Files:**
- Modify: `Sources/ClaudeGamepad/GamepadManager.swift`（加屬性、改 `enterCommandMode`、改 `onTriggerChanged` 退出分支、加 `toggleMouseMode`）

- [ ] **Step 1: 加一個時間戳屬性**

用 Edit。在現有 `ltHeld`/`rtHeld` 宣告後面加。

old_string:
```swift
    private var ltHeld = false
    private var rtHeld = false
```
new_string:
```swift
    private var ltHeld = false
    private var rtHeld = false
    private var commandModeEnteredAt: TimeInterval = 0
    private let mouseTapThreshold: TimeInterval = 0.30
```

- [ ] **Step 2: 在 `enterCommandMode()` 記錄進入時間**

用 Edit。

old_string:
```swift
    private func enterCommandMode() {
        isInCommandMode = true
        comboBuffer = []
        comboTimer?.invalidate()
        overlay.showCommandMode(inputs: [], combos: activeCombos, style: mapping.comboStyle, labels: mapping.labels)
    }
```
new_string:
```swift
    private func enterCommandMode() {
        commandModeEnteredAt = ProcessInfo.processInfo.systemUptime
        isInCommandMode = true
        comboBuffer = []
        comboTimer?.invalidate()
        overlay.showCommandMode(inputs: [], combos: activeCombos, style: mapping.comboStyle, labels: mapping.labels)
    }
```

- [ ] **Step 3: 改 `onTriggerChanged` 的「離開 command mode」分支**

用 Edit。把現有那段（偵測到一個 trigger 放開、退出 command mode）整段換掉，加入 tap 偵測。

old_string:
```swift
        // Leaving command mode: one trigger released
        if !bothNow && bothBefore && isInCommandMode {
            exitCommandMode()
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
```
new_string:
```swift
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
```

- [ ] **Step 4: 加 `toggleMouseMode()` 方法**

用 Edit。緊接在 `exitCommandMode()` 方法後面加（`exitCommandMode` 在 `// MARK: - Command Mode` 區塊內）。

old_string:
```swift
    private func exitCommandMode() {
        isInCommandMode = false
        comboBuffer = []
        comboTimer?.invalidate()
        comboTimer = nil
        overlay.fadeOut()
    }
```
new_string:
```swift
    private func exitCommandMode() {
        isInCommandMode = false
        comboBuffer = []
        comboTimer?.invalidate()
        comboTimer = nil
        overlay.fadeOut()
    }

    /// Toggle the left stick between scroll and mouse-cursor mode, persisting the choice.
    private func toggleMouseMode() {
        let newMode: LeftStickMode = mapping.leftStickMode == .mouse ? .scroll : .mouse
        mapping.leftStickMode = newMode
        mapping.save()
        if newMode != .mouse {
            mouseTimer?.invalidate()
            mouseTimer = nil
        }
        overlay.showMessage(newMode == .mouse ? "🖱️ Mouse mode ON" : "🖱️ Mouse mode OFF")
    }
```

> 註：`mapping` 是可變屬性 (`private var mapping = ButtonMapping.load()`)；`mapping.save()` 已存在、會把整份設定寫回 config.json。`mouseTimer`、`LeftStickMode` 都在同 module，可直接用。

- [ ] **Step 5: 驗證**

Run: `swift build -c release 2>&1 | tail -5`
Expected: `Build complete!`

- [ ] **Step 6: Commit**

```bash
git add Sources/ClaudeGamepad/GamepadManager.swift
git commit -m "$(cat <<'EOF'
feat: LT+RT tap toggles left-stick mouse mode (ROADMAP item 5)

A quick LT+RT tap (no combo input, under 300ms) flips leftStickMode
between scroll and mouse cursor, persisted to config. Holding LT+RT
still enters command mode as before. (by Claude)
EOF
)"
```

**Henry 實機測試：** 快速「點一下」LT+RT 一起按再放 → overlay 顯示 `🖱️ Mouse mode ON`，左搖桿改成移動游標；再點一下 → `OFF`。**按住** LT+RT 不放 → 仍進 command/combo mode（行為不變）。若覺得「放開一個 trigger 想看單 trigger cheat sheet」時會誤觸發 toggle，把 `mouseTapThreshold` 從 0.30 調小（如 0.22）。

---

## Task 6: Canva 控制器佈局圖 + README 嵌入

**ROADMAP 對應：** Item 6。
**前置：** Task 1–5 必須先完成（圖要反映最終 mapping）。
**建議 model：Sonnet/Opus**，且預期要和 Canva 來回迭代幾次調設計。Haiku 跑 Canva MCP 設計+匯出+下載+嵌入這條鏈偏吃力。

**做什麼：** 用 **Canva MCP** 產一張漂亮的 Xbox 手把佈局圖（每個按鍵標註它對應的動作），匯出 PNG 存進 `screenshots/`，再在 `README.md` 和 `README-zh.md` 的按鍵對照表「上方」加一個「Controller Layout」段嵌入這張圖。

**最終按鍵 mapping（餵給 Canva 當標註內容；這是 Task 1–5 完成後的 default 狀態）：**

| 實體按鍵 (Xbox) | 動作 |
|----------------|------|
| A | Enter（confirm）|
| B | Ctrl+C（interrupt）|
| X | Accept（y + Enter）|
| Y | Reject（n + Enter）|
| LB | ⌘W（預設；可在設定改）|
| RB | Escape |
| LT（按住）+ A/B/X/Y | Quick prompts：codex / claude / copilot / gemini |
| RT（按住）+ A/B/X/Y | Quick prompts：run tests / show diff / commit+push / refactor |
| **LT + LB** | **⌘⌥（Typeless 語音）← 新** |
| LT + RT（按住）| Command / Combo mode |
| **LT + RT（輕點）** | **Toggle mouse mode ← 新** |
| **Menu (≡)** | **⌘⇧]（下一個 tab）← 新** |
| View (⊞) | ⌘T（新 tab，預設）|
| **L3（左搖桿按壓）** | **Left Click ← 新** |
| **R3（右搖桿按壓）** | **⌘W（關閉）← 新** |
| 左搖桿 | 捲動 ↑↓（mouse mode 時 = 移動游標）|
| D-pad | 方向鍵 ↑↓←→ |

**Files:**
- Create: `screenshots/controller-layout.png`（Canva 匯出）
- Modify: `README.md`
- Modify: `README-zh.md`

- [ ] **Step 1: 用 Canva MCP 產圖**

用 Canva MCP 的 `generate-design`（或 `generate-design-structured`）。Prompt 要點：
- 一個橫向 Xbox 風格遊戲手把的乾淨向量插圖。
- 每個按鍵旁拉 callout 標籤，內容用上表的「動作」欄。
- 把 4 個「新」綁定（LT+LB、LT+RT tap、Menu、L3、R3）用不同顏色/高亮標出來。
- 標題：`ClaudeGamepad — Controller Layout`。
- 風格：深色背景、現代、開發者工具感，和現有 `screenshots/*.png` 調性一致。

產完用 `export-design` 匯出 PNG，下載並存成 `screenshots/controller-layout.png`。
（PS5 變體為 optional；要做就再產一張 `screenshots/controller-layout-ps5.png`，README 可放兩張或用 tab。）

- [ ] **Step 2: 在 `README.md` 加 Controller Layout 段**

找到 README 裡現有的按鍵對照表（mapping table）標題，在它**上方**插入：
```markdown
## Controller Layout

![ClaudeGamepad controller layout](screenshots/controller-layout.png)
```

- [ ] **Step 3: 在 `README-zh.md` 加對應段**

同樣在按鍵對照表上方插入：
```markdown
## 控制器佈局

![ClaudeGamepad 控制器佈局](screenshots/controller-layout.png)
```

- [ ] **Step 4: 驗證**

Run: `test -f screenshots/controller-layout.png && echo IMG_OK`
Expected: `IMG_OK`

Run: `grep -c "controller-layout.png" README.md README-zh.md`
Expected: 兩個檔各 `1`。

（這個 task 沒改 Swift，但仍可跑 `swift build -c release 2>&1 | tail -5` 確認沒誤動到 code。）

- [ ] **Step 5: Commit**

```bash
git add screenshots/controller-layout.png README.md README-zh.md
git commit -m "$(cat <<'EOF'
docs: add controller layout diagram to READMEs (ROADMAP item 6)

Canva-generated Xbox layout showing the full button mapping incl. the
new L3/R3/Menu/LT+LB/LT+RT bindings. (by Claude)
EOF
)"
```

**Henry 檢查：** 看圖好不好看、標註正不正確；README 預覽圖有顯示。

---

## 附錄 A — Henry 的手動步驟（個人 config 同步）

Task 3 / 4 / 1 改的是 repo 的 `default_config.json`（給全新安裝用）。**你本機已有個人設定** `~/Library/Application Support/ClaudeGamepad/config.json` 會覆蓋預設，所以要讓改動在你現在裝的 app 生效，**用 app 的 Settings UI** 做以下調整（最安全，不用手改 JSON）：

| 對應 Task | 在 Settings 改什麼 | 備註 |
|-----------|------------------|------|
| Task 1 | L3（左搖桿按壓）→ **Left Click** | 你個人 config 目前 L3 = **None**（所以按 L3 沒反應）。必須在重新打包的 app 設定裡改成 Left Click 才會生效。Typeless 已搬到 LT+LB（Task 2）|
| Task 4 | R3（右搖桿按壓）→ **Combo**，combo 設 **⌘W** | 你目前 R3 = /clear，會失去；想保留 /clear 可改綁別的鍵 |
| Task 3 | Menu → **Combo**，combo 設 **⌘⇧]** | 見下方限制；你目前 Menu = ⌘T（新 tab），會失去新 tab 綁定 |

**⚠️ Task 3 的 UI 限制：** 設定的 combo 按鍵選單（`KeyCombo.allKeys`）目前**只有字母/數字/F 鍵，沒有 `]`**，所以 `⌘⇧]` **無法用 UI 設**。兩個選項：
1. **手動編輯個人 config.json**：把 `guideKeyCombosMap` 裡的 `start` 改成
   ```json
   "start": [{ "key": "]", "command": true, "control": false, "option": false, "shift": true }]
   ```
   （改完重啟 app。檔案路徑：`~/Library/Application Support/ClaudeGamepad/config.json`）
2. **要我追加一個小 task**：在 `KeyCombo.allKeys` 加入 `]`、`[` 等符號鍵，讓 UI 可直接選（需要時跟我說，我補進施工圖）。

> 重置選項：若你願意放棄現有個人設定、直接吃新預設，刪掉 `~/Library/Application Support/ClaudeGamepad/config.json` 再重啟 app 即可（會以 `default_config.json` 重建）。

## 附錄 B — 已知限制 / 刻意取捨

- **無自動化測試**：手把輸入 + CGEvent + AX 權限無法在 session 內單元測試。每個 task 的自動驗證上限就是「`swift build` 編譯通過」；行為正確性靠 Henry 實機測。
- **Item 2 HUD hint 略過**：LT-held 時 overlay 沒加 "LB → ⌘⌥" 提示（避免動 `OverlayPanel` 複雜佈局）。
- **Item 1 簡化**：`.leftClick` 是無條件的可指派 action，沒做「只有 mouse mode 才 click」。
- **Item 5 threshold**：tap 偵測用 0.30s 門檻，可能和「放開一個 trigger 看單 trigger cheat sheet」輕微衝突，實機可調 `mouseTapThreshold`。
- **預設 LB=⌘W 冗餘**：Task 4 後 default LB 和 R3 都是 ⌘W，待 Henry 決定是否改 default LB。

## 附錄 C — 協調者 checklist（Henry 用）

- [ ] (選用) Task 1 前 `git checkout -b feat/roadmap-impl`
- [ ] Task 1 done + commit + 實機測 Left Click
- [ ] Task 2 done + commit + 實機測 LT+LB Typeless
- [ ] Task 3 done + commit
- [ ] Task 4 done + commit
- [ ] 同步個人 config（附錄 A）後實機測 Menu / R3
- [ ] Task 5 done + commit + 實機測 LT+RT tap
- [ ] Task 6（Sonnet/Opus）done + commit + 檢查圖與 README
- [ ] (選用) 更新 `ROADMAP.md` 把 6 項標為 done / 更新 `HANDOVER.md`
