using ZeeCore.Application;

namespace ZeeCore.Contracts;

/// Sets the engine `SpaceId`'s new pages open on when no site's choice
/// decides, or follows the device's default again when null. It reaches the
/// person's other devices with the time they chose. A device that did not
/// register the engine opens the Space's pages on its own default.
public sealed record SetSpaceEngine(Guid WorkspaceId, Guid SpaceId, EngineKind? Engine) : SessionIntent(WorkspaceId) {
    #region Actions - Session

    internal override SessionEdit? Edit(NativeSessionAuthority workspace, SessionTurn turn) {
        workspace.RequireOwnedSpaces();
        var space = workspace.Editable(turn.Basis, SpaceId);
        if (space.Settings.PreferredEngine == Engine) return new(turn.Basis, SyncStaging.Edit);
        var edited = space.Configured(space.Settings with {
            PreferredEngine = Engine,
            PreferredEngineModifiedAt = SpaceSettings.Chosen(space.Settings.PreferredEngineModifiedAt, turn.Now)
        });
        return new(turn.Basis.Replacing(edited), SyncStaging.Edit);
    }

    #endregion
}
