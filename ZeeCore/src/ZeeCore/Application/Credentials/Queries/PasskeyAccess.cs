using ZeeCore.Application;

namespace ZeeCore.Contracts;

/// Whether websites in Zee can use the system's passkey providers, from the
/// platform's build, device and authorization facts.
public sealed record PasskeyAccess(bool HasManagedCapability, PasskeyDeviceConfiguration DeviceConfiguration,
    PasskeyAuthorizationState AuthorizationState) : Query<PasskeyAccessVerdict> {
    #region Variables

    /// The managed capability comes first, then device setup, then consent.
    internal PasskeyAccessStatus Status {
        get {
            ArgumentNullException.ThrowIfNull(DeviceConfiguration);
            ArgumentNullException.ThrowIfNull(AuthorizationState);
            if (!HasManagedCapability) return PasskeyAccessStatus.ManagedCapabilityRequired;
            if (DeviceConfiguration.RulesOutPasskeys) return PasskeyAccessStatus.DeviceNotConfigured;
            return AuthorizationState.AccessStatus;
        }
    }

    #endregion

    #region Actions - Answering

    internal override PasskeyAccessVerdict Answer(ZeeApp app) {
        return new(Status);
    }

    #endregion
}
