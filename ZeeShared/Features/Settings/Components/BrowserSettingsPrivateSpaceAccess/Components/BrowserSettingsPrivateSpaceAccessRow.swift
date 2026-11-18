import SwiftUI

struct BrowserSettingsPrivateSpaceAccessRow: View {
    // MARK: - Variables

    let space: BrowserSpaceIdentity
    let accessController: BrowserSpaceAccessController

    // MARK: - Initializers

    init(space: some BrowserSpaceIdentifying, accessController: BrowserSpaceAccessController) {
        self.space = space.identity
        self.accessController = accessController
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: ZeeSpacing.medium) {
            BrowserSettingsPrivateSpaceIdentity(space: space)
            Spacer(minLength: ZeeSpacing.small)
            BrowserSettingsPrivateSpaceUnlockControl(
                space: space,
                accessController: accessController
            )
        }
        .frame(minHeight: ZeeFormRowMetrics.minimumHeight)
        .accessibilityElement(children: .contain)
    }
}
