import SwiftUI

/// The content seam used by both single cards and Split View, on every shell.
/// The surrounding layout owns identity, geometry, focus, and placement.
struct BrowserNativeTabHost: View {
    let tab: TabStateModel
    let space: SpaceModel
    /// The shell's floating controls remain outside native scrolling content.
    var bottomChromeHeight: CGFloat = 0
    @Environment(\.browserSettingsTabContent) private var settingsContent
    @Environment(\.browserNativeTabActions) private var actions
    @Environment(\.browserNativeTabs) private var nativeTabs

    var body: some View {
        Group {
            if let content = tab.nativeTabContent,
                let runtime = nativeTabs?.runtime(matching: assignment, content: content)
            {
                switch tab.nativeView {
                case .gettingStarted?:
                    BrowserGettingStartedTabAdapter(runtime: runtime, bottomChromeHeight: bottomChromeHeight) { url in
                        actions.openURL(assignment, content, url)
                    }
                case .note?:
                    if let note = space.settings.shownNotes.first(where: { $0.id == content.resourceID }) {
                        BrowserNoteTabView(
                            note: note,
                            save: { title, body in actions.saveNote(assignment, content, title, body) },
                            openLink: { url in actions.openURL(assignment, content, url) },
                            delete: { actions.deleteNote(assignment, content) },
                            imageURL: actions.noteImageURL
                        )
                        // A note another device replaced, or this one, starts the editor over.
                        .id(note.id)
                    } else {
                        ContentUnavailableView(
                            "This note was deleted", systemImage: "note.text",
                            description: Text("Close this tab, or write a new note from the File menu.")
                        )
                    }
                case .settings?:
                    if let settingsContent {
                        settingsContent.makeView(runtime)
                    } else {
                        ContentUnavailableView("Settings unavailable", systemImage: "gearshape")
                    }
                default:
                    ContentUnavailableView(
                        "This tab needs a newer Zee", systemImage: "square.stack.3d.up",
                        description: Text("Its content is still saved. Update Zee to open it.")
                    )
                }
            }
        }
        .id(tab.nativeTabContent.flatMap { nativeTabs?.runtime(matching: assignment, content: $0)?.id })
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaPadding(.bottom, bottomChromeHeight)
    }

    private var assignment: BrowserTabRuntimeAssignment {
        BrowserTabRuntimeAssignment(tabID: tab.id, spaceID: space.id, profileID: space.profileID)
    }
}

/// Native views can ask the shell to open a website, but cannot borrow a page
/// pool, switch profiles, or navigate whichever tab happens to be focused later.
struct BrowserNativeTabActions {
    var openURL: @MainActor (BrowserTabRuntimeAssignment, BrowserNativeTabContent, URL) -> Void = { _, _, _ in }
    /// Keeps a note's title and text, for the note the tab still shows.
    var saveNote: @MainActor (BrowserTabRuntimeAssignment, BrowserNativeTabContent, String, String) -> Void = { _, _, _, _ in }
    /// The file of an image a note shows, when this device keeps it.
    var noteImageURL: @MainActor (UUID) -> URL? = { _ in nil }
    /// Deletes the note the tab shows, and the tab with it.
    var deleteNote: @MainActor (BrowserTabRuntimeAssignment, BrowserNativeTabContent) -> Void = { _, _ in }

    @MainActor
    init(browser: BrowserStore, spaceAccess: BrowserSpaceAccessController, didOpenURL: @escaping @MainActor () -> Void)
    {
        openURL = { source, content, url in
            guard
                let space = browser.selectedUnlockedSpace(
                    matching: BrowserSpaceRuntimeAssignment(spaceID: source.spaceID, profileID: source.profileID),
                    accessController: spaceAccess),
                space.shownTab(source.tabID)?.nativeTabContent == content,
                ["https", "http"].contains(url.scheme?.lowercased() ?? "")
            else { return }
            browser.openNewTab(url: url, in: space.id)
            didOpenURL()
        }
        saveNote = { source, content, title, body in
            guard let noteID = content.resourceID,
                let space = browser.availableSpaces.first(where: {
                    $0.id == source.spaceID && $0.profileID == source.profileID
                }),
                !spaceAccess.isLocked(space)
            else { return }
            browser.saveNote(noteID, in: space.id, title: title, body: body)
        }
        let noteImages = browser.noteImages
        noteImageURL = { id in noteImages.existingFileURL(for: id) }
        deleteNote = { source, content in
            guard let noteID = content.resourceID,
                let space = browser.availableSpaces.first(where: {
                    $0.id == source.spaceID && $0.profileID == source.profileID
                }),
                !spaceAccess.isLocked(space)
            else { return }
            browser.deleteNote(noteID, shownIn: source.tabID, in: space)
        }
    }

    init() {}
}

private struct BrowserNativeTabActionsKey: EnvironmentKey {
    static let defaultValue = BrowserNativeTabActions()
}

extension EnvironmentValues {
    var browserNativeTabActions: BrowserNativeTabActions {
        get { self[BrowserNativeTabActionsKey.self] }
        set { self[BrowserNativeTabActionsKey.self] = newValue }
    }
}
