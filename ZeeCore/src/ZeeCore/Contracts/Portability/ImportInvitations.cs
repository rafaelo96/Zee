using ZeeCore.Application;

namespace ZeeCore.Contracts;

/// The browser Zee invites the person to bring their data from, or null for
/// none, and when it stops working, for one its makers are shutting down.
public sealed record ImportInvitation(ImportSource? Source, DateTimeOffset? StopsWorkingAt);

/// The invitation among the browsers whose data the platform found on this
/// device, `Found`: one setup chooses first, such as Arc, once setup is done
/// and until the person settles it.
public sealed record GetImportInvitation(IReadOnlyList<ImportSource> Found) : Query<ImportInvitation> {
    #region Actions - Answering

    internal override ImportInvitation Answer(ZeeApp app) =>
        app.Device.ImportInvitation(Found) is { } source ? new(source, source.StopsWorkingAt) : new(null, null);

    #endregion
}

/// The person imported from `Source` or dismissed the invitation to, so Zee
/// never invites them again on this device.
public sealed record SettleImportInvitation(ImportSource Source) : Intent {
    #region Actions - Routing

    internal override IReadOnlyList<Change> Route(ZeeApp app) => app.Turn(_ => app.Device.SettleImportInvitation(Source));

    #endregion
}
