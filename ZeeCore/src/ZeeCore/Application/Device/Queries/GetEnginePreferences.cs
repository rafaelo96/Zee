using ZeeCore.Application;

namespace ZeeCore.Contracts;

/// Persistent engine preferences, including a choice unavailable in this
/// composition. Private engine choices never enter this answer.
public sealed record GetEnginePreferences : Query<EnginePreferences> {
    #region Actions - Answering

    internal override EnginePreferences Answer(ZeeApp app) => app.Device.EnginePreferences;

    #endregion
}
