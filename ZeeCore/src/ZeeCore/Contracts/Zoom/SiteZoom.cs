using System.Globalization;

using ZeeCore.Application;

namespace ZeeCore.Contracts;

#region Types

/// The zoom a site keeps on this device, or null for one that follows the
/// person's default.
public sealed record SiteZoom(double? Zoom);

#endregion

/// The zoom the person last chose for pages at `Host` on this device, which
/// every page of that host starts at, in any Space. Null while the site
/// follows the default.
public sealed record SiteZoomFor(string? Host) : Query<SiteZoom> {
    #region Actions - Answering

    internal override SiteZoom Answer(ZeeApp app) => new(app.Device.SiteZoom(Host));

    #endregion
}

/// Remembers `Zoom` for pages at `Host` on this device, or forgets the site's
/// zoom when null, so it follows the default again. A host Zee cannot name or
/// a zoom outside what a page takes leaves the device as it was.
public sealed record RememberSiteZoom(string? Host, double? Zoom) : Intent {
    #region Static Variables

    public const double MinimumZoom = 0.25;
    public const double MaximumZoom = 5;
    /// The longest host a site zoom names.
    public const int MaximumHostLength = 253;

    #endregion

    #region Actions - Routing

    internal override IReadOnlyList<Change> Route(ZeeApp app) => app.Turn(_ => app.Device.RememberSiteZoom(Host, Zoom));

    #endregion

    #region Actions - Hosts

    /// The site a host names as a zoom keeps it: lowercased, without a
    /// trailing dot. Null for none.
    internal static string? Site(string? host) {
        string? name = host?.Trim().TrimEnd('.').ToLower(CultureInfo.InvariantCulture);
        return name is { Length: > 0 and <= MaximumHostLength } && !name.Any(char.IsWhiteSpace) ? name : null;
    }

    #endregion
}
