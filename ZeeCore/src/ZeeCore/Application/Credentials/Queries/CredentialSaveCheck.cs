using ZeeCore.Application;

namespace ZeeCore.Contracts;

/// Whether a save candidate submitted at `SubmittedAt` may still be planned or
/// committed at `Now`. Both are in seconds since 1970.
public sealed record CredentialSaveCheck(CredentialOrigin Origin, CredentialOrigin TopLevelOrigin, double SubmittedAt,
    double Now) : Query<CredentialSaveVerdict> {
    #region Actions - Answering

    internal override CredentialSaveVerdict Answer(ZeeApp app) {
        return new(new CredentialPendingCandidate(Origin, SubmittedAt).SaveValidity(TopLevelOrigin, Now));
    }

    #endregion
}
