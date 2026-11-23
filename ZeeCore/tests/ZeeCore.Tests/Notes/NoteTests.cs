using System.Text;
using System.Text.Json.Nodes;

using Xunit;

using ZeeCore.Application;
using ZeeCore.Contracts;

namespace ZeeCore.Tests;

/// Notes: a note opens in a tab that names it, what a Space keeps of one, and
/// that a Space's notes survive its file, its sync record and a browser-data
/// file, still named by the tabs that show them.
public sealed partial class BrowserContractsTests {
    /// A new note opens in a tab whose native content names it; saving the
    /// note names the tab by it, and the Space refuses a note it does not hold
    /// or one past what a note keeps.
    [Fact]
    public void ANoteOpensInATabThatNamesItAndSavingItRenamesTheTab() {
        using var device = new TestDevice(TwoSpaceSession(out var space, out _));
        var window = device.Open(space);
        var (note, tab) = (Guid.NewGuid(), Guid.NewGuid());

        device.Send(new CreateNote(device.Workspace, window, space, note, tab));
        var held = device.Authority.Current.Space(space)!;
        Assert.Equal(note, Assert.Single(held.Settings.ShownNotes).Id);
        var opened = held.Tabs.Single(candidate => candidate.Id == tab);
        Assert.Equal(new NativeTabContent(NativeView.Note.Name, note), opened.NativeContent);
        Assert.Equal(tab, device.Tab(window, space));

        device.Send(new SaveNote(device.Workspace, space, note, "", "\n# Groceries\n- milk"));
        held = device.Authority.Current.Space(space)!;
        Assert.Equal("Groceries", held.Tabs.Single(candidate => candidate.Id == tab).Title);
        device.Send(new SaveNote(device.Workspace, space, note, "Weekly\nplan", "- milk"));
        held = device.Authority.Current.Space(space)!;
        Assert.Equal("Weekly plan", held.Settings.ShownNotes.Single().Title);
        Assert.Equal("Weekly plan", held.Tabs.Single(candidate => candidate.Id == tab).Title);

        Assert.IsType<UnknownNote>(Assert.Throws<Rejected>(() =>
            device.Send(new SaveNote(device.Workspace, space, Guid.NewGuid(), "", ""))).Rejection);
        Assert.IsType<NoteTooLarge>(Assert.Throws<Rejected>(() =>
            device.Send(new SaveNote(device.Workspace, space, note, "", new string('x', Note.MaximumBodyBytes + 1)))).Rejection);

        device.Send(new DeleteNote(device.Workspace, space, note));
        Assert.Empty(device.Authority.Current.Space(space)!.Settings.ShownNotes);
        Assert.IsType<UnknownNote>(Assert.Throws<Rejected>(() => device.Send(new DeleteNote(device.Workspace, space, note))).Rejection);
    }

    /// A Space's notes come back from its stored form, ride its sync record in
    /// both forms with the time someone changed them, and leave in a
    /// browser-data file with the identities their tabs name.
    [Fact]
    public void ASpacesNotesSurviveItsFileItsSyncRecordAndAnExport() {
        using var device = new TestDevice(TwoSpaceSession(out var first, out _));
        var window = device.Open(first);
        var note = Guid.NewGuid();
        device.Send(new CreateNote(device.Workspace, window, first, note, Guid.NewGuid()));
        device.Send(new SaveNote(device.Workspace, first, note, "Trip", "Pack the charger\nBook the train"));
        var space = device.Authority.Current.Space(first)!;
        var kept = Assert.Single(space.Settings.ShownNotes);

        var stored = StoredSessionCodec.DecodeSpace(StoredSessionCodec.Encode(space));
        Assert.Equal(kept, stored.Settings.ShownNotes.Single());
        Assert.Equal(space.Settings.NotesModifiedAt, stored.Settings.NotesModifiedAt);

        var session = StoredSessionCodec.Encode(device.Authority.Current);
        var record = NativeSyncProjection.Project(session, SyncProjectionPreferences(), [])
            .Select(node => node!.AsObject()).First(node => node["type"]!.GetValue<string>() == "space"
                && SyncJson.Identity(node["value"]!["id"]) == first);
        var cloud = SyncRecordBody.Read(record, isTombstone: false, SyncPayloadForm.Journal).Write(SyncPayloadForm.Cloud);
        var synced = Assert.IsType<SpacePayload>(SyncRecordBody.Read(Encoding.UTF8.GetBytes(cloud.ToJsonString()), isTombstone: false,
            SyncPayloadForm.Cloud).Payload);
        var travelled = Assert.Single(synced.Notes!);
        Assert.Equal((kept.Id, kept.Title, kept.Body), (travelled.Id, travelled.Title, travelled.Body));
        Assert.NotNull(synced.NotesModifiedAt);

        var written = JsonNode.Parse(BrowserDataSpace.From(space).Write().ToJsonString())!.AsObject();
        var imported = BrowserDataSpace.Read(new BrowserDataValue(written)).Materialize(new TestIds(), DateTimeOffset.UnixEpoch);
        Assert.Equal((kept.Id, kept.Title, kept.Body), imported.Settings.ShownNotes.Single() is var copy
            ? (copy.Id, copy.Title, copy.Body) : default);
        Assert.Contains(imported.Tabs, tab => tab.NativeContent?.ResourceId == kept.Id);
    }

    /// An easel is a note its tab shows as the easel view: its canvas never
    /// names the tab, only its title does, and it stays an easel through the
    /// Space's file.
    [Fact]
    public void AnEaselOpensAsTheEaselViewAndIsNamedByItsTitleAlone() {
        using var device = new TestDevice(TwoSpaceSession(out var space, out _));
        var window = device.Open(space);
        var (easel, tab) = (Guid.NewGuid(), Guid.NewGuid());

        device.Send(new CreateNote(device.Workspace, window, space, easel, tab, IsEasel: true));
        device.Send(new SaveNote(device.Workspace, space, easel, "", "{\"v\":1,\"items\":[]}"));
        var held = device.Authority.Current.Space(space)!;
        Assert.True(held.Settings.ShownNotes.Single().IsEasel);
        var opened = held.Tabs.Single(candidate => candidate.Id == tab);
        Assert.Equal(new NativeTabContent(NativeView.Easel.Name, easel), opened.NativeContent);
        Assert.Equal(NativeView.Easel.Title, opened.Title);

        device.Send(new SaveNote(device.Workspace, space, easel, "Moodboard", "{\"v\":1,\"items\":[]}"));
        held = device.Authority.Current.Space(space)!;
        Assert.Equal("Moodboard", held.Tabs.Single(candidate => candidate.Id == tab).Title);
        Assert.True(StoredSessionCodec.DecodeSpace(StoredSessionCodec.Encode(held)).Settings.ShownNotes.Single().IsEasel);
    }
}
