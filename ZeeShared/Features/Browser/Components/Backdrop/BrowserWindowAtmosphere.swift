import SwiftUI

/// The window's chrome: the Space's look, over the desktop blurred through
/// the Mac's sidebar glass as far as the person's Sidebar transparency asks.
struct BrowserWindowAtmosphere: View {
    // MARK: - Variables

    /// The Space the window shows, or nil for none.
    let space: SpaceModel?

    /// The Space's look as the current appearance shows it, read in `body`
    /// so it follows the appearance and Space-colors preferences.
    private var branding: SpaceBranding? {
        space.map(\.settings.look.shown)
    }

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    private var transparency: Double {
        reduceTransparency ? 0 : BrowserDeviceAppearanceStore.shared.sidebarTransparency
    }

    var body: some View {
        ZStack {
            if transparency > 0 {
                // The Mac's glass is nearly opaque on its own, so it thins
                // too, until the desktop itself shows around the page.
                ZeeWindowMaterial()
                    .opacity(1 - transparency * BrowserWindowAtmosphereMetrics.glassThinning)
            }
            if let branding {
                BrowserSpaceBannerBackground(branding: branding, transparency: transparency)
            } else {
                ZeeColor.windowBackground.opacity(1 - transparency)
            }
        }
        .accessibilityHidden(true)
    }
}

enum BrowserWindowAtmosphereMetrics {
    /// How much of the glass full transparency thins away: most of it, while
    /// enough stays that the frame still catches the pointer.
    static let glassThinning = 0.85
}
