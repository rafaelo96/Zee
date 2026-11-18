import SwiftUI

/// The address field's fill, border, how much of the address it shows, how
/// it opens the command palette, and what copying its address copies, on
/// every Space on this device.
struct BrowserAddressAppearanceGroup: View {
    var space: BrowserSpaceAppearance?
    var showsPreview = false
    /// This device's link preferences, which keep Super Copy.
    var links: BrowserLinkPreferenceStore?

    @Bindable private var appearance = BrowserDeviceAppearanceStore.shared
    @Environment(\.browserAppearanceSettingFilter) private var filter

    var body: some View {
        let settings = filter.settings(rows)
        if !settings.isEmpty {
            group(settings: settings)
        }
    }

    private func group(settings: [ZeeResettableSetting]) -> some View {
        ZeeSettingsGroup("Address field", settings: settings, footnote: footnote) {
            if showsPreview {
                BrowserLookAndFeelPreview(space: space, focus: .addressField)
            }
        } content: {
            ZeeSettingSlider("Color fill", value: fill, readout: .percent(zero: "None", full: "Strong"))
                .browserAppearanceSetting(.addressFill)
            ZeeSettingSlider("Border", value: border, readout: .percent(zero: "None", full: "Strong"))
                .browserAppearanceSetting(.addressBorder)
            ZeeSettingRow("Address", setting: display.resettable("Address")) {
                Picker("Address", selection: display.binding) {
                    Text("Two lines").tag(BrowserAddressAppearance.Display.twoLines)
                    Text("One line").tag(BrowserAddressAppearance.Display.oneLine)
                    Text("Site only").tag(BrowserAddressAppearance.Display.siteOnly)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .fixedSize()
                .accessibilityLabel("Address")
            }
            .browserAppearanceSetting(.addressDisplay)
            ZeeSettingRow(
                "Accent outline while editing",
                setting: outline.resettable("Accent outline while editing")
            ) {
                Toggle("Accent outline while editing", isOn: outline.binding)
                    .labelsHidden()
            }
            .browserAppearanceSetting(.addressEditingOutline)
            ZeeSettingRow(
                "Animate into command palette",
                setting: paletteMorph.resettable("Animate into command palette")
            ) {
                Toggle("Animate into command palette", isOn: paletteMorph.binding)
                    .labelsHidden()
            }
            .browserAppearanceSetting(.commandPaletteMotion)
            #if os(macOS)
                ZeeSettingRow("Copy URL button", setting: copyURLButton.resettable("Copy URL button")) {
                    Toggle("Copy URL button", isOn: copyURLButton.binding)
                        .labelsHidden()
                }
                .browserAppearanceSetting(.copyURLButton)
            #endif
            if let superCopy {
                ZeeSettingRow("Super Copy", setting: superCopy.resettable("Super Copy")) {
                    Toggle("Super Copy", isOn: superCopy.binding)
                        .labelsHidden()
                }
                .browserAppearanceSetting(.superCopy)
            }
        }
    }

    /// What Super Copy does, while its row is on the page.
    private var footnote: LocalizedStringKey? {
        guard superCopy != nil, filter.shows(.superCopy) else { return nil }
        return
            "With Super Copy, copying or sharing a link leaves out its trackers, using AdGuard's URL Tracking filter. Copying the selected address keeps everything."
    }

    private var display: ZeeSettingValue<BrowserAddressAppearance.Display> {
        ZeeSettingValue($appearance.address.display, default: BrowserLookAndFeelDefaults.address.display)
    }

    /// Super Copy, on by default, kept with this device's link preferences.
    private var superCopy: ZeeSettingValue<Bool>? {
        guard let links else { return nil }
        return ZeeSettingValue(
            links.binding(.cleansCopiedLinks, reading: \.cleansCopiedLinks), default: true)
    }

    private var fill: ZeeSettingValue<Double> {
        ZeeSettingValue($appearance.address.fill, default: BrowserLookAndFeelDefaults.address.fill)
    }

    private var border: ZeeSettingValue<Double> {
        ZeeSettingValue($appearance.address.border, default: BrowserLookAndFeelDefaults.address.border)
    }

    private var outline: ZeeSettingValue<Bool> {
        ZeeSettingValue(
            $appearance.address.usesAccentWhenEditing,
            default: BrowserLookAndFeelDefaults.address.usesAccentWhenEditing)
    }

    private var paletteMorph: ZeeSettingValue<Bool> {
        ZeeSettingValue(
            $appearance.address.animatesIntoCommandPalette,
            default: BrowserLookAndFeelDefaults.address.animatesIntoCommandPalette)
    }

    private var copyURLButton: ZeeSettingValue<Bool> {
        ZeeSettingValue(
            $appearance.address.showsCopyURLButton,
            default: BrowserLookAndFeelDefaults.address.showsCopyURLButton)
    }

    private var rows: [(BrowserAppearanceSetting, ZeeResettableSetting)] {
        var rows: [(BrowserAppearanceSetting, ZeeResettableSetting)] = [
            (.addressFill, fill.resettable("Color fill")),
            (.addressBorder, border.resettable("Border")),
            (.addressDisplay, display.resettable("Address")),
            (.addressEditingOutline, outline.resettable("Accent outline while editing")),
            (.commandPaletteMotion, paletteMorph.resettable("Animate into command palette")),
        ]
        #if os(macOS)
            rows.append((.copyURLButton, copyURLButton.resettable("Copy URL button")))
        #endif
        if let superCopy { rows.append((.superCopy, superCopy.resettable("Super Copy"))) }
        return rows
    }
}
