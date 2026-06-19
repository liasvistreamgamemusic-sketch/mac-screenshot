import AppKit
import SwiftUI

/// The settings window content. A pure function of `SettingsStore`; every
/// control binds directly back into the store, which persists automatically.
struct SettingsView: View {
    @ObservedObject var store: SettingsStore
    @State private var permissionGranted = ScreenRecordingPermission.isGranted

    var body: some View {
        TabView {
            generalTab
                .tabItem { Label("一般", systemImage: "gearshape") }
            shortcutsTab
                .tabItem { Label("ショートカット", systemImage: "command") }
            aboutTab
                .tabItem { Label("情報", systemImage: "info.circle") }
        }
        .frame(width: 460, height: 430)
        .onAppear { permissionGranted = ScreenRecordingPermission.isGranted }
    }

    // MARK: - General

    private var generalTab: some View {
        Form {
            Section("撮影後の動作") {
                Toggle("クリップボードへコピー（貼り付け可能にする）", isOn: $store.settings.copyToClipboard)
                Toggle("ファイルに保存", isOn: $store.settings.saveToFile)

                if store.settings.saveToFile {
                    Picker("画像形式", selection: $store.settings.imageFormat) {
                        ForEach(ImageFormat.allCases) { format in
                            Text(format.displayName).tag(format)
                        }
                    }
                    if store.settings.imageFormat == .jpeg {
                        VStack(alignment: .leading) {
                            Text("JPEG 品質: \(Int(store.settings.jpegQuality * 100))%")
                                .font(.caption)
                            Slider(value: $store.settings.jpegQuality, in: 0.3...1.0)
                        }
                    }
                    saveLocationRow
                }
            }

            Section("フィードバック") {
                Toggle("シャッター音を鳴らす", isOn: $store.settings.playSound)
                Toggle("通知を表示する", isOn: $store.settings.showNotification)
            }

            Section("起動") {
                Toggle("ログイン時に自動起動", isOn: $store.settings.launchAtLogin)
            }

            Section("アップデート") {
                Toggle("起動時に自動でアップデートを確認", isOn: $store.settings.automaticUpdateChecks)
                HStack {
                    Text("バージョン \(AppInfo.version)")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("今すぐ確認", action: checkForUpdates)
                }
            }

            Section("権限") {
                permissionRow
            }
        }
        .formStyle(.grouped)
    }

    private var saveLocationRow: some View {
        HStack {
            Text("保存先")
            Spacer()
            Text((store.settings.resolvedSaveDirectory.path as NSString).abbreviatingWithTildeInPath)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
            Button("変更…", action: chooseSaveDirectory)
        }
    }

    private var permissionRow: some View {
        HStack {
            Image(systemName: permissionGranted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(permissionGranted ? .green : .orange)
            Text(permissionGranted ? "画面収録は許可されています" : "画面収録の許可が必要です")
            Spacer()
            if !permissionGranted {
                Button("許可をリクエスト") {
                    ScreenRecordingPermission.request()
                    permissionGranted = ScreenRecordingPermission.isGranted
                }
            }
        }
    }

    // MARK: - Shortcuts

    private var shortcutsTab: some View {
        Form {
            Section("グローバルショートカット") {
                ForEach(CaptureMode.allCases) { mode in
                    HStack {
                        Label(mode.title, systemImage: mode.symbolName)
                        Spacer()
                        HotkeyRecorder(combo: shortcutBinding(for: mode))
                    }
                }
            }
            Section {
                Text("ショートカットはどのアプリからでも動作します。システムのスクリーンショット（⌘⇧3/4/5）と重複しない組み合わせを推奨します。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - About

    private var aboutTab: some View {
        VStack(spacing: 12) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 56))
                .foregroundStyle(.tint)
            Text(AppInfo.name).font(.title.bold())
            Text("バージョン \(AppInfo.version) (\(AppInfo.build))")
                .foregroundStyle(.secondary)
            Text("Apple Silicon 向けの軽量スクリーンショットアプリ")
                .font(.callout)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
    }

    // MARK: - Helpers

    private func shortcutBinding(for mode: CaptureMode) -> Binding<KeyCombo> {
        Binding(
            get: { store.settings.shortcuts[mode] ?? AppSettings.default.shortcuts[mode]! },
            set: { newValue in store.update { $0.shortcuts[mode] = newValue } }
        )
    }

    private func checkForUpdates() {
        Task { @MainActor in
            await AppUpdater(settingsStore: store).checkForUpdates(userInitiated: true)
        }
    }

    private func chooseSaveDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "選択"
        panel.directoryURL = store.settings.resolvedSaveDirectory
        if panel.runModal() == .OK, let url = panel.url {
            store.update { $0.saveDirectoryPath = url.path }
        }
    }
}
