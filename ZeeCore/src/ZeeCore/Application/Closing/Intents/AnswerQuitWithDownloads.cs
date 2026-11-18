using ZeeCore.Application;

namespace ZeeCore.Contracts;

/// Whether the person quits and stops the downloads in progress.
public sealed record AnswerQuitWithDownloads(Guid PromptId, bool Quits) : PromptIntent(PromptId) {
    #region Actions - Closing

    internal override void Apply(ZeeApp app, ChangeFeed changes) {
        if (app.ClosePreparations.QuitPromptId != PromptId) throw new Rejected(new UnknownPrompt(PromptId));
        app.ClosePreparations.Finish(Quits, changes);
    }

    #endregion
}
