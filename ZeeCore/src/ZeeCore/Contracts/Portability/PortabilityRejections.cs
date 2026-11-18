namespace ZeeCore.Contracts;

#region Archives

/// The Zee browser-data file holds something Zee would not keep. Nothing was imported.
public sealed record ArchiveInvalid : Rejection {
    #region Variables

    /// What the person is told.
    [Localized]
    public string Message => "This file does not contain valid Zee browser data.";

    #endregion
}

/// The Zee browser-data file is larger than an import reads. Nothing was imported.
public sealed record ArchiveTooLarge : Rejection {
    #region Variables

    /// What the person is told.
    [Localized]
    public string Message => "This file is larger than Zee’s 50 MB import limit.";

    #endregion
}

/// The file is not Zee browser data. Nothing was imported.
public sealed record NotAnArchive : Rejection {
    #region Variables

    /// What the person is told.
    [Localized]
    public string Message => "This is not a Zee browser-data file.";

    #endregion
}

/// The Zee browser-data file is of `Version`, a format this build cannot read.
public sealed record UnsupportedArchiveVersion(int Version) : Rejection {
    #region Variables

    /// What the person is told.
    [Localized(Argument = nameof(Version))]
    public string Message => "This Zee browser-data version (%lld) is not supported.";

    #endregion
}

#endregion

#region Bookmarks

/// The browser's bookmarks hold no web page Zee can open. Nothing was imported.
public sealed record BookmarksHaveNoLinks : Rejection {
    #region Variables

    /// What the person is told.
    [Localized]
    public string Message => "This file does not contain any HTTP or HTTPS bookmarks Zee can import.";

    #endregion
}

/// The browser's bookmarks hold more folders, nesting, tabs or Spaces than Zee keeps. Nothing was imported.
public sealed record BookmarksOverLimits : Rejection {
    #region Variables

    /// What the person is told.
    [Localized]
    public string Message => "This bookmark file exceeds Zee’s folder, depth, tab, or Space limits.";

    #endregion
}

/// The browser's bookmark file is larger than an import reads. Nothing was imported.
public sealed record BookmarksTooLarge : Rejection {
    #region Variables

    /// What the person is told.
    [Localized]
    public string Message => "This bookmark file is larger than Zee’s 50 MB import limit.";

    #endregion
}

/// The browser's bookmark file holds nothing Zee recognizes as bookmarks. Nothing was imported.
public sealed record BookmarksUnrecognized : Rejection {
    #region Variables

    /// What the person is told.
    [Localized]
    public string Message => "Zee could not recognize this browser’s bookmark data.";

    #endregion
}

#endregion

#region Files

/// The file could not be read. Nothing was imported.
public sealed record FileUnreadable : Rejection {
    #region Variables

    /// What the person is told.
    [Localized]
    public string Message => "Zee could not read this file.";

    #endregion
}

#endregion

#region Sessions

/// The Chromium session is encrypted with its profile's key, which only that browser holds. Nothing was imported.
public sealed record SessionEncrypted : Rejection {
    #region Variables

    /// What the person is told.
    [Localized]
    public string Message => "This Chromium session is profile-encrypted and cannot be safely imported outside its source browser.";

    #endregion
}

/// The browser's session holds no web page Zee can open. Nothing was imported.
public sealed record SessionHasNoTabs : Rejection {
    #region Variables

    /// What the person is told.
    [Localized]
    public string Message => "This session has no HTTP or HTTPS tabs Zee can import.";

    #endregion
}

/// The browser's session holds more Spaces, tabs, folders or text than a Space keeps. Nothing was imported.
public sealed record SessionOverLimits : Rejection {
    #region Variables

    /// What the person is told.
    [Localized]
    public string Message => "This session exceeds Zee’s Space, tab, folder, or text limits.";

    #endregion
}

/// The browser's session file is larger than an import reads. Nothing was imported.
public sealed record SessionTooLarge : Rejection {
    #region Variables

    /// What the person is told.
    [Localized]
    public string Message => "This session file is larger than Zee’s 512 MB import limit.";

    #endregion
}

/// The browser's session file holds nothing Zee recognizes as its tabs. Nothing was imported.
public sealed record SessionUnrecognized : Rejection {
    #region Variables

    /// What the person is told.
    [Localized]
    public string Message => "Zee could not recognize this browser’s tab-session data.";

    #endregion
}

#endregion
