using ZeeCore.Application;
using ZeeCore.Domain;

namespace ZeeCore.Contracts;

/// The capacities the core enforces. Native surfaces read them to shape what
/// they offer, such as a pin action or a nested folder; the core still refuses
/// anything past them.
public sealed record EnforcedLimits() : StandaloneQuery<CapacityLimits> {
    #region Actions - Answering

    internal override CapacityLimits Answer(StandaloneContext context) => new(FolderTree.MaximumCount, FolderTree.MaximumDepth,
        HistoryEntryState.MaximumEntries, BrowserTabCollection.MaximumSplitMembers, SpaceBranding.MaximumColorCount,
        SpaceBranding.MaximumBadgePaletteCount, SessionState.MaximumSpaces, BrowserTabCollection.MaximumTabs, NativeSyncJournal.MaximumRecords,
        CredentialFile.MaximumBytes);

    #endregion
}
