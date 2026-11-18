using ZeeCore.Application;

namespace ZeeCore.Contracts;

/// The downloads the platform should make now. Each one handed out is not
/// handed out again for a while, so the platform reports how it went with
/// `FilterDownloadFetched`, `FilterDownloadNotModified` or `FilterDownloadFailed`.
public sealed record DueFilterDownloads : Query<IReadOnlyList<FilterDownload>> {
    #region Actions - Answering

    internal override IReadOnlyList<FilterDownload> Answer(ZeeApp app) => app.Filters.Due();

    #endregion
}
