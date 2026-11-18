namespace ZeeCore.Contracts;

/// How many of each thing the core keeps: folders in a Space and how deep
/// they nest, history entries per Space, members of a split, colors in a
/// Space's branding and its badge palette, Spaces in a workspace, tabs in a
/// Space, records in the sync journal, and bytes in a password file an
/// import reads.
public sealed record CapacityLimits(
    int Folders,
    int FolderDepth,
    int HistoryEntries,
    int SplitMembers,
    int BrandColors,
    int BadgePalette,
    int Spaces,
    int TabsPerSpace,
    int SyncRecords,
    int CredentialFileBytes);
