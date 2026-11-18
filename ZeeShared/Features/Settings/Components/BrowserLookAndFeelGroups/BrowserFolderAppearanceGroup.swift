import SwiftUI

/// How folders read in every Space on this device. A Space's own folder color
/// travels with its branding and stays in the Space editor.
struct BrowserFolderAppearanceGroup: View {
    var space: BrowserSpaceAppearance?
    var showsPreview = false

    @Bindable private var appearance = BrowserDeviceAppearanceStore.shared
    @Environment(\.browserAppearanceSettingFilter) private var filter

    var body: some View {
        let settings = filter.settings(rows)
        if !settings.isEmpty {
            group(settings: settings)
        }
    }

    private func group(settings: [ZeeResettableSetting]) -> some View {
        ZeeSettingsGroup(
            "Folders",
            settings: settings
        ) {
            if showsPreview {
                BrowserLookAndFeelPreview(space: space, focus: .folders)
            }
        } content: {
            ZeeSettingRow("Icon Only Folders", setting: icons.resettable("Icon Only Folders")) {
                Toggle("Icon Only Folders", isOn: icons.binding)
                    .labelsHidden()
                    .accessibilityIdentifier("folder-icon-only")
                    .help("Show a static custom icon or emoji instead of folder artwork.")
            }
            .browserAppearanceSetting(.folderIconOnly)
            ZeeSettingRow("Tint Folder Title", setting: titles.resettable("Tint Folder Title")) {
                Toggle("Tint Folder Title", isOn: titles.binding)
                    .labelsHidden()
                    .accessibilityIdentifier("folder-tint-title")
            }
            .browserAppearanceSetting(.folderTintTitle)
            ZeeSettingRow(
                "Always show folder highlights", setting: highlights.resettable("Always show folder highlights")
            ) {
                Toggle("Always show folder highlights", isOn: highlights.binding)
                    .labelsHidden()
                    .accessibilityIdentifier("folder-always-show-highlights")
            }
            .browserAppearanceSetting(.folderHighlights)
            ZeeSettingRow("Show folder tab counts", setting: counts.resettable("Show folder tab counts")) {
                Toggle("Show folder tab counts", isOn: counts.binding)
                    .labelsHidden()
                    .accessibilityIdentifier("folder-show-tab-counts")
            }
            .browserAppearanceSetting(.folderTabCounts)
            ZeeSettingRow("Show folder color borders", setting: borders.resettable("Show folder color borders")) {
                Toggle("Show folder color borders", isOn: borders.binding)
                    .labelsHidden()
                    .accessibilityIdentifier("folder-show-color-borders")
            }
            .browserAppearanceSetting(.folderBorders)
        }
    }

    private var highlights: ZeeSettingValue<Bool> {
        ZeeSettingValue($appearance.foldersAlwaysVisible, default: BrowserLookAndFeelDefaults.foldersAlwaysVisible)
    }

    private var counts: ZeeSettingValue<Bool> {
        ZeeSettingValue($appearance.foldersShowTabCounts, default: BrowserLookAndFeelDefaults.foldersShowTabCounts)
    }

    private var borders: ZeeSettingValue<Bool> {
        ZeeSettingValue($appearance.foldersShowBorders, default: BrowserLookAndFeelDefaults.foldersShowBorders)
    }

    private var rows: [(BrowserAppearanceSetting, ZeeResettableSetting)] {
        [
            (.folderIconOnly, icons.resettable("Icon Only Folders")),
            (.folderTintTitle, titles.resettable("Tint Folder Title")),
            (.folderHighlights, highlights.resettable("Always show folder highlights")),
            (.folderTabCounts, counts.resettable("Show folder tab counts")),
            (.folderBorders, borders.resettable("Show folder color borders")),
        ]
    }

    private var icons: ZeeSettingValue<Bool> {
        ZeeSettingValue($appearance.foldersIconOnly, default: BrowserLookAndFeelDefaults.foldersIconOnly)
    }

    private var titles: ZeeSettingValue<Bool> {
        ZeeSettingValue($appearance.foldersTintTitle, default: BrowserLookAndFeelDefaults.foldersTintTitle)
    }
}
