using ZeeCore.Application;

namespace ZeeCore.Contracts;

/// Hides the element `Selector` picks on pages at `Host` in `SpaceId`: in the
/// Space's own Boost for that site, or in a new one, `NewBoostId`, made for it.
/// Refused as `SaveBoost` refuses a Boost the Space does not keep.
public sealed record HideElementInBoost(Guid WorkspaceId, Guid SpaceId, string Host, string Selector, Guid NewBoostId)
    : SessionIntent(WorkspaceId) {
    #region Actions - Session

    internal override SessionEdit? Edit(NativeSessionAuthority workspace, SessionTurn turn) {
        workspace.RequireOwnedSpaces();
        var space = workspace.Editable(turn.Basis, SpaceId);
        var domain = Boost.Normalized(Host) ?? throw new Rejected(new BoostDomainInvalid());
        var existing = space.Settings.ShownBoosts.FirstOrDefault(boost => boost.Domain == domain);
        var boost = existing ?? Boost.For(NewBoostId, domain, turn.Now)!;
        var edited = (boost with { IsOn = true, HiddenElements = [.. boost.HiddenElements, Selector] }).Validated() with { ModifiedAt = turn.Now };
        var boosts = space.Settings.ShownBoosts.ToList();
        if (existing is null) {
            if (boosts.Count >= Boost.MaximumPerSpace) throw new Rejected(new BoostsFull(Boost.MaximumPerSpace));
            boosts.Add(edited);
        } else {
            boosts[boosts.IndexOf(existing)] = edited;
        }
        return new(turn.Basis.Replacing(space.Configured(space.Settings.Boosting(boosts, turn.Now))), SyncStaging.Edit);
    }

    #endregion
}
