using ZeeCore.Application;

namespace ZeeCore.Contracts;

/// The content rule lists a page that blocks applies now. Before any filter
/// list arrives they hold Zee's own baseline rules; `ContentRuleListsChanged`
/// names the next ones.
public sealed record ContentRuleLists : Query<ContentRuleListSet> {
    #region Actions - Answering

    internal override ContentRuleListSet Answer(ZeeApp app) => app.Filters.Rules();

    #endregion
}
