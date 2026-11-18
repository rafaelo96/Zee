using ZeeCore.Application;

namespace ZeeCore.Contracts;

/// Every filter list as the settings show it, and the person's own filters.
public sealed record GetFilterLists : Query<FilterLists> {
    #region Actions - Answering

    internal override FilterLists Answer(ZeeApp app) => app.Filters.States();

    #endregion
}
