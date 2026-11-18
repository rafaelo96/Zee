using ZeeCore.Application;

namespace ZeeCore.Contracts;

/// The scriptlets a page of `SpaceId` runs in its own world at `Url`, before
/// the page's scripts, as one script: empty when Zee does not block on the
/// site, or the filter runs none there.
public sealed record PageScriptlets(Guid SpaceId, string Url) : Query<string> {
    #region Actions - Answering

    internal override string Answer(ZeeApp app) =>
        app.Device.Blocks(SpaceId, new WebAddress(Url).Origin) ? app.Filters.Scriptlets(Url) : "";

    #endregion
}
