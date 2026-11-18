using ZeeCore.Application;
using ZeeCore.Domain;

namespace ZeeCore.Contracts;

/// Forgets every shortcut choice, including those for commands this device
/// does not offer.
public sealed record ResetShortcuts() : ShortcutIntent {
    #region Actions - Device

    internal override void Apply(Device device, ShortcutTurn turn) =>
        device.ReviseShortcuts(turn, _ => ShortcutOverrides.None);

    #endregion
}
