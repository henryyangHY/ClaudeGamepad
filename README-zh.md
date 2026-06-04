# Claude Gamepad Controller

[![macOS](https://img.shields.io/badge/macOS-14.0%2B-orange)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5.9+-red)](https://swift.org/)
[![License](https://img.shields.io/badge/License-MIT-blue)](LICENSE)
[![GitHub Stars](https://img.shields.io/github/stars/henryyangHY/ClaudeGamepad?style=social)](https://github.com/henryyangHY/ClaudeGamepad)

原生 macOS 選單列 App，讓你用遊戲手把操控 [Claude Code](https://claude.ai/claude-code)。躺在沙發上 vibe coding。

支援 Xbox、PS5 DualSense 及所有 MFi 相容手把。內建語音輸入（Apple 系統語音辨識 / 本地 [whisper.cpp](https://github.com/ggerganov/whisper.cpp)），可選 LLM 語音修正。

## 為什麼要用 Claude Gamepad？

想躺在沙發上寫程式嗎？Claude Gamepad 讓遊戲手把成為 AI 輔助開發的利器。告別鍵盤前的僵硬坐姿，用手把操控 Claude Code，站著用、躺著用、怎麼舒服怎麼用。

**適合情境：**
- 有 RSI 或行動不便的開發者
- 站立辦公族
- 客廳程式開發
- 語音優先、雙手解放的工作流程

## 目錄

- [快速開始](#快速開始)
- [功能特色](#功能特色)
- [截圖](#截圖)
- [預設按鍵對應](#預設按鍵對應)
- [安裝](#安裝)
- [使用說明](#使用說明)
- [設定](#設定)
- [語音輸入](#語音輸入)
- [Vibe Island / 覆蓋層導航](#vibe-island--覆蓋層導航)
- [疑難排解](#疑難排解)
- [貢獻指引](#貢獻指引)
- [架構](#架構)
- [授權條款](#授權條款)

## 快速開始

5 分鐘內上手：

```bash
# 1. 複製並建置
git clone https://github.com/henryyangHY/ClaudeGamepad.git
cd ClaudeGamepad
./build-app.sh
cp -R ClaudeGamepad.app /Applications/

# 2. 開啟 App，依提示授予權限
#    - 輔助使用（必要，鍵盤 / 滑鼠模擬）
#    - 麥克風（選用，僅在綁定 Voice Input 按鍵時需要）
# 3. 連接手把，聚焦 Claude Code 終端機，開始編程！
```

## 功能特色

- **選單列常駐** — 背景執行，無 Dock 圖示
- **即插即用** — 透過 `GCController` 自動偵測 Xbox / PS5 / MFi 手把
- **Xbox / PS5 樣式切換** — 整個 UI 的按鍵文字與顏色可一鍵切換
- **全按鍵自訂** — 每個按鍵均可透過 GUI 設定面板調整
- **快捷指令** — LT/RT + 功能鍵發送預設 prompt，按住扳機時 HUD 自動顯示 cheat sheet
- **LT+LB 和弦** — 觸發 `⌘⌥`，可呼叫 Typeless 或任何吃此修飾鍵的覆蓋層
- **LT+RT 切換** — 同時點按兩個扳機切換左搖桿滑鼠模式
- **L3 左鍵點擊** — 按下左搖桿即可在游標位置左鍵點擊
- **覆蓋層導航** — 任一按鍵可設為 `Combo` 動作（如 `⌘W` 關閉、`⌘⇧]` 切下一個分頁），直接觸發快捷鍵
- **語音輸入** — 選用功能，將任一按鍵綁定 `Voice Input` 動作即可啟用
  - 本地 whisper.cpp（離線、高精確度）
  - 可選 LLM 修正（Ollama / OpenAI 相容介面）
- **預設選單** — 可設定的預設 prompt 清單，方向鍵導航
- **浮動 HUD** — 非侵入式懸浮層顯示按鍵回饋與轉錄結果
- **原生 macOS** — 純 Swift + AppKit，無 Electron，無 Python

## 截圖

### 按鍵對應

使用直覺式視覺化編輯器設定手把。所有按鍵按區域分組——肩鍵、功能鍵、導航鍵和系統鍵，快速掃描與重新指派高頻操作。

![Button Mapping](screenshots/button-mapping.png)

### 預設指令

打造你的指令面板。在一個聚焦的工作區中編輯所有觸發組合，支援預設和自訂 prompt，儲存前即時預覽字元數與效果。

![Preset Prompts](screenshots/quick-prompts.png)

### 語音辨識

一覽語音流程全貌。無需開啟多個視窗，即可查看引擎狀態、二進位安裝狀態、模型下載進度和 LLM 修正開關。

![Speech Recognition](screenshots/speech-recognition.png)

### 選單列

App 常駐選單列。綠色表示手把已連接，灰色表示未偵測到手把。

![Menu Bar](screenshots/menu-bar.png)

## 預設按鍵對應

| 按鍵 (Xbox / PS5) | 預設動作 |
|-------------------|----------|
| A / ✕ | Enter（確認） |
| B / ○ | Ctrl+C（中斷） |
| X / □ | Accept（y + Enter） |
| Y / △ | Reject（n + Enter） |
| D-pad | 方向鍵 |
| LB / L1 | `⌘W`（關閉視窗/分頁） |
| RB / R1 | Escape |
| L3（左搖桿按下） | 滑鼠左鍵 |
| R3（右搖桿按下） | `⌘W`（關閉視窗/分頁） |
| Start / Options | `⌘⇧]`（下一個終端機分頁） |
| Select / Create | `⌘T`（新分頁） |
| LT / L2 + 功能鍵 | 快捷指令（可自訂） |
| RT / R2 + 功能鍵 | 快捷指令（可自訂） |
| LT + LB | `⌘⌥`（Typeless / 覆蓋層觸發） |
| LT + RT（點按） | 切換左搖桿滑鼠模式 |
| LT + RT + Select | 結束應用程式（安全 override） |

所有對應均可在設定中自訂。

> **注意：** macOS 會保留硬體 Guide / Home / PS 按鍵，應用程式無法直接捕捉。若要用手把開啟 Vibe Island 或其他覆蓋層，請將其他可捕捉的按鍵對應至 `Combo` 動作。

## 安裝

### 系統需求

- macOS 14.0 (Sonoma) 或更新版本
- 遊戲手把（Xbox、PS5 DualSense 或 MFi 相容）
- Whisper（選用）：`brew install whisper-cpp`

### 方法 A：.app Bundle（建議）

建置完整的 macOS App Bundle，放到 `/Applications/` 並可設定登入時自動啟動，首次建置後無需再開終端機。

```bash
git clone https://github.com/henryyangHY/ClaudeGamepad.git
cd ClaudeGamepad
./build-app.sh
cp -R ClaudeGamepad.app /Applications/
```

開啟 App 後，依提示授予**輔助使用**權限。

**登入自動啟動：** 系統設定 → 一般 → 登入項目 → 加入 ClaudeGamepad。

> **注意：** 每次重新建置並複製新的執行檔到 `/Applications/`，macOS 都會撤銷現有的輔助使用授權。每次更新後，請至系統設定 → 隱私權與安全性 → 輔助使用，將 ClaudeGamepad 關閉再重新開啟。

### 方法 B：從原始碼建置（CLI）

```bash
git clone https://github.com/henryyangHY/ClaudeGamepad.git
cd ClaudeGamepad
swift build -c release
# 執行檔位於 .build/release/ClaudeGamepad
```

### 執行（CLI 模式）

```bash
swift run
```

或建置後複製到 PATH：

```bash
swift build -c release
cp .build/release/ClaudeGamepad /usr/local/bin/
```

## 首次啟動

1. 開啟 `ClaudeGamepad.app`（或 CLI 模式執行 `swift run`）
2. 若尚未授予輔助使用權限，選單列圖示會顯示 **「⚠️ Grant Accessibility to enable buttons」** — 點擊後直接跳至系統設定
3. 授予**輔助使用**權限（鍵盤模擬所需）
4. 若使用語音輸入，授予**語音辨識**權限
5. 連接手把 — 選單列圖示轉為啟動狀態
6. 將焦點切換至執行 Claude Code 的終端機
7. 開始按按鍵！

## 使用說明

### 基本操作

| 操作 | 手把輸入 |
|------|----------|
| 導航 / 選取 | D-pad |
| 接受建議 | X / □ |
| 拒絕建議 | Y / △ |
| 送出 / 確認 | A / ✕ |
| 取消 / 中斷 | B / ○ |
| 關閉視窗 / 分頁 | LB / L1 或 R3（`⌘W`） |
| 下一個終端機分頁 | Start / Options（`⌘⇧]`） |
| 滑鼠左鍵點擊 | L3（需先開啟滑鼠模式） |
| 切換滑鼠模式 | 同時點按 LT + RT |
| 觸發 Typeless / 覆蓋層 | 按住 LT，按 LB（`⌘⌥`） |

### 語音輸入（選用）

語音輸入已不再預設綁定，要啟用：

1. 開啟 **Settings → Button Mapping**，將任一空閒按鍵指派為 `Voice Input`。
2. 按下該按鍵 — 浮動 HUD 顯示「Listening...」並附即時波形。
3. 說出你的 prompt（自動偵測中英文）。
4. HUD 顯示轉錄結果，提示 `[A=確認 B=取消]`。
5. 按 **A / ✕** 貼入終端機，或 **B / ○** 取消。

> 後端為 `whisper.cpp`（用 `brew install whisper-cpp` 安裝）。系統 `SFSpeechRecognizer` 目前是 stub。

### 快捷指令

按住扳機鍵（LT 或 RT）並按功能鍵執行即時指令。一按住扳機，HUD 就會跳出 cheat sheet。

| 扳機 | 按鍵 | 指令 |
|------|------|------|
| LT | A | `codex` |
| LT | B | `claude` |
| LT | X | `copilot` |
| LT | Y | `gemini` |
| RT | A | `run the tests` |
| RT | B | `show me the diff` |
| RT | X | `looks good, commit this and push` |
| RT | Y | `refactor this to be cleaner` |

LT 是「切換 AI 助理」扳機；RT 是開發工作流扳機。皆可在 **Settings → Prompts** 中編輯。

### 扳機和弦

| 和弦 | 效果 |
|------|------|
| **LT + LB** | 觸發 `⌘⌥` — 呼叫 Typeless 或任何吃該修飾鍵的覆蓋層 |
| **LT + RT**（同時點按） | 切換左搖桿滑鼠模式，狀態跨重啟保留 |
| **LT + RT + Select** | 結束應用程式（無論其他映射如何皆生效的安全 override） |

## 設定

點擊選單列圖示 > **Settings** 開啟設定視窗。設定面板採用深色主題卡片式排版，分為四個分頁:**General**、**Button Mapping**、**Prompts**、**Speech**。

### General

選擇**控制器樣式**（Xbox 或 PS5）。這會同步修改整個 UI、浮層和設定頁中的按鍵文字與顏色。

### Button Mapping

按區域展示所有按鍵繫結：Shoulders（肩鍵）、Face Buttons（功能鍵）、Navigation（導航鍵）、System & Sticks（系統鍵與搖桿）。每個按鍵可從下拉選單選擇動作。LT/RT 作為修飾鍵，對應的快捷指令在「Prompts」分頁管理。若將某按鍵設為 `Combo`，該列會展開顯示要觸發的快捷鍵（例如 `⌘W`、`⌘⇧]`）。

### Prompts

左側列出所有快捷指令槽位（LT+A、LT+B、RT+A 等），右側為聚焦編輯區。每個槽位可選擇預設 prompt 或自訂文字，即時顯示字元數與預覽。

**預設快捷指令：**

| 觸發 | Prompt |
|------|--------|
| LT + A | `codex` |
| LT + B | `claude` |
| LT + X | `copilot` |
| LT + Y | `gemini` |
| RT + A | `run the tests` |
| RT + B | `show me the diff` |
| RT + X | `looks good, commit this and push` |
| RT + Y | `refactor this to be cleaner` |

### Speech

頂部 Voice Pipeline 狀態列一覽引擎、二進位安裝狀態、模型下載情況和 LLM 修正開關。下方分兩個卡片：

- **Whisper Local** — 選擇模型（tiny 75MB ～ large-v3 3.1GB）、一鍵安裝二進位、一鍵下載模型
- **LLM Refinement** — 設定 API URL、API Key、模型名稱，支援 Ollama、LM Studio 或任何 OpenAI 相容端點

## 語音輸入

1. 在 **Settings → Button Mapping** 中將任一空閒按鍵指派為 `Voice Input` 動作。
2. 按下該按鍵 — 浮動 HUD 顯示「Listening...」並附即時波形。
3. 說出你的 prompt（自動偵測中英文）。
4. HUD 顯示轉錄結果，提示 `[A=確認 B=取消]`。
5. 按 **A / ✕** 貼入終端機，或 **B / ○** 取消。

## Vibe Island / 覆蓋層導航

如果你想用手把開啟並操作 Vibe Island 等吃鍵盤方向鍵的懸浮視窗，可以這樣設定：

1. 在 **Settings > Button Mapping** 中，將任一空閒按鍵對應至 `Combo` 動作。
2. 在該列展開的 Guide Key Combo 控制項中設定快捷鍵，預設為 `⌘G`。
3. 按下該手把按鍵，觸發快捷鍵並開啟覆蓋層。
4. 覆蓋層開啟後的短暫時間內，D-pad 方向鍵會優先送至最前景的覆蓋層 App，而非終端機。
5. 若手動點回終端機，App 不再搶回覆蓋層焦點，方向鍵也回到終端機路徑。

## 疑難排解

**Q：能開啟 Vibe Island，但 D-pad 沒有反應**
> 請確認已授予輔助使用權限，且覆蓋層在快捷鍵觸發後確實處於最前景。

**Q：從覆蓋層點回終端機後偶爾失焦**
> 目前版本在手動切回終端機後，會停止繼續搶回覆蓋層焦點。

**Q：手把的 Guide / Home / PS 鍵無法直接繫結**
> 這是 macOS 的系統限制，需要將其他按鍵對應至 `Combo` 來觸發對應快捷鍵。

**Q：語音輸入無法使用**
> 用 `brew install whisper-cpp` 安裝 whisper.cpp，然後在 **Speech** 設定分頁中下載模型。系統 `SFSpeechRecognizer` 路徑目前是 stub，語音輸入必須走 whisper。

**Q：手把無法被偵測**
> 請確認手把支援 Mac。Xbox 和 PS5 手把相容性最佳，MFi 手把應可使用，但按鍵支援可能有限。

**Q：更新 App 後按鍵停止運作**
> macOS 會在 App 執行檔被替換時撤銷輔助使用授權。請至系統設定 → 隱私權與安全性 → 輔助使用，將 ClaudeGamepad 關閉再重新開啟。

**Q：選單列顯示 ⚠️ Grant Accessibility to enable buttons**
> 點擊該選單項目可直接跳至輔助使用設定頁面，新增或重新啟用 ClaudeGamepad。

## 貢獻指引

歡迎貢獻！提交前請參閱以下指引：

### 開發環境

```bash
# 複製儲存庫
git clone https://github.com/henryyangHY/ClaudeGamepad.git
cd ClaudeGamepad

# Debug 模式建置
swift build

# 附帶日誌執行
swift run 2>&1 | tee debug.log
```

### 測試

1. 若條件許可，請分別用 Xbox 和 PS5 手把測試
2. 分別測試系統語音和 whisper.cpp 的語音輸入
3. 改動後測試所有按鍵對應
4. 在真實終端機工作階段中使用 Claude Code 驗證功能

### Pull Request 規範

- 保持提交的原子性，描述清晰
- 若改動涉及使用者可見功能，請更新文件
- 提交前在 macOS 14.0+ 上測試
- 遵循 Swift 程式碼風格規範

## 架構

詳細的系統架構、模組關係與資料流文件，請參閱 [ARCHITECTURE.md](ARCHITECTURE.md)。

```
Sources/ClaudeGamepad/
├── main.swift              # 進入點（NSApplication.shared.run()）
├── AppDelegate.swift       # 選單列圖示、權限處理
├── AppResources.swift      # Bundle-aware 資源載入器
├── GamepadManager.swift    # 核心協調器，輸入路由
├── KeySimulator.swift      # 鍵盤 + 滑鼠事件產生（CGEvent）
├── OverlayPanel.swift      # 浮動 HUD + WaveformView
├── SpeechEngine.swift      # SFSpeechRecognizer 封裝（目前為 stub，見 CLAUDE.md）
├── WhisperEngine.swift     # whisper.cpp CLI 封裝
├── LLMRefiner.swift        # OpenAI 相容 API 客戶端
├── ButtonMapping.swift     # 設定資料模型
├── SpeechSettings.swift    # 語音設定模型
├── GamepadConfigView.swift # 視覺化按鍵編輯器元件
└── SettingsWindow.swift    # 設定 UI（4 個分頁）
```

## 授權條款

MIT
