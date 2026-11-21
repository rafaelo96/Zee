using System.Text;
using System.Text.Json.Nodes;

using ZeeCore.Application;
using ZeeCore.Contracts;

using Xunit;

namespace ZeeCore.Tests;

/// Boosts: which pages a Boost reaches, the stylesheet it gives them, what a
/// Space keeps of one, and that a Space's Boosts survive its file, its sync
/// record and a browser-data file.
public sealed partial class BrowserContractsTests {
    private static Boost SampleBoost(Guid id, string domain = "youtube.com", bool allSpaces = false) => new(id, domain, IsOn: true,
        allSpaces, new BoostLook(new BrandColor(0.1, 0.2, 0.3), null, new BrandColor(1, 0.5, 0), BoostFont.Serif, 1.25),
        "body { margin: 0 }", "document.title = 'Boosted'", ["#comments", ".ad"], DateTimeOffset.UnixEpoch);

    /// The saved session with a second Space, which holds nothing of its own.
    private static JsonNode TwoSpaceSession(out Guid first, out Guid second) {
        var session = SavedSession().Document["session"]!;
        var spaces = session["spaces"]!.AsArray();
        var other = spaces[0]!.DeepClone().AsObject();
        second = Guid.NewGuid();
        other["id"] = SwiftId(second);
        other["profile"] = new JsonObject { ["id"] = Guid.NewGuid().ToString().ToUpperInvariant() };
        other["name"] = "Other";
        foreach (string key in new[] { "tabs", "folders", "history", "archivedTabs", "splitGroups" }) other[key] = new JsonArray();
        other.Remove("selectedTabID");
        spaces.Add(other);
        first = SpaceId(spaces[0]!);
        return session;
    }

    [Fact]
    public void ABoostReachesItsSiteAndSubdomainsAndNothingThatOnlyLooksAlike() {
        var boost = SampleBoost(Guid.NewGuid());

        Assert.All(new[] { "youtube.com", "www.youtube.com", "m.youtube.com", "YouTube.com." }, host => Assert.True(boost.Matches(host)));
        Assert.All(new[] { "evil-youtube.com", "youtube.com.evil.example", "tube.com", "", null },
            host => Assert.False(boost.Matches(host)));
        Assert.Equal("youtube.com", Boost.Normalized("WWW.YouTube.com"));
        Assert.Null(Boost.Normalized("localhost"));
        Assert.Null(Boost.Normalized("exa mple.com"));
    }

    [Fact]
    public void ABoostsStylesheetPaintsItsLookHidesItsElementsAndLetsThePersonsOwnCssWin() {
        string sheet = SampleBoost(Guid.NewGuid()).Stylesheet();

        Assert.Contains("background-color: rgba(26, 51, 77, 1) !important", sheet, StringComparison.Ordinal);
        Assert.Contains("a, a * { color: rgba(255, 128, 0, 1) !important; }", sheet, StringComparison.Ordinal);
        Assert.Contains(BoostFont.Serif.Family!, sheet, StringComparison.Ordinal);
        Assert.Contains("zoom: 1.25", sheet, StringComparison.Ordinal);
        Assert.Contains("#comments,\n.ad { display: none !important; }", sheet, StringComparison.Ordinal);
        Assert.EndsWith("body { margin: 0 }\n", sheet, StringComparison.Ordinal);
        Assert.Equal("", (Boost.For(Guid.NewGuid(), "example.com", DateTimeOffset.UnixEpoch)!).Stylesheet());
    }

    [Fact]
    public void ASpaceKeepsOnlyABoostItCanMatchAndHoldsWithinItsLimits() {
        var boost = SampleBoost(Guid.NewGuid());

        var kept = (boost with { Domain = "www.Example.com", HiddenElements = [" .a ", ".a", "", ".b"] }).Validated();
        Assert.Equal("example.com", kept.Domain);
        Assert.Equal([".a", ".b"], kept.HiddenElements);
        Assert.Equal(BoostLook.MaximumTextScale, (boost with { Look = boost.Look with { TextScale = 9 } }).Validated().Look.TextScale);
        Assert.IsType<BoostDomainInvalid>(Assert.Throws<Rejected>(() => (boost with { Domain = "nodot" }).Validated()).Rejection);
        Assert.IsType<BoostTooLarge>(Assert.Throws<Rejected>(() =>
            (boost with { Script = new string('x', Boost.MaximumSourceBytes + 1) }).Validated()).Rejection);
        Assert.IsType<BoostTooLarge>(Assert.Throws<Rejected>(() =>
            (boost with { HiddenElements = ["a} body {display:none"] }).Validated()).Rejection);
    }

