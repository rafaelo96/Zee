using ZeeCore.Application;

namespace ZeeCore.Contracts;

/// Adds or edits a persistent website engine rule. PreviousOrigin identifies
/// the rule being edited when its website changes.
public sealed record EditEngineRule(SiteOrigin? PreviousOrigin, SiteOrigin Origin, EngineKind Engine) : Intent {
    #region Actions - Device

    internal override IReadOnlyList<Change> Route(ZeeApp app) => app.Turn(changes => {
        if (app.Engines.Registered(Engine) is null) throw new Rejected(new UnregisteredEngine(Engine));
        app.Device.EditEngineRule(PreviousOrigin, Origin, Engine, changes);
    });

    #endregion
}
