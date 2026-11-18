using ZeeCore.Application;

namespace ZeeCore.Contracts;

/// Removes the filter list the person added as `Id`, and its copy.
public sealed record RemoveCustomFilterList(Guid Id) : Intent {
    #region Actions - Content blocking

    internal override IReadOnlyList<Change> Route(ZeeApp app) => app.ChangeFilters(() => {
        if (!app.Device.RemoveCustomFilterList(Id)) return false;
        app.Filters.SubscriptionsChanged();
        return true;
    });

    #endregion
}
