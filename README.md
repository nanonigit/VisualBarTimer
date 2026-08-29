# VisualBarTimer ⏱️

<p align="center">
  <b>A sleek, minimalist visual LED bar timer, desktop wallpaper widget, and menu bar companion for macOS.</b><br>
  macOSネイティブの直感的なフローティングLEDバータイマー、デスクトップ埋め込みウィジェット ＆ メニューバー常駐アプリ
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS%2013%2B-blue?style=flat-square" alt="Platform">
  <img src="https://img.shields.io/badge/Swift-5.9%2B-orange?style=flat-square" alt="Swift">
  <img src="https://img.shields.io/badge/license-MIT-green?style=flat-square" alt="License">
  <a href="https://github.com/nanonigit/VisualBarTimer/releases/latest"><img src="https://img.shields.io/github/v/release/nanonigit/VisualBarTimer?style=flat-square" alt="Release"></a>
</p>

<p align="center">
  <img src="docs/images/preview_color_medium.png" width="460" alt="VisualBarTimer Medium Preview">
</p>

---

[English](#english) | [日本語](#日本語) | [Screenshots / 画面プレビュー](#screenshots)

---

<a name="screenshots"></a>
## 📸 Screenshots / 画面プレビュー

### 🎨 Color Theme (カラーモード: 残り時間で 緑 → 黄 → 赤 に変化)

| Medium (中) | Mini / Extra Small (極小スリムバー) |
| :---: | :---: |
| <img src="docs/images/preview_color_medium.png" width="380" alt="Color Medium"> | <img src="docs/images/preview_color_mini.png" width="250" alt="Color Mini"> |

| Small (小) | Large (大) | Vertical (縦向き) |
| :---: | :---: | :---: |
| <img src="docs/images/preview_color_small.png" width="300" alt="Color Small"> | <img src="docs/images/preview_color_large.png" width="420" alt="Color Large"> | <img src="docs/images/preview_color_vertical.png" height="260" alt="Color Vertical"> |

---

### ⚪ Monochrome Theme (白黒モード: 高コントラスト・ミニマルLED)

| Medium (白黒・中) | Mini (白黒・極小) | Vertical (白黒・縦向き) |
| :---: | :---: | :---: |
| <img src="docs/images/preview_mono_medium.png" width="380" alt="Monochrome Medium"> | <img src="docs/images/preview_mono_mini.png" width="250" alt="Monochrome Mini"> | <img src="docs/images/preview_mono_vertical.png" height="260" alt="Monochrome Vertical"> |

---

<a name="english"></a>
## English

### ✨ Key Features

* **Visual LED Bar**:
  * **Horizontal Mode**: Time drains from right to left with precision tick marks.
  * **Vertical Mode**: Time drains from top to bottom.
* **Color & Monochrome Themes**:
  * **Color Theme**: 3-zone color spectrum (Green > 50% → Yellow 20–50% → Red < 20%).
  * **Monochrome Theme**: High-contrast, clean minimalist LED style.
* **3 Window Placement Modes (Floating / Normal / Desktop Widget)**:
  * **Always on Top (📌)**: Float on top of all windows and full-screen spaces.
  * **Normal Window**: Regular application window.
  * **Desktop Widget Mode (🖥️)**: Pin directly to macOS desktop wallpaper (behind all active apps) with full click interactivity and smooth real-time animation across all Spaces.
* **Real-time Circular Progress Menu Bar**:
  * **Multi-color Circular Progress**: 3-zone ring (Green → Yellow → Red) decaying clockwise matching the LED bar.
  * **Center Total Number**: Displays today's cumulative focus minutes inside the center of the ring.
  * **Multiple Display Styles**: Circular chart, circular chart + remaining time (`08:30`), `m` format (`⏱️ 45m`), `分` format (`⏱️ 45分`), numeric only, or icon only.
  * **Instant Window Toggle**: Click the menubar item to directly show or hide the timer window.
* **Activity Categories & Custom Tags**:
  * Built-in presets: **💼 Work**, **✏️ Study**, **💻 Dev**, **📖 Reading**, **🎨 Creative**, **🧘 Break**, **⏱️ Focus**.
  * **Unlimited Custom Categories**: Create custom emojis and labels (e.g. `🇬🇧 English`, `📊 Tax`, `✍️ Blog`) on the fly.
  * Category names automatically tag focus sessions and sync to calendar events.
* **Google & Apple Calendar Direct Sync (Daily & Weekly Summaries)**:
  * **Daily Auto Sync**: Automatically writes previous day's focus log to your selected calendar upon date change or wake from sleep.
  * **Weekly Summary Auto Sync**: Writes total weekly focus hours/sessions as an all-day event upon week transitions.
  * **Configurable Week Start**: Choose **Monday-start** (Mon–Sun summary on Sunday) or **Sunday-start** (Sun–Sat summary on Saturday).
  * **Sync Styles**: Choose between individual actual session time slots (time log) or an all-day summary.
* **History Management & Data Export**:
  * Daily history list with manual duration editing (`±15m`, custom minutes) and individual day deletion (🗑️) or clear all history.
  * **Export to CSV / JSON** with one click.
  * Data auto-persisted in `~/Library/Application Support/VisualBarTimer/activity_logs.json` for easy scripting (Obsidian, Notion, Python, Raycast).
* **Modes & Feedback**:
  * Supports **Countdown**, **Countup**, and **Pomodoro** (25m Focus / 5m Break).
  * Audible chime, LED flash animation, and macOS system notifications upon completion.

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
* **3つのウィンドウ配置モード (最前面 / 標準 / デスクトップ貼り付けウィジェット)**:
  * **常に最前面 (🟡 📌)**: 作業ウィンドウやフルスクリーンアプリの上でも常に手前にフロート表示。
  * **標準ウィンドウ (⚪ 🪟)**: 通常のアプリウィンドウ。
  * **デスクトップ貼り付けウィジェット (🔵 🖥️)**: Macの壁紙の直上（最背面）にピタッと吸着。他のアプリの邪魔にならず、全デスクトップ（Spaces）の背景でリアルタイムにバーが減衰し、クリック操作もそのまま可能。
* **リアルタイム円グラフ・メニューバー常駐**:
  * **マルチカラー円グラフ**: LEDバーと同じ「緑・黄・赤」の3色ゾーンを搭載し、12時（1時方向）から時計回りに滑らかに消灯。
  * **中央の本日累計分数表示**: 円グラフの中心に今日の総集中分数（例: `31`）がくっきり常時表示。
  * **メニューバー表示スタイル切替**: 円グラフ（中央分数付き）、円グラフ（アイコンのみ）、円グラフ＋残り時間（`08:30`）、`m`表示、`分`表示、数字のみ、固定アイコンから選択可能。
  * **ワンクリック表示切替**: メニューバーアイコンをクリックするだけでタイマーの表示/非表示を瞬時にトグル。
* **作業カテゴリ（アクティビティタグ）＆ 無制限カスタム登録**:
  * 集中セッションにタグを付与：**💼 仕事**, **✏️ 勉強**, **💻 開発**, **📖 読書**, **🎨 創作**, **🧘 休憩**, **⏱️ 集中作業**。
  * **無制限のカスタムカテゴリ作成**: 好きな絵文字＋名前（例: `🇬🇧 英語学習`, `📊 確定申告`, `✍️ ブログ`, `🏋️ 筋トレ`）を何個でも自由に追加・保存可能。
  * タイマー画面でワンクリックでカテゴリを瞬時に切り替えられ、カレンダーの予定タイトルにも自動反映。
* **Google & Apple Calendar 直接自動同期 (日別実績 ＆ 週間サマリー終日記録)**:
  * **日別自動同期**: 日付変更時や翌朝のスリープ復帰時に、前日の集中実績をGoogle/Macカレンダーへ自動登録。
  * **週間サマリー自動同期**: 週明けに前週1週間の総集中時間・セッション数・カテゴリ別内訳を終日予定としてカレンダーに自動記録。
  * **週の始まり曜日設定**: **月曜始まり（デフォルト）**（月〜日の集計を日曜日に終日記録）または **日曜始まり**（日〜土の集計を土曜日に終日記録）を自由に選択可能。
  * **同期スタイル選択**: 実際に作業していた時間帯に個別記録する「タイムログ形式」または「終日サマリー形式」から選択可能。
* **履歴管理 & データ書き出し**:
  * 過去の日別履歴リストから、時間の直接修正（`±15分`ボタンなど）、日別の個別削除（🗑️）、全履歴の一括消去が可能。
  * **CSV / JSON 形式でのワンクリック書き出し**・クリップボードコピーに対応。
  * ログは `~/Library/Application Support/VisualBarTimer/activity_logs.json` に自動保存（Obsidian、Notion、Python、Raycastと容易に連携）。
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
