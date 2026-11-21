using ZeeCore.Application;

namespace ZeeCore.Contracts;

/// The browsers the platform found installed, in the order it lists them,
/// which is the order setup imports from them. The first time setup offers
/// any, with none chosen, it chooses those a person leaving them most likely
/// came to bring, such as Arc.
public sealed record OfferImportSources(IReadOnlyList<ImportSource> Installed) : SetupFlowIntent {
    #region Actions - Device

    internal override void Apply(Device device, DeviceTurn turn) => device.ReviseFlow(turn.Changes, (flow, _) => flow with {
        Offered = Installed,
        Selected = flow.Offered.Count == 0 && flow.Selected.Count == 0
            ? [.. Installed.Where(source => source.IsChosenFirst)]
            : [.. Installed.Where(flow.Selected.Contains)]
    });

    #endregion
}
