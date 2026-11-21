using ZeeCore.Application;
using ZeeCore.Contracts;

using Xunit;

namespace ZeeCore.Tests;

/// A site's zoom on this device: remembered by host, whatever its letter
/// case, until forgotten; a zoom no page takes changes nothing; the least
/// recently chosen go past the most a device keeps; and the device store keeps
/// them across launches.
public sealed partial class BrowserContractsTests {
    [Fact]
    public void ASiteKeepsItsZoomOnTheDeviceUntilForgotten() {
        using var directory = new StorageDirectory();
        var configuration = new AppConfiguration(directory.Path, DevicePlatform.Desktop);
        using (var app = new ZeeApp(configuration)) {
            Assert.Null(app.Query(new SiteZoomFor("news.example")).Zoom);
            app.Send(new RememberSiteZoom("News.Example.", 1.5));
            app.Send(new RememberSiteZoom("docs.example", 0.8));
            Assert.Equal(1.5, app.Query(new SiteZoomFor("news.example")).Zoom);
            Assert.Null(app.Query(new SiteZoomFor("example")).Zoom);

            app.Send(new RememberSiteZoom("news.example", 9));
            app.Send(new RememberSiteZoom("news.example", double.NaN));
            app.Send(new RememberSiteZoom("  ", 1.2));
            Assert.Equal(1.5, app.Query(new SiteZoomFor("news.example")).Zoom);

            app.Send(new RememberSiteZoom("docs.example", null));
            Assert.Null(app.Query(new SiteZoomFor("docs.example")).Zoom);
        }
        using (var reopened = new ZeeApp(configuration)) {
            Assert.Equal(1.5, reopened.Query(new SiteZoomFor("NEWS.example")).Zoom);
            for (int index = 0; index < Device.MaximumSiteZooms; index++)
                reopened.Send(new RememberSiteZoom($"site{index}.example", 1.25));
            Assert.Null(reopened.Query(new SiteZoomFor("news.example")).Zoom);
            Assert.Equal(1.25, reopened.Query(new SiteZoomFor($"site{Device.MaximumSiteZooms - 1}.example")).Zoom);
        }
    }
}
