using ZeeCore.Contracts;

namespace ZeeCore.Application;

/// A web app that works fully only in Chromium: it relies on what WebKit
/// lacks, such as Chrome's extension store, Chromium-only file and device
/// APIs, or calls that refuse other browsers. Zee suggests Chromium for these
/// sites while a page shows one in WebKit, and never moves a page on its own.
internal sealed class ChromiumPreferredSite {
    #region Variables

    public static readonly ChromiumPreferredSite ChromeWebStore = new("chromewebstore.google.com", "chrome.google.com");
    public static readonly ChromiumPreferredSite MicrosoftTeams = new("teams.microsoft.com", "teams.live.com");
    public static readonly ChromiumPreferredSite VisualStudioCodeWeb = new("vscode.dev", "insiders.vscode.dev", "github.dev");
    public static readonly ChromiumPreferredSite SlackHuddles = new("app.slack.com");

    public static IReadOnlyList<ChromiumPreferredSite> All { get; } = [ChromeWebStore, MicrosoftTeams, VisualStudioCodeWeb, SlackHuddles];

    /// The secure origins the app loads from.
    private readonly IReadOnlyList<SiteOrigin> origins;

    #endregion

    #region Constructors

    private ChromiumPreferredSite(params string[] hosts) => origins = [.. hosts.Select(host => new SiteOrigin("https", host, -1))];

    #endregion

    #region Actions - Lookup

    /// The app `origin` belongs to, or null for any other site.
    public static ChromiumPreferredSite? Serving(SiteOrigin origin) => All.FirstOrDefault(site => site.origins.Contains(origin));

    #endregion
}
