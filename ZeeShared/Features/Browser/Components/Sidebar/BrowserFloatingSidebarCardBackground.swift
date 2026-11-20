import SwiftUI

struct BrowserFloatingSidebarCardBackground: View {
    private static let spaceThemeOpacity = 1.0

    let space: SpaceModel?

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        ZStack {
            platformBackground
                .opacity(1 - transparency * BrowserFloatingSidebarCardMetrics.glassThinning)

            if let space {
                BrowserSpaceBannerBackground(branding: space.settings.look.shown, transparency: transparency)
                    .opacity(Self.spaceThemeOpacity)
            }

            if !reduceTransparency {
                LinearGradient(
                    colors: [
                        .white.opacity(
                            BrowserRootMetrics.floatingSidebarHighlightOpacity
                        ),
                        .clear,
                        .black.opacity(
                            BrowserRootMetrics.floatingSidebarShadeOpacity
                        ),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        .accessibilityHidden(true)
    }

    /// How much of the card is glass, following the window's transparency.
    /// The system's Reduce Transparency keeps it solid.
    private var transparency: Double {
        reduceTransparency ? 0 : BrowserDeviceAppearanceStore.shared.sidebarTransparency
    }

    /// The Mac grounds the card in the window's own color; touch layers it on
    /// the secondary system background.
    private var platformBackground: Color {
        #if os(macOS)
            ZeeColor.windowBackground
        #else
            Color(uiColor: .secondarySystemBackground)
        #endif
    }
}

enum BrowserFloatingSidebarCardMetrics {
    /// How much of the card's own color fully transparent glass gives up,
    /// leaving enough that the page beneath never competes with the rows.
    static let glassThinning = 0.7
}
