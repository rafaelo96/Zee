import SwiftUI

/// Where the windows show a page's address, as one preview button for each
/// place: a Zee window in the current style with the field in its sidebar,
/// or with the bar along the top of its page card. The choice is this
/// device's, for every Space and window.
struct BrowserPlatformAddressBarSettingsSection: View {
    // MARK: - Variables

    @Bindable private var appearance = BrowserDeviceAppearanceStore.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let placement = ZeeSettingValue(
            $appearance.addressBarPlacement, default: BrowserLookAndFeelDefaults.addressBarPlacement)
        let resettable = ZeeResettableSetting(title: "Address bar", isDefault: placement.isDefault) {
            choose(BrowserLookAndFeelDefaults.addressBarPlacement)
        }
        ZeeSettingsGroup("Address bar", settings: [resettable]) {
            HStack(alignment: .top, spacing: BrowserCustomizationStyleMetrics.spacing) {
                ForEach(BrowserAddressBarPlacement.all) { candidate in
                    ZeePreviewButton(
                        title: Text(candidate.title), isSelected: candidate == appearance.addressBarPlacement,
                        previewSize: BrowserCustomizationStyleMetrics.previewSize
                    ) {
                        choose(candidate)
                    } preview: {
                        BrowserOnboardingWindowPreview(
                            branding: look.previewBranding, symbol: look.previewSymbol,
                            name: String(localized: "Personal"),
                            spaceIcons: appearance.chosenSpaceIcons ?? appearance.customizationStyle.spaceIcons,
                            companionLook: look,
                            addressBarPlacement: candidate
                        ) {
                            EmptyView()
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("address-bar-placement")
        }
    }

    /// The look of the style the page shows, which both previews wear.
    private var look: SetupLook {
        appearance.customizationStyle.look
    }

    // MARK: - Actions - Choice

    private func choose(_ placement: BrowserAddressBarPlacement) {
        withAnimation(ZeeMotion.chrome.unlessReducingMotion(reduceMotion)) {
            appearance.addressBarPlacement = placement
        }
    }
}
