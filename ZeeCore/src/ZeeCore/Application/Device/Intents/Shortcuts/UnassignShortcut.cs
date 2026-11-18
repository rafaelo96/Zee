using ZeeCore.Application;
using ZeeCore.Domain;

namespace ZeeCore.Contracts;

/// Leaves `Command` without a chord.
public sealed record UnassignShortcut(ShortcutCommand Command) : ShortcutIntent {
    #region Actions - Device

    internal override void Apply(Device device, ShortcutTurn turn) =>
        device.ReviseShortcuts(turn, shortcuts => shortcuts.Unassigning(Command, device.Platform));

    #endregion
}
