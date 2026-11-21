using ZeeCore.Application;

namespace ZeeCore.Contracts;

/// Removes the Boost `BoostId` names from `SpaceId`. Refused with
/// `UnknownBoost` for one the Space does not hold.
public sealed record DeleteBoost(Guid WorkspaceId, Guid SpaceId, Guid BoostId) : SessionIntent(WorkspaceId) {
    #region Actions - Session

    internal override SessionEdit? Edit(NativeSessionAuthority workspace, SessionTurn turn) {
        workspace.RequireOwnedSpaces();
        var space = workspace.Editable(turn.Basis, SpaceId);
        var boosts = space.Settings.ShownBoosts;
        if (boosts.All(boost => boost.Id != BoostId)) throw new Rejected(new UnknownBoost(BoostId));
        var kept = boosts.Where(boost => boost.Id != BoostId).ToArray();
        return new(turn.Basis.Replacing(space.Configured(space.Settings.Boosting(kept, turn.Now))), SyncStaging.Edit);
    }

    #endregion
}
