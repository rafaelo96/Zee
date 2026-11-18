using ZeeCore.Application;

namespace ZeeCore.Contracts;

/// Every site where Zee blocks no ads or trackers.
public sealed record GetSiteContentBlocking : Query<IReadOnlyList<SiteContentBlocking>> {
    #region Actions - Answering

    internal override IReadOnlyList<SiteContentBlocking> Answer(ZeeApp app) => app.Device.BlockingSites;

    #endregion
}
