using System.Text;

using Xunit;

using ZeeCore.Application;
using ZeeCore.Contracts;

namespace ZeeCore.Tests;

/// Importing from Crest, the browser Zee forked from: its session file is
/// Zee's own layout, so every Space comes over whole with new identities.
public sealed partial class BrowserContractsTests {
    /// A Crest session file holding `device`'s Spaces, each with an empty
    /// history, at a new path in the temporary folder.
    private static string CrestSessionFile(TestDevice device) {
        string folder = Path.Combine(Path.GetTempPath(), "zee-crest-test-" + Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(folder);
        string path = Path.Combine(folder, CrestSession.FileName);
        using var connection = SqliteConnection.Open(path, Sqlite.OpenReadWrite | Sqlite.OpenCreate);
        connection.Execute("CREATE TABLE checkpoint (part TEXT PRIMARY KEY, data BLOB NOT NULL)");
        var session = device.Authority.Current;
        connection.Write(StoragePart.Core.Name, Encoding.UTF8.GetBytes(StoredSessionCodec.Encode(session).ToJsonString()));
        foreach (var space in session.Spaces) connection.Write(StoragePart.History(space.Id).Name, "[]"u8.ToArray());
        connection.Write(StoragePart.Journal.Name, """{"schemaVersion":99}"""u8.ToArray());
        return path;
    }

    [Fact]
    public void CrestBringsEverySpaceWholeWithNewIdentities() {
        using var device = new TestDevice(TwoSpaceSession(out var first, out var second));
        var boost = Guid.NewGuid();
        device.Send(new SaveBoost(device.Workspace, first, SampleBoost(boost)));
        var original = device.Authority.Current;
        string path = CrestSessionFile(device);

        using var app = Importer();
        var spaces = app.Query(new ReadImport(ImportSource.Crest, [new("crest", "Crest", null, path)])).Spaces;

        Assert.Equal(original.Spaces.Select(space => space.Settings.Name), spaces.Select(space => space.Settings.Name));
        Assert.DoesNotContain(spaces, space => space.Id == first || space.Id == second);
        var source = original.Space(first)!;
        Assert.Equal(source.Tabs.Where(tab => tab.Url is not null).Select(tab => (tab.Title, tab.Url, tab.Placement)),
            spaces[0].Tabs.Where(tab => tab.Url is not null).Select(tab => (tab.Title, tab.Url, tab.Placement)));
        Assert.DoesNotContain(spaces[0].Tabs, tab => source.Tabs.Any(kept => kept.Id == tab.Id));
        var brought = Assert.Single(spaces[0].Settings.ShownBoosts);
        Assert.Equal((source.Settings.ShownBoosts[0].Domain, source.Settings.ShownBoosts[0].Css),
            (brought.Domain, brought.Css));
        Assert.NotEqual(boost, brought.Id);
    }

    [Fact]
    public void ACrestFileThatHoldsNoSessionIsRefused() {
        string folder = Path.Combine(Path.GetTempPath(), "zee-crest-test-" + Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(folder);
        string path = Path.Combine(folder, CrestSession.FileName);
        File.WriteAllText(path, "not a session");

        using var app = Importer();
        var refused = Assert.Throws<Rejected>(() => app.Query(new ReadImport(ImportSource.Crest, [new("crest", "Crest", null, path)])));
        Assert.IsType<SessionUnrecognized>(refused.Rejection);
    }

    /// Setup offers Crest by name, never again as an unlisted Chromium browser
    /// for the engine data it keeps beside its own session.
    [Fact]
    public void AListedBrowsersChromiumDataIsNotOfferedAgainAsUnlisted() {
        string home = Path.Combine(Path.GetTempPath(), "zee-crest-home-" + Guid.NewGuid().ToString("N"));
        foreach (string name in new[] { "Crest/Chromium", "Other/Data" }) {
            string data = Path.Combine(home, "Library", "Application Support", name);
            Directory.CreateDirectory(Path.Combine(data, "Default"));
            File.WriteAllText(Path.Combine(data, "Local State"), "{}");
            File.WriteAllText(Path.Combine(data, "Default", "Preferences"), "{}");
            File.WriteAllText(Path.Combine(data, "Default", "Bookmarks"), "{}");
        }

        var found = InstalledBrowser.FindUnlisted(home,
            [new(ImportSource.Crest.BundleIdentifier, "Crest"), new("com.example.other", "Other")]);

        Assert.Equal(["com.example.other"], found.Select(browser => browser.BundleIdentifier));
    }
}
