import SwiftUI

/// The shared Window group, plus the window choices only the desktop has:
/// light or dark, how far dark dims Space colors, Space page motion, the
/// sidebar hover area, how long it waits and how long the sidebar slides, and
/// whether it stays live over a page in full screen.
struct BrowserPlatformAppearanceSettingsSection: View {
    var space: BrowserSpaceAppearance?
    var showsPreview = false

    @AppStorage(SpacePageMotionPreference.key)
    private var animatesSpacePages = SpacePageMotionPreference.defaultValue
    @Bindable private var appearance = BrowserDeviceAppearanceStore.shared
    @AppStorage(SidebarFullscreenRevealPreference.key, store: BrowserChromeAppearancePreference.defaults)
    private var revealsSidebarInFullscreen = SidebarFullscreenRevealPreference.defaultValue

    var body: some View {
        let mode = ZeeSettingValue($appearance.mode, default: BrowserLookAndFeelDefaults.appearanceMode)
        let dimming = ZeeSettingValue(
            $appearance.darkSpaceDimming, default: BrowserLookAndFeelDefaults.darkSpaceDimming)

        let motion = ZeeSettingValue($animatesSpacePages, default: SpacePageMotionPreference.defaultValue)

        let revealWidth = ZeeSettingValue(
            $appearance.sidebarRevealWidth, default: SidebarRevealWidthPreference.defaultValue)
        let revealDelay = ZeeSettingValue(
            $appearance.sidebarRevealDelay, default: SidebarRevealDelayPreference.defaultValue)
        let slide = ZeeSettingValue($appearance.sidebarSlideDuration, default: BrowserSidebarSlide.defaultValue)
        let fullscreenReveal = ZeeSettingValue(
            $revealsSidebarInFullscreen, default: SidebarFullscreenRevealPreference.defaultValue)

        return BrowserWindowAppearanceGroup(
            space: space,
            showsPreview: showsPreview,
            extraSettings: [
                (.appearanceMode, mode.resettable("Appearance")),
                (.darkSpaceDimming, dimming.resettable("Dim Space colors in dark")),
                (.spacePageMotion, motion.resettable("Animate pages when switching Spaces")),
                (.sidebarRevealWidth, revealWidth.resettable("Sidebar hover area")),
                (.sidebarRevealDelay, revealDelay.resettable("Sidebar hover delay")),
                (.sidebarSlideDuration, slide.resettable("Sidebar slide time")),
                (.fullScreenSidebarReveal, fullscreenReveal.resettable("Show sidebar on hover in full screen")),
            ]
        ) {
            ZeeSettingRow("Appearance", setting: mode.resettable("Appearance")) {
                Picker("Appearance", selection: mode.binding) {
                    ForEach(BrowserAppearanceMode.all, id: \.self) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .fixedSize()
                .accessibilityIdentifier("appearance-mode")
            }
            .browserAppearanceSetting(.appearanceMode)

            ZeeSettingSlider(
                "Dim Space colors in dark",
                value: dimming,
                readout: .percent(zero: "Off", full: "Full"),
                identifier: "dark-space-dimming"
            )
            .browserAppearanceSetting(.darkSpaceDimming)

            BrowserSpacePageMotionRow(motion: motion)

            ZeeSettingSlider(
                "Sidebar hover area",
                value: revealWidth,
                range: SidebarRevealWidthPreference.range,
                readout: .points,
                identifier: "sidebar-reveal-width",
                onEditingChanged: { _ in SidebarRevealWidthPreview.shared.adjusted() }
            )
            .onChange(of: appearance.sidebarRevealWidth) { SidebarRevealWidthPreview.shared.adjusted() }
            .browserAppearanceSetting(.sidebarRevealWidth)

            ZeeSettingSlider(
                "Sidebar hover delay",
                value: revealDelay,
                range: SidebarRevealDelayPreference.range,
                readout: .milliseconds(zero: "Instant"),
                identifier: "sidebar-reveal-delay"
            )
            .browserAppearanceSetting(.sidebarRevealDelay)

            ZeeSettingSlider(
                "Sidebar slide time",
                value: slide,
                range: BrowserSidebarSlide.range,
                readout: .milliseconds(zero: "Snap"),
                identifier: "sidebar-slide-time"
            )
            .browserAppearanceSetting(.sidebarSlideDuration)

            ZeeSettingRow(
                "Show sidebar on hover in full screen",
                setting: fullscreenReveal.resettable("Show sidebar on hover in full screen")
            ) {
                Toggle("Show sidebar on hover in full screen", isOn: fullscreenReveal.binding)
                    .labelsHidden()
                    .accessibilityIdentifier("sidebar-fullscreen-reveal")
            }
            .browserAppearanceSetting(.fullScreenSidebarReveal)
        }
    }
}
