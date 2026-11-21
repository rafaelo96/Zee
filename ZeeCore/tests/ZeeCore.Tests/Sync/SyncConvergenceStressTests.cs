using System.Text.Json.Nodes;

using ZeeCore.Application;
using ZeeCore.Contracts;

using Xunit;

namespace ZeeCore.Tests;

/// Two devices that edit on their own and then exchange their records, in
/// either order, end with the same browser: a Space made empty on one appears
/// on the other, a burst of tabs on both keeps every tab once and in one order,
/// the same tab or folder edited on both settles on one value, and a Space
/// deleted on one never comes back from edits the other made to it.
public sealed partial class BrowserContractsTests {
    #region Types

    /// A device of the stress tests: its journal and the session it shows.
    private sealed class StressDevice(Guid id) {
        public JournalUnderTest Journal { get; } = new(id);
        public JsonObject Session { get; set; } = SessionOf();

        /// Stages the session the device shows, as an edit `at` seconds after 1970.
        public void Stage(double at) => Journal.Stage(Session, at: at);

        /// Takes what `other` holds, as the cloud would bring it, and shows
        /// what the records make of the session.
        public void Take(StressDevice other) {
            Journal.Merge(other.Journal.Records);
            Session = Journal.Materialize(Session);
        }
    }

    #endregion

    #region Actions - Helpers

    /// Two devices that both show `base`, the first having staged it and the
    /// second having taken it from the cloud.
    private static (StressDevice First, StressDevice Second) StressDevices(JsonObject @base) {
        var first = new StressDevice(Fixed(9_001)) { Session = @base };
        first.Stage(at: 100);
        var second = new StressDevice(Fixed(9_002));
        second.Take(first);
        return (first, second);
    }

    /// What a person sees of `session`: each Space's identity and name, and its
    /// web tabs' identities and titles in order.
    private static string Seen(JsonObject session) => string.Join("\n", session["spaces"]!.AsArray().Select(space => {
        var tabs = space!["tabs"]!.AsArray().Where(tab => tab!["url"] is not null)
            .Select(tab => $"{SyncJson.Identity(tab!["id"])}={tab!["title"]!.GetValue<string>()}");
        var folders = (space["folders"] as JsonArray ?? []).Select(folder => folder!["title"]!.GetValue<string>());
        return $"{SyncJson.Identity(space["id"])}:{space["name"]!.GetValue<string>()}|{string.Join(",", folders)}|{string.Join(",", tabs)}";
    }).OrderBy(line => line, StringComparer.Ordinal));

    /// Lets each device take the other's records, the first device first when
    /// `firstLeads`, and asserts both then show the same.
    private static void Converge(StressDevice first, StressDevice second, bool firstLeads) {
        if (firstLeads) {
            second.Take(first);
            first.Take(second);
        } else {
            first.Take(second);
            second.Take(first);
        }
        Assert.Equal(Seen(first.Session), Seen(second.Session));
    }

    private static JsonArray TabsIn(JsonObject session, Guid space) => SpaceIn(session, space)!["tabs"]!.AsArray();

    #endregion

    #region Actions - Tests

    [Theory]
    [InlineData(true)]
    [InlineData(false)]
    public void ASpaceMadeEmptyOnOneDeviceAppearsAndStaysOnTheOther(bool firstLeads) {
        var (first, second) = StressDevices(OneSpaceSession());
        var empty = Fixed(9_100);
        first.Session["spaces"]!.AsArray().Add(SpaceOf(empty, Fixed(9_101), "Empty"));
        first.Stage(at: 200);

        Converge(first, second, firstLeads);

        Assert.NotNull(SpaceIn(second.Session, empty));
        // The Space the second device shows syncs back without removing it.
        second.Stage(at: 300);
        Converge(first, second, firstLeads);
        Assert.Equal("Empty", SpaceIn(first.Session, empty)!["name"]!.GetValue<string>());
    }

    [Theory]
    [InlineData(true)]
    [InlineData(false)]
    public void ABurstOfTabsOnBothDevicesKeepsEveryTabOnceInOneOrder(bool firstLeads) {
        var (first, second) = StressDevices(OneSpaceSession());
        var space = Fixed(100);
        const int burst = 150;
        for (int index = 0; index < burst; index++) {
            TabsIn(first.Session, space).Add(TabOf(Fixed(20_000 + index), $"First {index}", $"https://first.example/{index}",
                activated: 200 + index));
            TabsIn(second.Session, space).Add(TabOf(Fixed(30_000 + index), $"Second {index}", $"https://second.example/{index}",
                activated: 200 + index));
            // Each device stages as edits pause, several times through the burst.
            if (index % 25 == 24) {
                first.Stage(at: 200 + index);
                second.Stage(at: 200 + index);
            }
        }

        Converge(first, second, firstLeads);

        var ids = TabsIn(first.Session, space).Select(tab => SyncJson.Identity(tab!["id"])).ToArray();
        Assert.Equal(ids.Length, ids.Distinct().Count());
        Assert.Equal((2 * burst) + 1, ids.Length);
    }

    [Theory]
    [InlineData(true)]
    [InlineData(false)]
    public void TheSameTabAndFolderEditedOnBothDevicesSettleOnOneValue(bool firstLeads) {
        var folder = Fixed(9_200);
        var @base = SessionOf(SpaceOf(Fixed(100), Fixed(101), tabs: [TabOf(Fixed(102))],
            folders: [FolderOf(folder, "Reading")]));
        var (first, second) = StressDevices(@base);
        var space = Fixed(100);
        TabsIn(first.Session, space)[0]!["title"] = "Renamed on the first";
        SpaceIn(first.Session, space)!["folders"]![0]!["title"] = "First's folder";
        TabsIn(second.Session, space)[0]!["title"] = "Renamed on the second";
        SpaceIn(second.Session, space)!["folders"]![0]!["title"] = "Second's folder";
        first.Stage(at: 200);
        second.Stage(at: 210);

        Converge(first, second, firstLeads);

        var title = TabsIn(first.Session, space)[0]!["title"]!.GetValue<string>();
        Assert.Contains(title, new[] { "Renamed on the first", "Renamed on the second" });
    }

    [Theory]
    [InlineData(true)]
    [InlineData(false)]
    public void ASpaceDeletedOnOneDeviceNeverComesBackFromEditsOnTheOther(bool firstLeads) {
        var kept = Fixed(9_300);
        var deleted = Fixed(9_310);
        var @base = SessionOf(SpaceOf(kept, Fixed(9_301), "Kept", tabs: [TabOf(Fixed(9_302))]),
            SpaceOf(deleted, Fixed(9_311), "Doomed", tabs: [TabOf(Fixed(9_312))]));
        var (first, second) = StressDevices(@base);
        first.Session["spaces"]!.AsArray().RemoveAt(first.Session["spaces"]!.AsArray()
            .ToList().FindIndex(space => SyncJson.Identity(space!["id"]) == deleted));
        first.Stage(at: 200);
        SpaceIn(second.Session, deleted)!["name"] = "Renamed meanwhile";
        TabsIn(second.Session, deleted).Add(TabOf(Fixed(9_313), "Added meanwhile", "https://late.example/", activated: 220));
        second.Stage(at: 220);

        Converge(first, second, firstLeads);

        Assert.Null(SpaceIn(first.Session, deleted));
        Assert.NotNull(SpaceIn(first.Session, kept));
    }

    #endregion
}
