import SwiftUI

struct BrowserSettingsPrivateSpaceIdentity: View {
    // MARK: - Variables

    let space: BrowserSpaceIdentity

    // MARK: - Initializers

    init(space: some BrowserSpaceIdentifying) {
        self.space = space.identity
    }

    // MARK: - Body

    var body: some View {
        Group {
            BrowserSpaceSymbolArtwork(identity: space, size: 34, lockSize: 8)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: ZeeFormRowMetrics.titleSpacing) {
                Text(space.name)
                    .font(ZeeTypography.controlTitle)
                Text("Private Space")
                    .font(ZeeTypography.metadata)
                    .foregroundStyle(ZeeColor.textSecondary)
            }
        }
    }
}

#if DEBUG
    #Preview("Component") {
        BrowserSettingsPrivateSpaceIdentity(space: BrowserSpaceBrandingPreviewFixture.zeeSpace).padding().frame(
            width: 360)
    }
#endif
