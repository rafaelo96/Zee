import SwiftUI

/// The sample page at the chosen default zoom, for the Page card when the pane
/// has no pinned window crop to show it in.
struct BrowserLookAndFeelPagePreview: View {
    private var pageZoom = BrowserDefaultPageZoomStore.shared

    var body: some View {
        BrowserSettingsPagePreview(zoom: pageZoom.defaultZoom)
            .clipShape(.rect(cornerRadius: ZeeRadius.compact, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: ZeeRadius.compact, style: .continuous)
                    .strokeBorder(.primary.opacity(ZeeOpacity.border))
            }
            .frame(maxWidth: .infinity)
            .accessibilityIdentifier("default-page-zoom-preview")
    }
}
