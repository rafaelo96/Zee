using ZeeCore.Application;
using ZeeCore.Domain;

namespace ZeeCore.Contracts;

/// Removes a route. Refused with `UnknownLinkRoute`.
public sealed record RemoveLinkRoute(Guid RouteId) : LinkIntent {
    #region Actions - Device

    internal override void Apply(Device device, DeviceTurn turn) =>
        device.ReviseLinks(turn.Changes, links => links.Removing(this));

    #endregion
}
