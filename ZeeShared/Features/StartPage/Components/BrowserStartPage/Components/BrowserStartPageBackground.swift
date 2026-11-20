import SwiftUI

/// What shows behind the start page's stack.
///
/// A shell that puts the page on the Space's banner says so in its layout; the
/// rest leave the page clear and let whatever the shell already drew show
/// through, unless Sidebar transparency clears the window: the page then keeps
/// the Space's look itself, so only the frame around it shows the desktop.
struct BrowserStartPageBackground: View {
    let page: BrowserStartPage

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    @ViewBuilder
    var body: some View {
        if page.layout.backgroundIgnoresSafeArea {
            backdrop
                .ignoresSafeArea()
                .accessibilityHidden(true)
        } else {
            backdrop
                .accessibilityHidden(true)
        }
    }

    @ViewBuilder
    private var backdrop: some View {
        if page.layout.showsSpaceBanner, let space = page.space {
            BrowserSpaceBannerBackground(branding: space.settings.look.shown)
        } else if clearsWindow {
            if let space = page.space {
                BrowserSpaceBannerBackground(branding: space.settings.look.shown)
            } else {
                ZeeColor.windowBackground
            }
        } else {
            Color.clear
        }
    }

    /// Whether the window behind the page lets the desktop through.
    private var clearsWindow: Bool {
        !reduceTransparency && BrowserDeviceAppearanceStore.shared.sidebarTransparency > 0
    }
}
