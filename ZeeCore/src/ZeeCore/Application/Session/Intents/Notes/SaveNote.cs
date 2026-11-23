using ZeeCore.Application;

namespace ZeeCore.Contracts;

/// Keeps `Title` and `Body` as the note `NoteId` of `SpaceId`, as the person
/// left it now, and names every tab of the Space that shows it by it. Refused
/// with `UnknownNote` for a note the Space does not hold, and `NoteTooLarge`
/// for text past what a note, or the Space's notes together, hold.
public sealed record SaveNote(Guid WorkspaceId, Guid SpaceId, Guid NoteId, string Title, string Body) : SessionIntent(WorkspaceId) {
    #region Actions - Session

    internal override SessionEdit? Edit(NativeSessionAuthority workspace, SessionTurn turn) {
        workspace.RequireOwnedSpaces();
        var space = workspace.Editable(turn.Basis, SpaceId);
        var notes = space.Settings.ShownNotes.ToList();
        int index = notes.FindIndex(note => note.Id == NoteId);
        if (index < 0) throw new Rejected(new UnknownNote(NoteId));
        var kept = (notes[index] with { Title = Title, Body = Body, ModifiedAt = turn.Now }).Validated();
        if (kept.Title == notes[index].Title && kept.Body == notes[index].Body) return null;
        notes[index] = kept;
        if (notes.Sum(note => note.Bytes) > Note.MaximumSpaceBytes)
            throw new Rejected(new NoteTooLarge(Note.MaximumBodyBytes, Note.MaximumSpaceBytes));
        var title = kept.TabTitle ?? (kept.IsEasel ? NativeView.Easel : NativeView.Note).Title;
        var tabs = space.Tabs.Select(tab => tab.NativeContent is { ResourceId: { } shown } && shown == NoteId && tab.Title != title
            ? tab with { Title = title } : tab).ToArray();
        var edited = space.Configured(space.Settings.Noting(notes, turn.Now)) with { Tabs = tabs };
        return new(turn.Basis.Replacing(edited), SyncStaging.Edit);
    }

    #endregion
}
