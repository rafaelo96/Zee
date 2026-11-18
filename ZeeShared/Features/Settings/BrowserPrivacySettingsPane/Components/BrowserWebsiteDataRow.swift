import SwiftUI

/// One site that keeps data in a Space: its name, what it keeps, and Remove.
struct BrowserWebsiteDataRow: View {
    let site: StoredSite
    let isRemoving: Bool
    let remove: () -> Void

    var body: some View {
        HStack(spacing: ZeeFormRowMetrics.contentSpacing) {
            VStack(alignment: .leading, spacing: ZeeFormRowMetrics.titleSpacing) {
                Text(site.site)
                    .lineLimit(1)
                Text(kinds)
                    .font(ZeeTypography.metadata)
                    .foregroundStyle(ZeeColor.textSecondary)
                    .lineLimit(1)
            }
            Spacer(minLength: ZeeSpacing.small)
            Button("Remove", action: remove)
                .disabled(isRemoving)
                .accessibilityLabel("Remove data for \(site.site)")
        }
        .frame(minHeight: ZeeFormRowMetrics.minimumHeight)
        .contextMenu {
            Button("Remove", systemImage: "trash", role: .destructive, action: remove)
                .zeeMenuActionLabelStyle()
        }
    }

    /// What the site keeps, as a list a person reads.
    private var kinds: String {
        site.kinds.map { String(localized: $0.title) }.formatted(.list(type: .and))
    }
}