    /// A page runs the Boosts of its own Space that are on and match its site,
    /// and those made for every Space anywhere in the workspace; hiding an
    /// element makes the Space's Boost for the site, or adds to it.
    [Fact]
    public void APageRunsItsSpacesBoostsAndThoseMadeForEverySpace() {
        using var device = new TestDevice(TwoSpaceSession(out var first, out var second));
        var own = Guid.NewGuid(); var everywhere = Guid.NewGuid(); var off = Guid.NewGuid();
        device.Send(new SaveBoost(device.Workspace, first, SampleBoost(own)));
        device.Send(new SaveBoost(device.Workspace, second, SampleBoost(everywhere, "news.example", allSpaces: true)));
        device.Send(new SaveBoost(device.Workspace, second, SampleBoost(off, "youtube.com") with { IsOn = false }));

        Assert.Equal([own], device.Query(new BoostsFor(device.Workspace, first, "m.youtube.com")).Select(script => script.Id));
        Assert.Equal([everywhere], device.Query(new BoostsFor(device.Workspace, first, "news.example")).Select(script => script.Id));
        Assert.Empty(device.Query(new BoostsFor(device.Workspace, second, "youtube.com")));
        Assert.Empty(device.Query(new BoostsFor(device.Workspace, Guid.NewGuid(), "youtube.com")));

        var made = Guid.NewGuid();
        device.Send(new HideElementInBoost(device.Workspace, first, "www.example.org", "#banner", made));
        device.Send(new HideElementInBoost(device.Workspace, first, "example.org", ".popup", Guid.NewGuid()));
        var hidden = device.Authority.Current.Space(first)!.Settings.ShownBoosts.Single(boost => boost.Domain == "example.org");
        Assert.Equal(made, hidden.Id);
        Assert.Equal(["#banner", ".popup"], hidden.HiddenElements);

        device.Send(new DeleteBoost(device.Workspace, first, own));
        Assert.Empty(device.Query(new BoostsFor(device.Workspace, first, "youtube.com")));
        Assert.IsType<UnknownBoost>(Assert.Throws<Rejected>(() => device.Send(new DeleteBoost(device.Workspace, first, own))).Rejection);
    }

    /// A Space's Boosts come back from its stored form, ride its sync record
    /// in both forms with the time someone changed them, and leave in a
    /// browser-data file, coming back with new identities.
    [Fact]
    public void ASpacesBoostsSurviveItsFileItsSyncRecordAndAnExport() {
        using var device = new TestDevice(TwoSpaceSession(out var first, out _));
        var id = Guid.NewGuid();
        device.Send(new SaveBoost(device.Workspace, first, SampleBoost(id)));
        var space = device.Authority.Current.Space(first)!;
        var boost = Assert.Single(space.Settings.ShownBoosts);

        var stored = StoredSessionCodec.DecodeSpace(StoredSessionCodec.Encode(space));
        Assert.Equal(boost with { HiddenElements = [] }, stored.Settings.ShownBoosts.Single() with { HiddenElements = [] });
        Assert.Equal(boost.HiddenElements, stored.Settings.ShownBoosts.Single().HiddenElements);
        Assert.Equal(space.Settings.BoostsModifiedAt, stored.Settings.BoostsModifiedAt);

        var session = StoredSessionCodec.Encode(device.Authority.Current);
        var record = NativeSyncProjection.Project(session, SyncProjectionPreferences(), [])
            .Select(node => node!.AsObject()).First(node => node["type"]!.GetValue<string>() == "space"
                && SyncJson.Identity(node["value"]!["id"]) == first);
        var cloud = SyncRecordBody.Read(record, isTombstone: false, SyncPayloadForm.Journal).Write(SyncPayloadForm.Cloud);
        var synced = Assert.IsType<SpacePayload>(SyncRecordBody.Read(Encoding.UTF8.GetBytes(cloud.ToJsonString()), isTombstone: false,
            SyncPayloadForm.Cloud).Payload);
        Assert.Equal((boost.Id, boost.Css, boost.Script, boost.Look.Font), (synced.Boosts!.Single().Id, synced.Boosts!.Single().Css,
            synced.Boosts!.Single().Script, synced.Boosts!.Single().Look.Font));
        Assert.NotNull(synced.BoostsModifiedAt);

        var written = JsonNode.Parse(BrowserDataSpace.From(space).Write().ToJsonString())!.AsObject();
        var file = BrowserDataSpace.Read(new BrowserDataValue(written));
        var imported = file.Materialize(new TestIds(), DateTimeOffset.UnixEpoch).Settings.ShownBoosts.Single();
        Assert.NotEqual(boost.Id, imported.Id);
        Assert.Equal((boost.Domain, boost.Css, boost.Script), (imported.Domain, imported.Css, imported.Script));
    }
}
