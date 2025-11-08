import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var hub: ServiceHub

    var body: some View {
        Form {
            Section("テーマ") {
                Picker("表示モード", selection: $settings.themeMode) {
                    ForEach(SettingsStore.ThemeMode.allCases) { mode in
                        Text(mode.rawValue.capitalized).tag(mode)
                    }
                }
            }
            Section("購読") {
                Stepper(value: Binding(get: { settings.retentionDays }, set: { settings.retentionDays = $0 }), in: 7...180, step: 7) {
                    Text("保持日数: \(settings.retentionDays) 日")
                }
                Slider(value: Binding(get: { settings.markReadThreshold }, set: { settings.markReadThreshold = $0 }), in: 0.3...0.9) {
                    Text("スクロールで既読")
                }
                Text("しきい値: \(Int(settings.markReadThreshold * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Toggle("英語タイトルを自動翻訳", isOn: $settings.autoTranslateEnglishTitles)
                Toggle("モバイル通信時に画像を抑制", isOn: $settings.cellularImageBlocking)
            }
            Section("ツール") {
                Button("OPML を書き出し") { Task { await hub.subscriptionService.exportOPML() } }
                Button("バックアップを書き出し") { Task { await hub.backupService.exportBackup() } }
                Button("バックアップを読み込み") { Task { await hub.backupService.importBackup() } }
                NavigationLink("ミュートルール") { RulesEditorView() }
            }
            Section("プライバシー") {
                Text("KitsuneReader は端末内でのみ処理を行います。解析やトラッキングはありません。")
                    .font(.footnote)
            }
        }
        .navigationTitle("設定")
    }
}
