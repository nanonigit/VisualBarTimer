# VisualBarTimer ⏱️

<p align="center">
  <b>A sleek, Kingjim-style visual bar timer for macOS.</b><br>
  キングジム「ビジュアルバータイマー」風のmacOSネイティブ・フローティングタイマー
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS%2013%2B-blue?style=flat-square" alt="Platform">
  <img src="https://img.shields.io/badge/Swift-5.9%2B-orange?style=flat-square" alt="Swift">
  <img src="https://img.shields.io/badge/license-MIT-green?style=flat-square" alt="License">
  <a href="https://github.com/nanonigit/VisualBarTimer/releases/latest"><img src="https://img.shields.io/github/v/release/nanonigit/VisualBarTimer?style=flat-square" alt="Release"></a>
</p>

---

[English](#english) | [日本語](#日本語)

---

<a name="english"></a>
## English

### ✨ Key Features

* **Visual LED Bar**:
  * **Horizontal Mode**: Time drains from right to left with precision tick marks.
  * **Vertical Mode**: Time drains from top to bottom.
* **Color & Monochrome Themes**:
  * **Color Theme**: Changes smoothly based on remaining time (Green > 50% → Yellow 20–50% → Red < 20%).
  * **Monochrome Theme**: High-contrast, clean minimalist LED style.
* **Floating & Always on Top**:
  * Pin button (📌) keeps the timer always on top of your workflow.
  * Move freely around your screen by dragging anywhere on the background.
* **4 Flexible Window Sizes**:
  * **Mini (極小)**: Slim, unobtrusive 68px bar perfect for desk corners.
  * **Small (小)**, **Medium (中)**, **Large (大)**.
* **Intuitive Time Controls**:
  * **Click / Drag on Bar**: Set time directly by clicking anywhere on the bar.
  * **Click Clock to Edit**: Tap the digital clock to type custom minutes with your keyboard.
  * **Quick Presets**: `3m`, `5m`, `10m`, `15m`, `25m`, `30m`, `60m`.
* **Modes & Feedback**:
  * Supports **Countdown**, **Countup**, and **Pomodoro** (25m Focus / 5m Break).
  * Audible alarm, flash animation, and macOS system notification upon completion.

---

### 📦 Installation

#### Homebrew (Recommended)

```bash
brew install --cask nanonigit/visual-bar-timer/visual-bar-timer
```

#### Manual Download
Download the latest `VisualBarTimer.zip` from [GitHub Releases](https://github.com/nanonigit/VisualBarTimer/releases), unzip, and move `VisualBarTimer.app` to your `/Applications` folder.

---

### ⌨️ Shortcuts

* `Space`: Start / Pause
* `R`: Reset timer
* `Esc`: Close settings window

---

<a name="日本語"></a>
## 日本語

### ✨ 主な機能

* **視覚的LEDバー表示**:
  * **横向き**: 右から左へ目盛が減少（直感的な残り時間把握）
  * **縦向き**: 上から下へ目盛が減少
* **カラー & 白黒テーマ**:
  * **カラー**: 残り時間に応じて変化（緑 50%以上 → 黄 20〜50% → 赤 20%以下）
  * **白黒（モノトーン）**: 余計な色を排した高コントラストなLED表示
* **フローティング & 最前面固定**:
  * 📌ピンボタンで常時最前面への固定/解除が可能
  * 背景や時計の周囲をドラッグしてデスクトップ上を自由に移動
* **4段階のサイズプリセット**:
  * **極小 (Mini)**: デスクトップの隅に邪魔にならず置けるスリムバー（高さ約68px）
  * **小 (Small)**, **中 (Medium)**, **大 (Large)**
* **直感的な時間設定**:
  * **バーを直接クリック/ドラッグ**: バー上の位置をクリックして直感的に時間をセット
  * **分数の直接手入力**: デジタル時計部分（`10:00`など）をクリックしてキーボードで好きな分数を即入力
  * **ワンクリックプリセット**: `3m`, `5m`, `10m`, `15m`, `25m`, `30m`, `60m`
* **多彩なモード & 通知**:
  * **カウントダウン** / **カウントアップ** / **ポモドーロ**（25分作業 / 5分休憩）
  * タイムアップ時にアラーム音 ＋ バーの点滅フラッシュ ＋ macOSシステム通知

---

### 📦 インストール方法

#### Homebrew (推奨)

```bash
brew install --cask nanonigit/visual-bar-timer/visual-bar-timer
```

#### 手動ダウンロード
[GitHub Releases](https://github.com/nanonigit/VisualBarTimer/releases) から最新の `VisualBarTimer.zip` をダウンロード・展開し、`VisualBarTimer.app` を `/Applications`（アプリケーション）フォルダに移動してください。

---

### ⌨️ ショートカットキー

* `Space`: スタート / 一時停止
* `R`: リセット
* `Esc`: 設定ウィンドウを閉じる

---

## 🛠️ Build from Source

```bash
git clone https://github.com/nanonigit/VisualBarTimer.git
cd VisualBarTimer
swift run
```
