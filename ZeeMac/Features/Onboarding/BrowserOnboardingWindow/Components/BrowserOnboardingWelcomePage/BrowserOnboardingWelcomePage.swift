import SwiftUI

/// The first page: the mark, one line, and what the welcome offers on a pane
/// of Liquid Glass, beside a banner of a Space wearing Zee's own look. The
/// pane settles into place as the backdrop's waves rise.
struct BrowserOnboardingWelcomePage: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let action: BrowserOnboardingWelcomeAction
    let hasCompletedSetup: Bool
    let hasDisposableSeedState: Bool
    let continueSetup: () -> Void
    let setUpWithoutCloud: () -> Void
    let openZee: () -> Void

    @State private var hasArrived = false

    private var cloudStatusDetail: String {
        if hasCompletedSetup {
            return String(localized: "Your existing Zee setup is ready.")
        }
        if !hasDisposableSeedState {
            return String(localized: "Your existing Spaces are ready to customize.")
        }
        if action.reportsCloudUnavailable {
            return String(localized: "iCloud is unavailable right now; you can still set up this Mac.")
        }
        return String(localized: "No existing setup was found.")
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 0) {
                column
                    .frame(maxWidth: 560, alignment: .leading)
                    .padding(.leading, 80)
                Spacer(minLength: 60)
                BrowserOnboardingWindowPreview(
                    branding: BrowserOnboardingWelcomeMetrics.previewBranding, symbol: "house.fill",
                    name: String(localized: "Personal")
                ) {
                    ZeeStartPageMark()
                        .frame(width: 160, height: 160)
                }
                .frame(width: 680, height: 460)
                .padding(.trailing, 100)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            column
                .frame(maxWidth: 560, alignment: .leading)
                .padding(.leading, 80)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }

    private var column: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
            pane
                .opacity(hasArrived ? 1 : 0)
                .blur(radius: hasArrived ? 0 : 14)
                .offset(y: hasArrived ? 0 : 28)
                .animation(
                    BrowserOnboardingWelcomeMetrics.arrival.unlessReducingMotion(reduceMotion), value: hasArrived)
            Spacer()
        }
        .onAppear { hasArrived = true }
    }

    private var pane: some View {
        VStack(alignment: .leading, spacing: 28) {
            ZeeStartPageMark()
                .frame(width: 84, height: 84)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 14) {
                Text("Welcome to Zee")
                    .font(ZeeTypography.display(68))
                    .foregroundStyle(ZeeBrandTheme.textDisplay)
                    .accessibilityAddTraits(.isHeader)
                Text("Your browser, your way.")
                    .font(ZeeTypography.sans(21, weight: .medium))
                    .foregroundStyle(ZeeBrandTheme.textDisplay.opacity(0.88))
                Text("No AI built in. Your tabs stay yours.")
                    .font(ZeeTypography.sans(15, weight: .regular))
                    .foregroundStyle(ZeeBrandTheme.textDisplay.opacity(0.72))
            }
            BrowserOnboardingWelcomeCallToAction(
                action: action,
                cloudStatusDetail: cloudStatusDetail,
                perform: performAction,
                setUpWithoutCloud: setUpWithoutCloud
            )
        }
        .padding(BrowserOnboardingWelcomeMetrics.panePadding)
        .glassEffect(
            .regular.tint(ZeeBrandPalette.midnight.opacity(BrowserOnboardingWelcomeMetrics.paneShade)),
            in: .rect(cornerRadius: BrowserOnboardingWelcomeMetrics.paneCornerRadius)
        )
        .padding(.leading, -BrowserOnboardingWelcomeMetrics.panePadding)
    }

    private func performAction() {
        guard !action.waitsOnCloud else { return }
        if action.opensZee {
            openZee()
        } else {
            continueSetup()
        }
    }
}

enum BrowserOnboardingWelcomeMetrics {
    static let panePadding: CGFloat = 40
    static let paneCornerRadius: CGFloat = 36
    /// How much midnight tints the pane, so its words read over any wave.
    static let paneShade = 0.45
    /// The pane arrives a beat after the waves begin to rise.
    static let arrival = Animation.smooth(duration: 1.1).delay(0.45)
    /// The Space the banner shows: the simple look in Zee's ocean blue.
    static let previewBranding = BrowserSimpleSpaceColor.all[0].applied(to: SpaceHouse.winter.look)
}
