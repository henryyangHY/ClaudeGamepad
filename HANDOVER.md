# ClaudeGamepad — Session Handover

**Last session:** 2026-06-04
**Expected pickup:** ~2026-06-11 (約一週後)
**Branch:** `main` (origin: `henryyangHY/ClaudeGamepad`)
**Repo path:** `~/Documents/Claude/projects/ClaudeGamepad`
**Daily-use build:** `./build-app.sh` → produces `ClaudeGamepad.app`

---

## 一句話狀態

ROADMAP item 1~5 全部完成、combo/command mode 已徹底移除、README 同步至現行行為。專案在 macOS 26、Opus 4.7 環境下可正常 build / 打包 / codesign,**剩 ROADMAP item 6(Controller Layout Diagram)未做**。

---

## Pickup 時請先跑這些指令喚醒記憶

```bash
cd ~/Documents/Claude/projects/ClaudeGamepad
git log --oneline -10              # 看最近 commit
cat ROADMAP.md | head -120         # 看待辦
swift build                         # 驗證可編譯
./build-app.sh                      # 打 .app(可選)
```

如果忘了現在按鍵映射,直接看 `README-zh.md` 的「預設按鍵對應」表(這次 session 剛同步過)。

---

## 本次 Session(2026-06-04)做了什麼

### 1. 驗收 ROADMAP item 1~5(全部對得上 commit)

| # | 功能 | 對應 commit |
|---|---|---|
| 1 | L3 → Left Click | `2a46e6a` + `60f0cf3` (osascript → CGEvent 修正) |
| 2 | LT+LB → ⌘⌥ Typeless + LT cheat sheet hint | `2956fa3` + `dee341e` |
| 3 | Menu(Start)→ ⌘⇧] 下個分頁 | `2e7c6d4` + `12a9b1d` (符號鍵修正) |
| 4 | R3 → ⌘W 關閉 | `e32b6e0` |
| 5 | LT+RT tap → 切換 mouse mode | `aa0ba27` |

外加大型 refactor(`b611a36` + `4e6014d` + `5d1dd53` + `1892660`):combo / command mode 從 runtime、UI、model、default config 全部移除。`ComboInputEditor`、`Command Combos` tab、`showCommandMode` overlay、`combos` / `comboStyle` 欄位都不存在了。`SettingsWindow` 現在 4 個 tab(General / Button Mapping / Prompts / Speech)。

### 2. 驗證 build & 打包

- `swift build`(debug)✅
- `./build-app.sh`(release + ad-hoc sign)✅
- `codesign --verify` ✅ valid on disk / satisfies DR
- `default_config.json` / `default_speech_settings.json` 解析正常
- Sources/ 全無 combo-mode 殘留引用

### 3. 同步兩份 README(本次唯一未 commit 的改動)

兩份 README 之前還在描述「Command combos / 指令連招」、L3/R3 = Voice input、五個 tab、`showtime / fix the failing tests` 等舊預設。已全部改成現行行為:

- Default Button Mapping 表完整重寫
- Quick Prompts 改成 `codex/claude/copilot/gemini`(LT)與 RT 的新 prompts
- 新增「Trigger Chords / 扳機和弦」section
- Configuration 改為 4 個 tab、移除 Command Combos 整節
- Voice Input 改述為「需手動指派 Voice Input action」
- 架構檔案結構補上 `AppResources.swift`、註記 `SpeechEngine` 是 stub

---

## 目前 default_config.json 按鍵映射

```
buttonActions:
  a, b, x, y      → Enter / Ctrl+C / Accept / Reject (不變)
  lb              → Combo → ⌘W (close)
  rb              → Escape
  start           → Combo → ⌘⇧] (next terminal tab)
  select          → Combo → ⌘T (new tab)
  leftStickClick  → Left Click   ← 之前是 Voice Input
  rightStickClick → Combo → ⌘W   ← 之前是 Voice Input
  dpad            → Arrow keys

trigger chords (寫在 GamepadManager 程式邏輯內,不在 config):
  LT + LB         → ⌘⌥ Typeless(tapModifiers)
  LT + RT (tap)   → toggle leftStickMode(scroll ↔ mouse,持久化)
  LT + RT + Select→ Quit override(安全閘)

LT prompts: codex / claude / copilot / gemini
RT prompts: run the tests / show me the diff / looks good, commit this and push / refactor this to be cleaner
```

⚠️ **個人 runtime config 可能不同**:`~/Library/Application Support/ClaudeGamepad/config.json` 是使用者層級 override,跟 repo 內的 `default_config.json` 可能不同步。若 pickup 時想看「我目前實際用的」,讀 `~/Library/Application Support/ClaudeGamepad/config.json`。

---

## Pickup 後的 ROADMAP

### 已完成
- [x] Item 1 — L3 mouse click
- [x] Item 2 — LT+LB → ⌘⌥ Typeless
- [x] Item 3 — Menu → terminal tab(⌘⇧])
- [x] Item 4 — R3 → ⌘W
- [x] Item 5 — LT+RT → toggle mouse mode

### 待辦

**Item 6 — Controller Layout Diagram in README**(ROADMAP.md 唯一剩下的項目)
- 用 SVG 在 Xbox/PS5 controller outline 上加 callout 標記每個按鍵預設動作
- 兩個變體:`screenshots/controller-layout-xbox.png` + `controller-layout-ps5.png`
- 放進 README.md / README-zh.md 的「Default Button Mapping」section **上方**
- 工具:Figma / Canva / 直接寫 SVG 都行
- 現成素材:`Sources/ClaudeGamepad/Resources/xbox.svg` + `ps5.svg`(可當底圖)

### 額外想到但 ROADMAP 沒寫的點

- 是否要把 `Voice Input` 重新預設綁到某個閒置按鍵?目前完全無預設綁定,新使用者不會發現有這功能。候選:LT+RB?或 Select(目前是 ⌘T,但 Start 已經是 ⌘⇧],分頁類功能有點冗)。
- `ButtonMapping.swift` line 236-237 in-code default 還是 `.voiceInput`(會被 JSON 覆寫),想清理可以順手改。
- README 的 "trigger combos" 用語在截圖標題還在,語意上指 LT/RT+face,沒問題,但若 Item 6 要新增 layout diagram 順手檢視一下是否需要術語統一。

---

## 環境 / 工具備忘

- **macOS 26** + Swift 6.x SPM。Xcode 不需要。
- **沒有 unit test**(此專案無 test target),驗證靠 build + 實機。
- **8BitDo Xbox style 手把** + 可能也測過 DualSense(`controllerStyle: "PS5"` 在 default config 裡)。
- Accessibility 每次換 binary 都要重新授權(`build-app.sh` 後 copy 到 /Applications/ 會踩到)。

---

## Commits 等待 push 到 origin

本次 session 結束時,`main` 領先 `origin/main` 6 個 commit(5 個既有 + 1 個本次的 README 同步):

```
dee341e feat: show LB -> Cmd+Option hint at bottom of LT cheat sheet
1892660 refactor: drop combos/comboStyle from model and default config
5d1dd53 refactor: remove Command Combos settings tab and ComboInputEditor (by Claude)
4e6014d refactor: remove showCommandMode overlay (combo mode gone) (by Claude)
b611a36 refactor: LT+RT toggles mouse mode, remove command-mode runtime
<本次>  docs: sync READMEs + HANDOVER to current behavior (by Claude)
```

(由本次 session 一併 push 到 origin/main。)
