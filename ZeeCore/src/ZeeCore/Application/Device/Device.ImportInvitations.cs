using ZeeCore.Contracts;

namespace ZeeCore.Application;

/// The browsers this device invited the person to bring their data from,
/// once setup was done, which the person settled by importing or dismissing
/// the invitation. The device store keeps them and never syncs them.
internal sealed partial class Device {
    #region Variables

    private readonly HashSet<ImportSource> settledInvitations = [];

    #endregion

    #region Actions - Import invitations

    /// The browser among `found`, whose data the platform found on this
    /// device, that Zee invites the person to bring: one setup chooses first,
    /// once setup is done, until the person settles it. Null for none.
    public ImportSource? ImportInvitation(IReadOnlyList<ImportSource> found) {
        ArgumentNullException.ThrowIfNull(found);
        lock (gate)
            return setupCompleted ? found.FirstOrDefault(source => source.IsChosenFirst && !settledInvitations.Contains(source)) : null;
    }

    /// Never invites the person to bring `source` again.
    public void SettleImportInvitation(ImportSource source) {
        ArgumentNullException.ThrowIfNull(source);
        lock (gate) {
            if (settledInvitations.Add(source)) storage?.EnqueueDevice(Records());
        }
    }

    #endregion
}
