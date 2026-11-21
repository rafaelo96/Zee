import SwiftUI

/// The sites a Space restyles with Boosts: each one's switch, whether it
/// reaches every Space, and a way to delete it. Boosts are made and edited
/// from a site's Site Controls.
struct BrowserSpaceBoostsSection: View {
    let browser: BrowserStore
    let space: SpaceModel

    private var workspaceID: UUID { browser.profileSettingsBrowser.family.workspaceID }

    var body: some View {
        Section {
            if space.settings.shownBoosts.isEmpty {
                Text("No Boosts yet").foregroundStyle(.secondary)
            }
            ForEach(space.settings.shownBoosts) { boost in
                HStack(spacing: ZeeSpacing.small) {
                    Toggle(isOn: Binding(get: { boost.isOn }, set: { isOn in save(boost, isOn: isOn) })) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(boost.domain)
                            if boost.appliesToAllSpaces {
                                Text("Every Space").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                    Button("Delete Boost", systemImage: "trash") {
                        _ = browser.sendSpaceSettings(
                            DeleteBoost(workspaceID: workspaceID, spaceID: space.id, boostID: boost.id))
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(ZeeChromeButtonStyle())
                    .help("Delete Boost")
                }
            }
        } header: {
            Text("Boosts")
        } footer: {
            ZeeFormFootnote(
                "A Boost restyles a site and its subdomains in this Space. Make or edit one from the site’s Site Controls."
            )
        }
    }

    private func save(_ boost: Boost, isOn: Bool) {
        var edited = boost
        edited.isOn = isOn
        _ = browser.sendSpaceSettings(SaveBoost(workspaceID: workspaceID, spaceID: space.id, boost: edited))
    }
}
