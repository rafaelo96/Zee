using ZeeCore.Application;

namespace ZeeCore.Contracts;

/// What a page of `SpaceId` in `WorkspaceId` at `Host` runs of the Boosts:
/// those of its Space that are on and match its site, then those made in any
/// other Space of the workspace for every Space. None for a Space the
/// workspace does not hold.
public sealed record BoostsFor(Guid WorkspaceId, Guid SpaceId, string? Host) : Query<IReadOnlyList<BoostScript>> {
    #region Actions - Answering

    internal override IReadOnlyList<BoostScript> Answer(ZeeApp app) {
        var spaces = app.Device.Workspace(WorkspaceId).Current.Spaces;
        if (spaces.All(space => space.Id != SpaceId)) return [];
        var own = spaces.Where(space => space.Id == SpaceId).SelectMany(space => space.Settings.ShownBoosts);
        var everywhere = spaces.Where(space => space.Id != SpaceId)
            .SelectMany(space => space.Settings.ShownBoosts.Where(boost => boost.AppliesToAllSpaces));
        return [.. own.Concat(everywhere).Where(boost => boost.Matches(Host)).Select(boost => boost.Applied()).OfType<BoostScript>()];
    }

    #endregion
}
