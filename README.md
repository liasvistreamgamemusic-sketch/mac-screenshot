# Snapper

Apple Silicon 向けの軽量なスクリーンショットアプリ。メニューバーに常駐し、グローバルショートカットで素早くキャプチャできます。**撮影と同時に画像をクリップボードへコピー**するので、そのまま貼り付け（ペースト）できます。

<p align="center">
  <em>📸 メニューバー常駐 · ⌨️ グローバルショートカット · 📋 撮影即コピー</em>
</p>

## 特長

- **4 つのキャプチャモード**
  - **選択領域** — ドラッグした矩形だけをキャプチャ（複数ディスプレイをまたいでも可）
  - **アクティブなウィンドウ** — 最前面のウィンドウだけをキャプチャ（背景透過）
  - **アクティブな画面** — 最前面のウィンドウがあるディスプレイ全体をキャプチャ
  - **全画面まとめて** — 接続中の全ディスプレイを実際の配置で 1 枚に合成
- **撮影即コピー（デフォルト ON / 切り替え可）** — 撮ったらすぐ貼り付け可能
- **ファイル保存** — PNG / JPEG、保存先・JPEG 品質を設定可能。デフォルトの保存先は専用フォルダ `~/Pictures/Snapper`（初回保存時に自動作成）
- **グローバルショートカット** — どのアプリからでも動作。設定画面で自由に変更可能
- **自動アップデート** — 起動時に GitHub の最新リリースを確認し、新しい版があればアプリ内でダウンロード・インストール（設定でオフ可能）
- **フィードバック** — シャッター音・通知のオン/オフ
- **ログイン時に自動起動**（任意）
- メニューバーの**ヘッダー（アイコン）**から全設定にアクセス

### デフォルトのショートカット

| 操作 | ショートカット |
| --- | --- |
| 選択領域をキャプチャ | <kbd>⌃⌥⌘R</kbd> |
| アクティブなウィンドウをキャプチャ | <kbd>⌃⌥⌘W</kbd> |
| アクティブな画面をキャプチャ | <kbd>⌃⌥⌘D</kbd> |
| 全画面をまとめてキャプチャ | <kbd>⌃⌥⌘A</kbd> |

> macOS 標準のスクリーンショット（⌘⇧3/4/5）と衝突しない組み合わせを採用しています。設定画面でいつでも変更できます。ショートカットには **⌘ または ⌃ を含める**必要があります（各操作に別々のキーを割り当ててください）。

## 動作環境

- macOS 14 (Sonoma) 以降
- Apple Silicon (arm64)

## インストール

1. [Releases](../../releases) から最新の `Snapper-x.y.z.dmg` をダウンロード
2. DMG を開き、`Snapper.app` を `Applications` フォルダにドラッグ
3. 初回起動時、未署名アプリのため Gatekeeper に止められた場合は、`Applications` の `Snapper.app` を**右クリック → 開く**で起動するか、以下を実行：
   ```bash
   xattr -dr com.apple.quarantine /Applications/Snapper.app
   ```
4. 起動すると**画面収録**の許可を求められます。
   **システム設定 > プライバシーとセキュリティ > 画面収録** で Snapper を有効にしてください（ScreenCaptureKit によるキャプチャに必須）。

> 開発者署名（Developer ID）は付与していないため、ad-hoc 署名での配布です。

> **アップデート後の画面収録の再許可について**
> ad-hoc 署名はビルドごとに署名（cdhash）が変わるため、macOS の画面収録の許可は
> アプリを更新すると引き継がれません。**アップデート後にキャプチャが「権限がない」と
> なる場合**は、一覧が ON に見えても、次の手順で**入れ直し**てください：
> システム設定 > プライバシーとセキュリティ > 画面収録 → 一覧の **Snapper を「−」で削除** →
> Snapper を再起動して**再度許可**（自分でソースからビルドし直した場合も同様です）。
> これは Developer ID 署名＋公証を行えば解消できます。

## 使い方

- メニューバーのカメラアイコン（📷 ファインダー）をクリックすると、各キャプチャ操作・クリップボード設定・設定画面にアクセスできます。
- ショートカットを押すだけでキャプチャ。設定で「クリップボードへコピー」が ON なら、そのまま <kbd>⌘V</kbd> で貼り付けられます。

## ソースからビルド

フル Xcode（または Command Line Tools）と Swift 6 が必要です。

```bash
# テスト
swift test

# .app をビルド（dist/Snapper.app）
./scripts/build_app.sh 0.1.0

# DMG を作成（dist/Snapper-0.1.0.dmg）
./scripts/make_dmg.sh 0.1.0
```

## アーキテクチャ

機能拡張しやすいよう、責務ごとにレイヤーを分離しています。

```
Sources/Snapper/
├── main.swift                  # エントリポイント（NSApplication 起動）
├── App/                        # 合成ルート（依存の組み立て）
│   ├── AppDelegate.swift
│   └── CaptureCoordinator.swift # 撮影フローのオーケストレーション
├── Capture/                    # ScreenCaptureKit によるキャプチャ
│   ├── ScreenCaptureService.swift
│   ├── DisplayResolver.swift    # アクティブ画面の判定
│   ├── WindowResolver.swift     # アクティブ（最前面）ウィンドウの判定
│   ├── ImageCompositor.swift    # 複数画面の合成・クロップ
│   └── ScreenScale.swift
├── Output/                     # 出力（副作用）
│   ├── CaptureOutputDispatcher.swift
│   ├── ClipboardWriter.swift
│   ├── ImageFileWriter.swift
│   ├── ImageEncoder.swift
│   └── CaptureFeedback.swift    # 音・通知
├── Hotkeys/                    # グローバルショートカット（Carbon）
│   ├── HotkeyCenter.swift
│   ├── HotkeyBindingManager.swift
│   └── KeyCombo.swift
├── Region/                     # 領域選択オーバーレイ + 座標変換
├── Update/                     # 自動アップデート（GitHub Releases）
│   ├── UpdateChecker.swift      # 最新リリース取得 & バージョン比較
│   ├── UpdateInstaller.swift    # DMG ダウンロード & 入れ替え（再起動）
│   ├── AppUpdater.swift         # チェック〜インストールの UI オーケストレーション
│   └── SemanticVersion.swift
├── Settings/                   # 設定モデル & 永続化（UserDefaults）
├── StatusBar/                  # メニューバー（ヘッダー）
├── UI/                         # SwiftUI 設定画面
└── Support/                    # ログ・アプリ情報・ログイン項目
```

新しいキャプチャモードを追加する場合は `CaptureMode` に case を足すだけで、コンパイラが各 `switch` の更新を強制します。

## ライセンス

[MIT](./LICENSE)
