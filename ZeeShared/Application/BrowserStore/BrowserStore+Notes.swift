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
            workspaceID: family.workspaceID, windowID: windowID, spaceID: space.id, noteID: UUID(), tabID: tabID)
        return family.perform(creating, from: self) == nil ? nil : tabID
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
