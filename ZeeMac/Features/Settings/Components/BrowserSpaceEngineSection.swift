import SwiftUI

/// The engine a Space's new pages open on when no site's choice decides: the
/// device's default, or one of its own, as a Space for work in Chromium with
/// its extensions and a personal one in WebKit. It syncs with the Space.
struct BrowserSpaceEngineSection: View {
    let browser: BrowserStore
    let space: SpaceModel

    private var engines: [EngineKind] { browser.core.state.engines?.engines.map(\.kind) ?? [] }

    var body: some View {
        if engines.count > 1 {
            Section {
                Picker("Engine", selection: choice) {
                    Label("Device Default", systemImage: "laptopcomputer").tag(EngineKind?.none)
                    ForEach(engines, id: \.self) { engine in
                        Label(engine.title, systemImage: engine == .chromium ? "globe" : "square.stack")
                            .tag(EngineKind?.some(engine))
                    }
                }
                .accessibilityIdentifier("space-engine")
            } footer: {
                ZeeFormFootnote(
                    "New pages in this Space open on this engine unless you chose one for their site. Open pages keep their engine."
                )
            }
        }
    }

    private var choice: Binding<EngineKind?> {
        Binding(
            get: { space.settings.preferredEngine },
            set: { engine in
                _ = browser.sendSpaceSettings(
                    SetSpaceEngine(
                        workspaceID: browser.profileSettingsBrowser.family.workspaceID, spaceID: space.id,
                        engine: engine))
            })
    }
}
