using ZeeCore.Application;

namespace ZeeCore.Contracts;

/// Why a download looks dangerous and whether, given how it started, the
/// person must confirm it before it continues.
public sealed record DownloadRisk(DownloadRiskFacts Facts, bool IsUserInitiated) : Query<DownloadRiskVerdict> {
    #region Actions - Answering

    /// The engines' downloads ask the ledger the same question.
    internal override DownloadRiskVerdict Answer(ZeeApp app) => app.Downloads.Answer(this);

    #endregion
}
