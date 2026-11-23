import Foundation

/// Notes: writing a new one in the Space the window shows, keeping what the
/// person writes, and finding the note a tab shows. The core keeps every note
/// with its Space's settings, so a note syncs and goes with its Space.
extension BrowserStore {
    // MARK: - Actions - Notes

    /// Writes a new, empty note in the Space this window shows and opens it
    /// in a tab there, which the window shows. Answers the tab, or nil when
    /// the core refused, which it reports as a notice.
    @discardableResult
    func createNote() -> UUID? {
        guard let space = shownSpace else { return nil }
        let tabID = UUID()
        let creating = CreateNote(
            workspaceID: family.workspaceID, windowID: windowID, spaceID: space.id, noteID: UUID(), tabID: tabID,
            shows: true)
        return family.perform(creating, from: self) == nil ? nil : tabID
    }

    /// The images notes show, which stay on this device.
    var noteImages: BrowserNoteImageStore {
        BrowserNoteImageStore(storageDirectory: core.storageDirectory)
    }

    /// Adds `markdown` to the end of the note of `spaceID` someone changed
    /// last, or to a new note, titled `newTitle`, when the Space holds none,
    /// leaving the window where it is. Says where it went in the window's
    /// notice, and answers whether it did.
    @discardableResult
    func addToNote(_ markdown: String, in spaceID: UUID, newTitle: String) -> Bool {
        guard !isPrivateBrowsing, var space = spaceModel(spaceID) else { return false }
        var target = space.settings.shownNotes.max { $0.modifiedAt < $1.modifiedAt }
        if target == nil {
            let creating = CreateNote(
                workspaceID: family.workspaceID, windowID: windowID, spaceID: spaceID, noteID: UUID(), tabID: UUID(),
                shows: false)
            guard family.perform(creating, from: self) != nil, let created = spaceModel(spaceID) else { return false }
            space = created
            target = space.settings.shownNotes.max { $0.modifiedAt < $1.modifiedAt }
        }
        guard let note = target else { return false }
        let title = note.title.isEmpty && note.body.isEmpty ? newTitle : note.title
        let body = note.body.isEmpty ? markdown : note.body + "\n\n" + markdown
        guard saveNote(note.id, in: spaceID, title: title, body: body) else { return false }
        let shown = title.isEmpty ? String(localized: NativeView.note.title) : title
        BrowserNoticeCenter.shared.post(
            BrowserNotice(message: String(localized: "Added to “\(shown)”"), systemImage: "note.text"))
        return true
    }

    /// Keeps `title` and `body` as the note `noteID` of `spaceID`.
    @discardableResult
    func saveNote(_ noteID: UUID, in spaceID: UUID, title: String, body: String) -> Bool {
        family.send(
            SaveNote(workspaceID: family.workspaceID, spaceID: spaceID, noteID: noteID, title: title, body: body),
            from: self)
    }

    /// Deletes the note `noteID` of `space` and the tab `tabID` that showed
    /// it, so no tab is left showing a note that is gone.
    func deleteNote(_ noteID: UUID, shownIn tabID: UUID, in space: SpaceModel) {
        deleteTab(tabID, in: space.id)
        _ = family.send(DeleteNote(workspaceID: family.workspaceID, spaceID: space.id, noteID: noteID), from: self)
    }

    /// The note `noteID` of `space`, or nil when the Space no longer holds it.
    func note(_ noteID: UUID?, in space: SpaceModel) -> Note? {
        guard let noteID else { return nil }
        return space.settings.shownNotes.first { $0.id == noteID }
    }
}
