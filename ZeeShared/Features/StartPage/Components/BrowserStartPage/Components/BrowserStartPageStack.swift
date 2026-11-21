import SwiftUI

/// The start page's column: the header, the palette, then any invitation to
/// bring another browser's data.
struct BrowserStartPageStack: View {
    let page: BrowserStartPage

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: page.layout.spacing) {
            BrowserStartPageHeader(
                isPrivateBrowsing: page.isPrivateBrowsing,
                layout: page.layout,
                colorScheme: page.headerColorScheme
            )
            // Nothing in the header takes a tap, so one there reaches the page.
            .allowsHitTesting(false)
            BrowserStartPageCommandPalette(page: page)
                // The palette is material over the page's backdrop, so it reads
                // in the material color over the scheme its title reads in.
                .environment(
                    \.colorScheme,
                    ZeeSurfaceTone.shownScheme(over: page.headerColorScheme ?? colorScheme, window: colorScheme))
            if let invitation = page.invitation, !page.isPrivateBrowsing {
                BrowserStartPageInvitationCard(invitation: invitation)
            }
        }
        .padding(page.layout.padding)
        .frame(maxWidth: page.layout.maximumWidth)
    }
}
