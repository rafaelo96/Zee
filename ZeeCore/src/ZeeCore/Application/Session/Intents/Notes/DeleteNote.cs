using ZeeCore.Application;

namespace ZeeCore.Contracts;

/// Removes the note `NoteId` from `SpaceId`. A tab that showed it shows an
/// empty note until it closes. Refused with `UnknownNote` for one the Space
/// does not hold.
public sealed record DeleteNote(Guid WorkspaceId, Guid SpaceId, Guid NoteId) : SessionIntent(WorkspaceId) {
    #region Actions - Session

    internal override SessionEdit? Edit(NativeSessionAuthority workspace, SessionTurn turn) {
        workspace.RequireOwnedSpaces();
        var space = workspace.Editable(turn.Basis, SpaceId);
        var notes = space.Settings.ShownNotes;
        if (notes.All(note => note.Id != NoteId)) throw new Rejected(new UnknownNote(NoteId));
        var kept = notes.Where(note => note.Id != NoteId).ToArray();
        return new(turn.Basis.Replacing(space.Configured(space.Settings.Noting(kept, turn.Now))), SyncStaging.Edit);
    }

    #endregion
}
