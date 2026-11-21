using ZeeCore.Application;

namespace ZeeCore.Contracts;

/// Opens new pages in WebKit while the system saves power, which uses less
/// of it, or stops. A site's or a Space's engine choice still decides first.
/// The device store keeps the choice; it never syncs.
public sealed record SetSavesBattery(bool Saves) : Intent {
    #region Actions - Device

    internal override IReadOnlyList<Change> Route(ZeeApp app) => app.Turn(changes => app.Device.SaveBattery(Saves, changes));

    #endregion
}

/// The system started or stopped saving power: Low Power Mode, or a battery
/// running low. The platform reports it as it launches and whenever it
/// changes; the core keeps it in memory alone.
public sealed record ReportPowerConstraint(bool Constrained) : Intent {
    #region Actions - Device

    internal override IReadOnlyList<Change> Route(ZeeApp app) => app.Turn(_ => app.Device.ConstrainPower(Constrained));

    #endregion
}
