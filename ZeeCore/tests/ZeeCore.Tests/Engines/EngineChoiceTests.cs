using System.Text;

using ZeeCore.Application;
using ZeeCore.Contracts;

using Xunit;

namespace ZeeCore.Tests;

/// Which engine a new page opens on beyond a site's choice: its Space's own
/// engine, then WebKit while the device saves battery, then the default; and
/// when Zee suggests Chromium for the site a WebKit page shows.
public sealed partial class BrowserContractsTests {
    private sealed record TwoEngines(ZeeApp App, Engine Chromium, Engine WebKit, RecordingEngine ChromiumBinding,
        RecordingEngine WebKitBinding, Guid Workspace, Guid Window, Guid Space);

    /// An app with Chromium as the default and WebKit beside it, a workspace
    /// over the saved session and a window showing nothing.
    private static TwoEngines OpenTwoEngines() {
        var session = SavedSession().Document["session"]!;
        var app = new ZeeApp();
        var (chromiumBinding, webKitBinding) = (new RecordingEngine(), new RecordingEngine());
        var chromium = app.RegisterEngine(new EngineRegistration(EngineKind.Chromium, EngineCapability.Required, IsDefault: true),
            chromiumBinding.Run);
        var webKit = app.RegisterEngine(new EngineRegistration(EngineKind.WebKit, EngineCapability.Required, IsDefault: false),
            webKitBinding.Run);
        var workspace = TestWorkspaces.Open(app, session);
        var window = Guid.NewGuid();
        app.Send(new OpenWindow(window, workspace, Saved: false, null, null, [], RestoresTabs: true));
        return new(app, chromium, webKit, chromiumBinding, webKitBinding, workspace, window, SpaceId(session["spaces"]![0]!));
    }

    [Fact]
    public void ANewPageOpensOnItsSitesChoiceThenItsSpacesEngineThenForBatteryThenTheDefault() {
        var engines = OpenTwoEngines();
        using var disposal = engines.App;
        var (app, space) = (engines.App, engines.Space);
        EngineKind Opens(string url) {
            var (_, page) = LiveTab(app, engines.Chromium, engines.Workspace, engines.Window, space, url);
            return CreatedOn(page, engines.ChromiumBinding, engines.WebKitBinding);
        }

        Assert.Equal(EngineKind.Chromium, Opens("https://plain.example/"));
        app.Send(new SetSpaceEngine(engines.Workspace, space, EngineKind.WebKit));
        Assert.Equal(EngineKind.WebKit, Opens("https://plain.example/a"));
        app.Send(new ChooseSiteEngine(space, new WebAddress("https://chosen.example/").Origin!, EngineKind.Chromium));
        Assert.Equal(EngineKind.Chromium, Opens("https://chosen.example/"));

        app.Send(new SetSpaceEngine(engines.Workspace, space, null));
        app.Send(new SetSavesBattery(true));
        Assert.Equal(EngineKind.Chromium, Opens("https://plain.example/b"));
        app.Send(new ReportPowerConstraint(true));
        Assert.Equal(EngineKind.WebKit, Opens("https://plain.example/c"));
        Assert.Equal(EngineKind.Chromium, Opens("https://chosen.example/b"));
        Assert.True(app.Query(new GetEnginePreferences()).SavesBattery);
        app.Send(new SetSavesBattery(false));
        Assert.Equal(EngineKind.Chromium, Opens("https://plain.example/d"));

        // A page the site's choice opened in Chromium stays there as it goes to
        // another site, whatever the Space or battery would choose for a new page.
        app.Send(new SetSpaceEngine(engines.Workspace, space, EngineKind.WebKit));
        var (_, kept) = LiveTab(app, engines.Chromium, engines.Workspace, engines.Window, space, "https://chosen.example/c");
        app.Report(engines.Chromium, new NavigationStarted(kept, "https://plain.example/e", SameDocument: false));
        Assert.DoesNotContain(engines.WebKitBinding.Commands, command => command is CreatePage creation && creation.PageId == kept);
    }

    [Fact]
    public void ZeeSuggestsChromiumForAKnownSiteOrAStoppingPageUntilDismissedOrChosen() {
        var engines = OpenTwoEngines();
        using var disposal = engines.App;
        var (app, space) = (engines.App, engines.Space);
        app.Send(new SetSpaceEngine(engines.Workspace, space, EngineKind.WebKit));
        Guid OnWebKit(string url) {
            var (_, page) = LiveTab(app, engines.WebKit, engines.Workspace, engines.Window, space, url);
            app.Report(engines.WebKit, new NavigationCommitted(page, url, SameDocument: false));
            return page;
        }

        var teams = OnWebKit("https://teams.microsoft.com/v2/");
        Assert.Equal((EngineKind.Chromium, EngineSuggestionReason.KnownSite),
            (app.Query(new SuggestedEngine(teams)).Engine, app.Query(new SuggestedEngine(teams)).Reason));
        var plain = OnWebKit("https://plain.example/");
        Assert.Null(app.Query(new SuggestedEngine(plain)).Engine);
        app.Report(engines.WebKit, new PageCrashed(plain, "WebKitErrorDomain", 1));
        Assert.Equal(EngineSuggestionReason.Unstable, app.Query(new SuggestedEngine(plain)).Reason);

        app.Send(new DismissEngineSuggestion(new WebAddress("https://plain.example/").Origin!));
        Assert.Null(app.Query(new SuggestedEngine(plain)).Engine);
        app.Send(new ChooseSiteEngine(space, new WebAddress("https://teams.microsoft.com/").Origin!, EngineKind.WebKit));
        Assert.Null(app.Query(new SuggestedEngine(teams)).Engine);
        app.Send(new SetSpaceEngine(engines.Workspace, space, null));
        var onChromium = LiveTab(app, engines.Chromium, engines.Workspace, engines.Window, space, "https://vscode.dev/").Page;
        Assert.Null(app.Query(new SuggestedEngine(onChromium)).Engine);
    }

    /// A Space's engine survives its stored form and rides its sync record in
    /// both forms with the time someone chose.
    [Fact]
    public void ASpacesEngineSurvivesItsFileAndItsSyncRecord() {
        var engines = OpenTwoEngines();
        using var disposal = engines.App;
        engines.App.Send(new SetSpaceEngine(engines.Workspace, engines.Space, EngineKind.WebKit));
        var space = engines.App.Workspace(engines.Workspace).Current.Space(engines.Space)!;

        var stored = StoredSessionCodec.DecodeSpace(StoredSessionCodec.Encode(space));
        Assert.Equal((EngineKind.WebKit, space.Settings.PreferredEngineModifiedAt),
            (stored.Settings.PreferredEngine, stored.Settings.PreferredEngineModifiedAt));

        var record = NativeSyncProjection.Project(StoredSessionCodec.Encode(engines.App.Workspace(engines.Workspace).Current),
                SyncProjectionPreferences(), [])
            .Select(node => node!.AsObject()).First(node => node["type"]!.GetValue<string>() == "space");
        var cloud = SyncRecordBody.Read(record, isTombstone: false, SyncPayloadForm.Journal).Write(SyncPayloadForm.Cloud);
        var synced = Assert.IsType<SpacePayload>(SyncRecordBody.Read(Encoding.UTF8.GetBytes(cloud.ToJsonString()), isTombstone: false,
            SyncPayloadForm.Cloud).Payload);
        Assert.Equal(EngineKind.WebKit, synced.PreferredEngine);
        Assert.NotNull(synced.PreferredEngineModifiedAt);
    }
}
