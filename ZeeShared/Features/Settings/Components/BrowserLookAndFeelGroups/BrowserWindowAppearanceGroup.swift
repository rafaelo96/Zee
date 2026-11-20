import SwiftUI

/// The window's frame: how much of the Space shows around a page, which side
/// the sidebar sits on, and the accent its tabs and address field wear.
///
/// Each platform hands in the rest as extra rows and the settings that go
/// with them — Space page motion on every platform, and the window choices
/// only the desktop has — so the group's own Reset covers them too. The group shows the rows the page's
/// filter keeps, and none of itself when it keeps none.
struct BrowserWindowAppearanceGroup<Extra: View>: View {
    // MARK: - Variables

    var space: BrowserSpaceAppearance?
    var showsPreview = false
    var extraSettings: [(BrowserAppearanceSetting, ZeeResettableSetting)] = []
    @ViewBuilder var extraRows: () -> Extra

    @Bindable private var appearance = BrowserDeviceAppearanceStore.shared
    @Environment(\.browserAppearanceSettingFilter) private var filter

    // MARK: - Actions - Drawing

    var body: some View {
        let settings = filter.settings(rows)
        if !settings.isEmpty {
            group(settings: settings)
        }
    }

    private func group(settings: [ZeeResettableSetting]) -> some View {
        ZeeSettingsGroup(
            "Window",
            settings: settings
        ) {
            if showsPreview {
                BrowserLookAndFeelPreview(space: space, focus: .window)
            }
        } content: {
            ZeeSettingSlider(
                "Window border",
                value: border,
                range: BrowserChromeAppearance.borderWidthRange,
                readout: .points(zero: "Borderless"),
                identifier: "window-border-width"
            )
            .browserAppearanceSetting(.windowBorder)
            ZeeSettingSlider(
                "Sidebar transparency",
                value: transparency,
                range: 0...1,
                readout: .percent(naming: [0: "Solid"]),
                identifier: "sidebar-transparency"
            )
            .browserAppearanceSetting(.sidebarTransparency)
            ZeeSettingSlider(
                "Sidebar blur",
                value: blur,
                range: 0...1,
                readout: .percent(naming: [0: "None"]),
                identifier: "sidebar-blur"
            )
            .disabled(appearance.sidebarTransparency == 0)
            .browserAppearanceSetting(.sidebarBlur)
            ZeeSettingSlider(
                "Material",
                value: material,
                range: 0...Double(ZeeSurfaceMaterial.all.count - 1),
                step: 1,
                readout: ZeeSettingSliderReadout {
                    String(localized: ZeeSurfaceMaterial.at(position: Int($0.rounded())).title)
                },
                identifier: "surface-material"
            )
            .browserAppearanceSetting(.material)
            ZeeSettingRow("Material color", setting: materialColor.resettable("Material color")) {
                Picker("Material color", selection: materialColor.binding) {
                    ForEach(ZeeSurfaceTone.all, id: \.self) { Text($0.title).tag($0) }
                }
                .labelsHidden()
                .accessibilityIdentifier("surface-material-color")
            }
            .browserAppearanceSetting(.materialColor)
            ZeeSettingRow("Sidebar on right", setting: sidebar.resettable("Sidebar on right")) {
                Toggle("Sidebar on right", isOn: sidebar.binding)
                    .labelsHidden()
                    .accessibilityIdentifier("sidebar-on-right")
            }
            .browserAppearanceSetting(.sidebarOnRight)
            BrowserAppearanceAccentRow(
                color: accent,
                fallback: space?.branding.primaryColor ?? .indigo,
                identifier: "follows-space-accent"
            )
            .browserAppearanceSetting(.followSpaceAccent)
            extraRows()
        }
    }

    // MARK: - Actions - Settings

    private var border: ZeeSettingValue<Double> {
        ZeeSettingValue($appearance.windowBorderWidth, default: BrowserLookAndFeelDefaults.windowBorderWidth)
    }

    private var transparency: ZeeSettingValue<Double> {
        ZeeSettingValue(
            $appearance.sidebarTransparency, default: BrowserLookAndFeelDefaults.sidebarTransparency)
    }

    private var blur: ZeeSettingValue<Double> {
        ZeeSettingValue($appearance.sidebarBlur, default: BrowserLookAndFeelDefaults.sidebarBlur)
    }

    /// The sidebar's layer material, as a position from Ultra Thin to Ultra Thick.
    private var material: ZeeSettingValue<Double> {
        ZeeSettingValue(
            Binding(
                get: { Double(appearance.surfaceMaterial.position) },
                set: { appearance.surfaceMaterial = .at(position: Int($0.rounded())) }
            ),
            default: Double(BrowserLookAndFeelDefaults.surfaceMaterial.position)
        )
    }

    /// Whether the material and the text on it read light or dark.
    private var materialColor: ZeeSettingValue<ZeeSurfaceTone> {
        ZeeSettingValue($appearance.surfaceTone, default: BrowserLookAndFeelDefaults.surfaceTone)
    }

    private var sidebar: ZeeSettingValue<Bool> {
        ZeeSettingValue($appearance.sidebarOnRight, default: BrowserLookAndFeelDefaults.sidebarOnRight)
    }

    /// One accent for the selected tabs, pins and the address field, which
    /// keep their own stored colors.
    private var accent: ZeeSettingValue<BrandColor?> {
        ZeeSettingValue(
            Binding(
                get: { appearance.tabs.color ?? appearance.address.color },
                set: { color in
                    appearance.tabs.color = color
                    appearance.address.color = color
                }
            )
        )
    }

    private var rows: [(BrowserAppearanceSetting, ZeeResettableSetting)] {
        [
            (.windowBorder, border.resettable("Window border")),
            (.sidebarTransparency, transparency.resettable("Sidebar transparency")),
            (.sidebarBlur, blur.resettable("Sidebar blur")),
            (.material, material.resettable("Material")),
            (.materialColor, materialColor.resettable("Material color")),
            (.sidebarOnRight, sidebar.resettable("Sidebar on right")),
            (.followSpaceAccent, accent.resettable("Follow Space accent")),
        ] + extraSettings
    }
}
