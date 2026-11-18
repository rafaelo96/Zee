import SwiftUI

struct BrowserSitePermissionRow: View {
    let permission: SitePermission
    let origin: SiteOrigin
    let spaceID: UUID
    let permissionCenter: BrowserSitePermissionCenter

    var body: some View {
        HStack(spacing: ZeeSpacing.small) {
            Label(permission.title, systemImage: permission.symbol)
                .font(.caption)
            Spacer(minLength: ZeeSpacing.small)
            Menu(permission.title(for: currentDecision)) {
                Group {
                    Button(permission.askChoiceTitle, systemImage: "questionmark.circle") {
                        setDecision(.ask)
                    }
                    // The system asks each time for some capabilities, so
                    // nothing allows a site ahead of that question.
                    if !permission.isAskedBySystem {
                        Button("Allow", systemImage: "checkmark.circle") {
                            setDecision(.grantPersistently)
                        }
                    }
                    Button("Block", systemImage: "nosign") {
                        setDecision(.denyPersistently)
                    }
                }
                .zeeMenuActionLabelStyle()
            }
            .menuStyle(.borderlessButton)
            .zeeMenuActionLabelStyle()
            .fixedSize()
        }
    }

    private var currentDecision: SitePermissionDecision {
        permissionCenter.decision(
            for: permission,
            origin: origin,
            in: spaceID
        )
    }

    private func setDecision(_ decision: SitePermissionDecision) {
        permissionCenter.setDecision(
            decision,
            for: permission,
            origin: origin,
            in: spaceID
        )
    }
}
