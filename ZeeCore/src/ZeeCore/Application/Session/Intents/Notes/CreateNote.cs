using ZeeCore.Application;
using ZeeCore.Domain;

namespace ZeeCore.Contracts;

/// Writes a new, empty note, `NoteId`, in `SpaceId` and opens it in a tab,
/// `TabId`, among the Space's open tabs where a new tab goes, which the window
/// that asked shows. Refused with `NotesFull` past the most a Space holds, and
/// with `TabLimitReached` when the Space holds no more tabs.
public sealed record CreateNote(Guid WorkspaceId, Guid WindowId, Guid SpaceId, Guid NoteId, Guid TabId) : SessionIntent(WorkspaceId) {
    #region Actions - Session

    internal override SessionEdit? Edit(NativeSessionAuthority workspace, SessionTurn turn) {
        workspace.RequireOwnedSpaces();
        var space = workspace.Editable(turn.Basis, SpaceId);
        if (turn.Basis.Spaces.Any(candidate => candidate.Tabs.Any(tab => tab.Id == TabId)))
            throw new Rejected(new TabAlreadyExists(TabId));
        var notes = space.Settings.ShownNotes;
        if (notes.Count >= Note.MaximumPerSpace) throw new Rejected(new NotesFull(Note.MaximumPerSpace));
        var noted = space.Configured(space.Settings.Noting([.. notes, Note.Empty(NoteId, turn.Now)], turn.Now));
        var edited = BrowserTabCollection.Restore(noted);
        var opened = workspace.NewTab(TabId, new TabContent(null, NativeView.Note, null), TabPlacement.Current, turn.Now);
        var tab = BrowserTab.Restore(opened with { NativeContent = new NativeTabContent(NativeView.Note.Name, NoteId) });
        edited.InsertTab(tab, workspace.PositionForNewTabs(turn.Basis).InsertionIndex);
        var followUp = new WindowFollowUp(workspace.IssuingWindow(WindowId)).ShowTab(space.Id, tab.Id).ShowSpace(space.Id);
        return new(turn.Basis.Replacing(edited.Capture(noted)), SyncStaging.Creation, followUp);
    }

    #endregion
}
