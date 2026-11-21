using ZeeCore.Application;

namespace ZeeCore.Contracts;

/// Keeps `Boost` in `SpaceId`, in place of the one of its identity or after
/// the others, as the person left it now. Refused with `BoostDomainInvalid`
/// or `BoostTooLarge` for a Boost a Space does not keep, and `BoostsFull`
/// past the most a Space holds.
public sealed record SaveBoost(Guid WorkspaceId, Guid SpaceId, Boost Boost) : SessionIntent(WorkspaceId) {
    #region Actions - Session

    internal override SessionEdit? Edit(NativeSessionAuthority workspace, SessionTurn turn) {
        workspace.RequireOwnedSpaces();
        var space = workspace.Editable(turn.Basis, SpaceId);
        var kept = Boost.Validated() with { ModifiedAt = turn.Now };
        var boosts = space.Settings.ShownBoosts.ToList();
        int index = boosts.FindIndex(boost => boost.Id == kept.Id);
        if (index >= 0) {
            boosts[index] = kept;
        } else {
            if (boosts.Count >= Contracts.Boost.MaximumPerSpace) throw new Rejected(new BoostsFull(Contracts.Boost.MaximumPerSpace));
            boosts.Add(kept);
        }
        return new(turn.Basis.Replacing(space.Configured(space.Settings.Boosting(boosts, turn.Now))), SyncStaging.Edit);
    }

    #endregion
}
