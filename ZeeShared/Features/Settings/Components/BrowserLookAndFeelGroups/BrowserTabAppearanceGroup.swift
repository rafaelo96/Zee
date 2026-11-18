import SwiftUI

/// Tabs, pins, and the shape they share, on every Space on this device.
struct BrowserTabAppearanceGroup: View {
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
            "Tabs and pins",
            settings: settings
        ) {
            if showsPreview {
                BrowserLookAndFeelPreview(space: space, focus: .tabs)
            }
        } content: {
            BrowserAppearancePresetPicker(
                "Corner radius",
                value: cornerRadius,
                presets: BrowserAppearancePresets.cornerRadius,
                tolerance: BrowserAppearancePresets.cornerRadiusTolerance,
                identifier: "tab-corner-radius"
            )
            .browserAppearanceSetting(.cornerRadius)
            ZeeSettingSlider(
                "Tab size",
                value: scale,
                range: BrowserSidebarDensity.scaleRange,
                step: BrowserSidebarDensity.scaleStep,
                readout: .percent(naming: [
                    0.6: "Thin", 0.8: "Compact", 1: "Default", 1.2: "Comfortable", 1.4: "Large",
                ]),
                identifier: "tab-scale"
            )
            .browserAppearanceSetting(.tabScale)
            ZeeSettingRow("Spacing", setting: spacing.resettable("Spacing")) {
                Picker("Spacing", selection: spacing.binding) {
                    ForEach(BrowserSidebarSpacing.all) { spacing in
                        Text(spacing.title).tag(spacing)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .fixedSize()
                .accessibilityIdentifier("sidebar-spacing")
            }
            .browserAppearanceSetting(.sidebarSpacing)
            ZeeSettingRow("Pin layout", setting: columns.resettable("Pin layout")) {
                Picker("Pin layout", selection: columns.binding) {
                    Text("Balanced rows").tag(0)
                    Text("One per row").tag(1)
                    ForEach(2...6, id: \.self) { Text("Up to \($0) per row").tag($0) }
                }
                .labelsHidden()
                .fixedSize()
                .accessibilityLabel("Pin layout")
            }
            .browserAppearanceSetting(.pinLayout)
            ZeeSettingRow(
                "Stretch pins to fill the row", setting: fillsRow.resettable("Stretch pins to fill the row")
            ) {
                Toggle("Stretch pins to fill the row", isOn: fillsRow.binding)
                    .labelsHidden()
            }
            .browserAppearanceSetting(.pinsFillRow)
            ZeeSettingRow("Color borders", setting: borders.resettable("Color borders")) {
                Picker("Color borders", selection: borders.binding) {
                    Text("Selected").tag(BrowserTabAppearance.Borders.selected)
                    Text("Pins").tag(BrowserTabAppearance.Borders.pinned)
                    Text("All tabs").tag(BrowserTabAppearance.Borders.all)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .fixedSize()
                .accessibilityLabel("Color borders")
            }
            .browserAppearanceSetting(.colorBorders)
            ZeeSettingRow(
                "Accent outline on selected tabs", setting: outlines.resettable("Accent outline on selected tabs")
            ) {
                Toggle("Accent outline on selected tabs", isOn: outlines.binding)
                    .labelsHidden()
            }
            .browserAppearanceSetting(.selectedTabOutline)
            ZeeSettingRow("Website colors for pins", setting: websiteColors.resettable("Website colors for pins")) {
                Toggle("Website colors for pins", isOn: websiteColors.binding)
                    .labelsHidden()
            }
            .browserAppearanceSetting(.websitePinColors)
            ZeeSettingRow("Dim unloaded tabs", setting: dimming.resettable("Dim unloaded tabs")) {
                Toggle("Dim unloaded tabs", isOn: dimming.binding)
                    .labelsHidden()
            }
            .browserAppearanceSetting(.dimUnloadedTabs)
            ZeeSettingSlider("Pinned fill", value: pinFill, readout: .percent(zero: "None", full: "Strong"))
                .browserAppearanceSetting(.pinnedFill)
            ZeeSettingSlider("Selected tab glow", value: pinGlow, readout: .percent(zero: "None", full: "Strong"))
                .browserAppearanceSetting(.selectedTabGlow)
            ZeeSettingSlider("Hover tint", value: hoverFill, readout: .percent(zero: "Neutral", full: "Accent"))
                .browserAppearanceSetting(.hoverTint)
        }
    }

    private var cornerRadius: ZeeSettingValue<Double> {
        ZeeSettingValue($appearance.cornerRadius, default: BrowserLookAndFeelDefaults.cornerRadius)
    }

    private var scale: ZeeSettingValue<Double> {
        ZeeSettingValue($appearance.tabScale, default: BrowserLookAndFeelDefaults.tabScale)
    }

    private var spacing: ZeeSettingValue<BrowserSidebarSpacing> {
        ZeeSettingValue($appearance.sidebarSpacing, default: BrowserLookAndFeelDefaults.sidebarSpacing)
    }

    private var columns: ZeeSettingValue<Int> {
        ZeeSettingValue($appearance.pinColumns, default: BrowserLookAndFeelDefaults.pinColumns)
    }

    private var fillsRow: ZeeSettingValue<Bool> {
        ZeeSettingValue($appearance.pinsFillRow, default: BrowserLookAndFeelDefaults.pinsFillRow)
    }

    private var borders: ZeeSettingValue<BrowserTabAppearance.Borders> {
        ZeeSettingValue($appearance.tabs.borders, default: BrowserLookAndFeelDefaults.tabs.borders)
    }

    private var outlines: ZeeSettingValue<Bool> {
        ZeeSettingValue(
            $appearance.tabs.outlinesSelectedTabs,
            default: BrowserLookAndFeelDefaults.tabs.outlinesSelectedTabs)
    }

    private var websiteColors: ZeeSettingValue<Bool> {
        ZeeSettingValue(
            $appearance.tabs.usesWebsitePinColor,
            default: BrowserLookAndFeelDefaults.tabs.usesWebsitePinColor)
    }

    private var dimming: ZeeSettingValue<Bool> {
        ZeeSettingValue(
            $appearance.tabs.dimsUnloadedTabs,
            default: BrowserLookAndFeelDefaults.tabs.dimsUnloadedTabs)
    }

    private var pinFill: ZeeSettingValue<Double> {
        ZeeSettingValue($appearance.tabs.pinFill, default: BrowserLookAndFeelDefaults.tabs.pinFill)
    }

    private var pinGlow: ZeeSettingValue<Double> {
        ZeeSettingValue($appearance.tabs.pinGlow, default: BrowserLookAndFeelDefaults.tabs.pinGlow)
    }

    private var hoverFill: ZeeSettingValue<Double> {
        ZeeSettingValue($appearance.tabs.hoverFill, default: BrowserLookAndFeelDefaults.tabs.hoverFill)
    }

    private var rows: [(BrowserAppearanceSetting, ZeeResettableSetting)] {
        [
            (.cornerRadius, cornerRadius.resettable("Corner radius")),
            (.tabScale, scale.resettable("Tab size")),
            (.sidebarSpacing, spacing.resettable("Spacing")),
            (.pinLayout, columns.resettable("Pin layout")),
            (.pinsFillRow, fillsRow.resettable("Stretch pins to fill the row")),
            (.colorBorders, borders.resettable("Color borders")),
            (.selectedTabOutline, outlines.resettable("Accent outline on selected tabs")),
            (.websitePinColors, websiteColors.resettable("Website colors for pins")),
            (.dimUnloadedTabs, dimming.resettable("Dim unloaded tabs")),
            (.pinnedFill, pinFill.resettable("Pinned fill")),
            (.selectedTabGlow, pinGlow.resettable("Selected tab glow")),
            (.hoverTint, hoverFill.resettable("Hover tint")),
        ]
    }
}
