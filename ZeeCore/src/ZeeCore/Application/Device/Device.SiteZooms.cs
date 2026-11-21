using ZeeCore.Contracts;

namespace ZeeCore.Application;

/// The zoom each site keeps on this device, the most recently chosen last,
/// which the device store keeps and never syncs. Past `MaximumSiteZooms`, the
/// least recently chosen goes.
internal sealed partial class Device {
    #region Static Variables

    public const int MaximumSiteZooms = 1_000;

    #endregion

    #region Variables

    private readonly List<(string Host, double Zoom)> siteZooms = [];

    #endregion

    #region Actions - Site zoom

    /// The zoom pages at `host` start at, or null while the site follows the
    /// default.
    public double? SiteZoom(string? host) {
        if (Contracts.RememberSiteZoom.Site(host) is not { } site) return null;
        lock (gate) {
            int index = siteZooms.FindLastIndex(entry => entry.Host == site);
            return index < 0 ? null : siteZooms[index].Zoom;
        }
    }

    /// Remembers `zoom` for `host`, or forgets the host's zoom when null.
    public void RememberSiteZoom(string? host, double? zoom) {
        if (Contracts.RememberSiteZoom.Site(host) is not { } site) return;
        if (zoom is { } chosen && (!double.IsFinite(chosen) || chosen < Contracts.RememberSiteZoom.MinimumZoom
            || chosen > Contracts.RememberSiteZoom.MaximumZoom)) return;
        lock (gate) {
            int removed = siteZooms.RemoveAll(entry => entry.Host == site);
            if (zoom is { } kept) {
                siteZooms.Add((site, kept));
                if (siteZooms.Count > MaximumSiteZooms) siteZooms.RemoveRange(0, siteZooms.Count - MaximumSiteZooms);
            } else if (removed == 0) {
                return;
            }
            storage?.EnqueueDevice(Records());
        }
    }

    #endregion
}
