import SwiftUI

/// The quiet bar a WebKit page shows when Zee suggests Chromium for its site:
/// why, a button that moves the page there and remembers the site, and one
/// that leaves it be until Zee quits. It floats over the page's foot on Zee's
/// flyout surface.
struct BrowserEngineSuggestionBar: View {
    let suggestion: EngineSuggestion
    let open: () -> Void
    let dismiss: () -> Void

    var body: some View {
        if let reason = suggestion.reason, let engine = suggestion.engine {
            HStack(spacing: ZeeSpacing.medium) {
                Image(systemName: "globe")
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                Text(reason.message)
                    .font(.callout)
                Spacer(minLength: ZeeSpacing.small)
                Button("Open in \(Text(engine.title))", action: open)
                    .buttonStyle(.zeePrimary)
                    .accessibilityIdentifier("engine-suggestion-open")
                Button("Not Now", systemImage: "xmark", action: dismiss)
                    .labelStyle(.iconOnly)
                    .buttonStyle(ZeeChromeButtonStyle())
                    .help("Not Now")
            }
            .padding(.horizontal, ZeeSpacing.large)
            .padding(.vertical, ZeeSpacing.small)
            .frame(maxWidth: 520)
            .zeeFloatingFlyoutStyle(in: .rect(cornerRadius: ZeeRadius.panel))
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("engine-suggestion-bar")
        }
    }
}
