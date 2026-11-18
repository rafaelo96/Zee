using ZeeCore.Application;

namespace ZeeCore.Contracts;

/// The person answered a script dialog: whether they accepted it, and the text
/// a prompt dialog took.
public sealed record AnswerScriptDialog(Guid PromptId, bool Accepted, string? Text) : PromptIntent(PromptId) {
    #region Actions - Prompts

    internal override void Apply(ZeeApp app, ChangeFeed changes) =>
        app.Prompts.Answer<ScriptDialogQuestion>(PromptId, new SettleScriptDialog(PromptId, Accepted, Text), changes, app.Issue);

    #endregion
}
