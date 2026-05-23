# ClaudeGamepad — Session Handover

**Date:** 2026-05-22 (updated)
**Branch:** `add-always-allow` (fork: `henryyangHY/ClaudeGamepad`)
**Repo path:** `~/Documents/Claude/projects/ClaudeGamepad`
**Build command:** `swift build -c release && .build/release/ClaudeGamepad`

---

## 專案背景

把 8BitDo Xbox 搖桿改造成 Claude Code vibe-coding 鍵盤。基礎是 fork 自 `cch123/ClaudeGamepad`，在此之上新增：

1. **Always Allow 按鈕**：按一下送出 `2` + Enter，選 Claude Code 許可對話框的「Yes, don't ask again」
2. **L3 / R3 獨立設定**：原版 L3/R3 共用一個 action，現在分開
3. **L3 = Typeless 語音（⌘⌥ modifier-only hotkey）**
4. **R3 = /clear**
5. **modifier-only combo 支援**（只有 modifier 鍵、無字母鍵）

---

## 本次 Session 完成的工作

### 已 commit & pushed (commit `2d8185c`, branch `add-always-allow`)

所有 Swift 改動一次 commit，包含：

- `ButtonMapping.swift`：`alwaysAllow` case、L3/R3 拆分、`KeyCombo` 擴充
- `GamepadConfigView.swift`：stickR slot、modifier-only combo fix
- `GamepadManager.swift`：`alwaysAllow` case、L3/R3 handlers、**LT 閾值 0.3 → 0.1**
- `KeySimulator.swift`：`typeAlwaysAllow()`、`tapModifiers()`、`pressCombo()` modifier-only 分支
- `Resources/default_config.json`：`stickClick` 拆成 `leftStickClick` + `rightStickClick`
- `SettingsWindow.swift`：新欄位對應
- `SpeechEngine.swift`：完全替換成 no-op stub（macOS 26 TCC crash fix）

### Config 修正（user config.json）

**路徑：** `~/Library/Application Support/ClaudeGamepad/config.json`

改動：
- `lb` action：`"Combo"` (⌘W ← 危險！) → `"Always Allow (2 + Enter)"`
- `start` combo：`⌘G` → `⌘T`（開新 tab）
- `select` action：`"Combo"` (⌘T) → `"None"`（使用者尚未決定用途）

---

## 目前 User Config 狀態

```
buttonActions:
  a               → Enter
  b               → Ctrl+C
  x               → Accept (y+Enter)
  y               → Reject (n+Enter)
  lb              → Always Allow (2 + Enter)  ← 已修正
  rb              → Escape
  start (Menu ≡)  → Combo → ⌘T (開新 tab)   ← 已修正
  select (View ⊞) → None                     ← 暫停用，使用者未決定
  leftStickClick  → Combo → ⌘⌥ (Typeless)
  rightStickClick → /clear

guideKeyCombosMap:
  "lb"             : ⌘W    ← config 裡還有此 entry 但 lb 已改為 Always Allow，不會觸發
  "start"          : ⌘T    ← 開新 tab
  "leftStickClick" : ⌘⌥   ← Typeless 語音（modifier-only）
```

---

## 已知問題（剩餘待驗證）

### 問題：LT + A / LT + B 組合鍵（需實機測試）

**修正狀態：** 已把 LT 閾值從 0.3 降到 0.1，理論上應該修好了。

**現象（修前）**：按住 LT trigger 再按 A 或 B，沒有把 ltPrompt 文字送到 terminal。  
**根因推測**：8BitDo LT trigger 的 analog value 可能低於原本的 0.3 threshold。  
**驗證方法**：
1. 啟動 app：`swift build -c release && .build/release/ClaudeGamepad`
2. 按住 LT（應出現 overlay cheat sheet 顯示 `codex / claude / copilot / gemini`）
3. 按 A → terminal 應輸入 `codex` + Enter
4. 按 B → terminal 應輸入 `claude` + Enter

如果 overlay 仍不出現 → 再把閾值改低到 0.05 試試。

---

## 下一個 Session 的優先任務

1. **實機測試 LT+A/B**：確認閾值修正有效
2. **決定 Select 的用途**：使用者尚未決定 View(⊞) 要做什麼
3. **（可選）ltPrompts 自訂**：目前是 `codex/claude/copilot/gemini`，考慮改成自己慣用的 slash commands 或提示詞

---

## Build & 執行方式

```bash
swift build -c release 2>&1 | tail -5
.build/release/ClaudeGamepad
```

第一次執行需要到 System Settings → Privacy & Security → Accessibility 手動新增 binary。

---

## 控制器 Layout 備忘（8BitDo Xbox style）

```
LT        RT
LB        RB
← Stick →    ← Stick →
  D-pad         A
           X       B
              Y
     View(⊞)  Menu(≡)
        L3    R3
```

- **View(⊞)** = `select` in code（目前 = None）
- **Menu(≡)** = `start` in code（目前 = ⌘T 開新 tab）
- **L3** = left thumbstick click（目前 = ⌘⌥ Typeless）
- **R3** = right thumbstick click（目前 = /clear）

---

## 補充：Speech.framework crash 記錄

macOS 26 在 non-bundled binary 中，只要 link 了 `Speech.framework`，啟動時 TCC 就會 crash（exit 134）。原版 `SpeechEngine.swift` 使用 SFSpeechRecognizer，已被完全替換成 no-op stub。若未來想重啟語音功能，需要：
- 改成 app bundle（有 Info.plist）
- 或改用 WhisperEngine（本機 whisper binary，不需 TCC）
