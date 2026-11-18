using ZeeCore.Application;

namespace ZeeCore.Contracts;

/// This device's agent preferences.
public sealed record GetAgentPreferences : Query<AgentPreferences> {
    #region Actions - Answering

    internal override AgentPreferences Answer(ZeeApp app) => app.Device.Agents;

    #endregion
}
