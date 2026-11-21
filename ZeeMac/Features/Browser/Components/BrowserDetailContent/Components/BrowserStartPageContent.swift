import SwiftUI

struct BrowserStartPageContent: View {
    /// The tab this start page belongs to.
    ///
    /// Split View renders one of these per card, so the surface can no longer
    /// assume it is speaking for the selected tab. Every action still routes
    /// through `BrowserStore.isPaletteSourceAvailable`, which answers "unavailable"
    /// for a card that is not the focused one — an unfocused start page reads
    /// but does not act until a click makes it the focused card.
    let tab: TabStateModel?
    let space: SpaceModel?
    let browser: BrowserStore
    let pages: BrowserPagePool
    let spaceAccess: BrowserSpaceAccessController
    let tabPromotionNamespace: Namespace.ID
    let focusRequest: Int
    let isCommandPalettePresented: Bool
    /// The window's commands, which the page's palette offers once what is
    /// typed matches one. They run exactly as they do from the overlay.
    let commands: BrowserCommandPaletteCommandRegistry

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.browserMacWindows) private var windows
    /// The core's invitation to bring another browser's data, which the page
    /// asks for each time it appears.
    @State private var invitation: ImportInvitation?

    var body: some View {
        if let space {
            BrowserStartPage(
                browser: browser,
                space: space,
                isPrivateBrowsing: browser.isPrivateBrowsing,
                selectedTabID: tab?.id,
                isSourceAvailable: isSourceAvailable,
                selectTab: selectStartPageTab,
                openURL: openStartPageURL,
                isCommandPaletteObscured: isCommandPalettePresented,
                layout: .macOSPage,
                focusRequest: space.id == browser.selectedSpaceID && tab != nil && tab?.id == browser.shownTab?.id
                    ? focusRequest
                    : nil,
                promotion: tab.map { tab in
                    BrowserStartPagePromotion(
                        namespace: tabPromotionNamespace,
                        id: BrowserTabPromotionID.value(for: tab.id)
                    )
                },
                // The page shows the Space's backdrop, so its title reads in
                // the Space's scheme, as the sidebar's text does.
                headerColorScheme: space.settings.look.shown.colorScheme(over: colorScheme),
                commands: commands,
                invitation: shownInvitation
            )
            .task { loadInvitation() }
        } else {
            BrowserUnloadedPageSurface()
        }
    }

    /// The invitation as the page offers it, once the core made one.
    private var shownInvitation: BrowserStartPageInvitation? {
        guard let source = invitation?.source, !browser.isPrivateBrowsing else { return nil }
        return BrowserStartPageInvitation(
            source: source, stopsWorkingAt: invitation?.stopsWorkingAt,
            bring: {
                settle(source)
                windows?.openOnboardingWindow(.importBrowser)
            },
            dismiss: { settle(source) })
    }

    /// Asks the core which browser, among those whose app or data is on this
    /// Mac, it invites the person to bring. Finding them reads none of their
    /// data.
    private func loadInvitation() {
        guard !browser.isPrivateBrowsing else { return }
        let found = BrowserInstalledImportSourceDetector.installedSources().map(\.application)
        invitation = try? browser.core.query(GetImportInvitation(found: found))
    }

    /// The person brought `source` or dismissed its invitation, so Zee never
    /// offers it again here.
    private func settle(_ source: ImportSource) {
        _ = try? browser.core.send(SettleImportInvitation(source: source))
        withAnimation(ZeeMotion.contentNavigation.unlessReducingMotion(reduceMotion)) { invitation = nil }
    }

    private func openStartPageURL(
        _ source: BrowserTabRuntimeAssignment,
        _ url: URL
    ) -> Bool {
        return withAnimation(
            ZeeMotion.contentNavigation.unlessReducingMotion(reduceMotion)
        ) {
            BrowserStartPageNavigationAction(
                browser: browser,
                pages: pages,
                spaceAccess: spaceAccess
            ).perform(source, url: url)
        }
    }

    private func selectStartPageTab(
        _ source: BrowserTabRuntimeAssignment,
        _ target: BrowserTabRuntimeAssignment
    ) -> Bool {
        guard
            let destination = browser.paletteTarget(target, from: source, accessController: spaceAccess)
        else { return false }
        browser.selectSpace(destination.space.id)
        browser.selectTab(destination.tab.id)
        pages.select()
        return true
    }

    private func isSourceAvailable(
        _ source: BrowserTabRuntimeAssignment
    ) -> Bool {
        browser.isPaletteSourceAvailable(source, accessController: spaceAccess)
    }
}
