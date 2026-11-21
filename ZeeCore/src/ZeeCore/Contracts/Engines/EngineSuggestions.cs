using ZeeCore.Application;

namespace ZeeCore.Contracts;

#region Types

/// The engine Zee suggests for the site a page shows, and why, or neither.
public sealed record EngineSuggestion(EngineKind? Engine, EngineSuggestionReason? Reason, SiteOrigin? Origin);

#endregion

/// Why Zee suggests another engine for a site: it is one known to need
/// Chromium, or its page kept stopping in the engine it runs on.
public sealed class EngineSuggestionReason {
    #region Static Variables

    public static readonly EngineSuggestionReason KnownSite = new(name: "knownSite", message: "This site works better in Chromium.");
    public static readonly EngineSuggestionReason Unstable = new(name: "unstable", message: "This site keeps stopping in WebKit.");

    public static IReadOnlyList<EngineSuggestionReason> All { get; } = [KnownSite, Unstable];

    #endregion

    #region Variables

    public string Name { get; }

    /// What the page's bar says.
    [Localized]
    public string Message { get; }

    public string MessageComment { get; } = "A bar over a web page suggesting it open in another browser engine.";

    #endregion

    #region Constructors

    private EngineSuggestionReason(string name, string message) {
        Name = name;
        Message = message;
    }

    #endregion
}

/// Whether Zee suggests Chromium for the site page `PageId` shows: while the
/// page runs in WebKit on a device that registered Chromium, for a site no
/// choice of the person decides and whose suggestion they did not dismiss,
/// when the site is one known to need Chromium or the page stopped since it
/// last loaded what the person asked for.
public sealed record SuggestedEngine(Guid PageId) : Query<EngineSuggestion> {
    #region Actions - Answering

    internal override EngineSuggestion Answer(ZeeApp app) {
        var none = new EngineSuggestion(null, null, null);
        if (app.Pages.Hosted(PageId) is not { } page || page.Engine.Kind != EngineKind.WebKit
            || app.Engines.Registered(EngineKind.Chromium) is null || page.DocumentAddress is not { } address
            || new WebAddress(address).Origin is not { } origin || app.Device.ChosenEngine(page.SpaceId, origin) is not null
            || app.Device.DismissedEngineSuggestion(origin))
            return none;
        var reason = ChromiumPreferredSite.Serving(origin) is not null ? EngineSuggestionReason.KnownSite
            : page.StoppedSinceLoad ? EngineSuggestionReason.Unstable : null;
        return reason is null ? none : new(EngineKind.Chromium, reason, origin);
    }

    #endregion
}

/// The person dismissed the suggestion of another engine for `Origin`, which
/// Zee keeps quiet about until it quits.
public sealed record DismissEngineSuggestion(SiteOrigin Origin) : Intent {
    #region Actions - Device

    internal override IReadOnlyList<Change> Route(ZeeApp app) => app.Turn(_ => app.Device.DismissEngineSuggestion(Origin));

    #endregion
}
