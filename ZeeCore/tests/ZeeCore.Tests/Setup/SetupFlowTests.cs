using System.Text.Json.Nodes;

using ZeeCore.Application;
using ZeeCore.Contracts;

using Xunit;

namespace ZeeCore.Tests;

/// Setup as the core walks a person through it: where each entry opens and
/// where Back and Next lead on each platform, the queue of browsers it imports
/// in turn, finishing, which applies the manual setup and opens the Getting
/// Started guide only in an unlocked first Space, and whether the device has
/// completed setup, which the device store adopts once and keeps.
public sealed partial class BrowserContractsTests {
    [Fact]
    public void CompletionIsAdoptedOnceAndKeptInTheDeviceStore() {
        using var directory = new StorageDirectory();
        var document = SavedSession().Document["session"]!.AsObject();
        var configuration = new AppConfiguration(directory.Path, DevicePlatform.Desktop);
        Guid first = SpaceId(document["spaces"]![0]!);
        using (var app = new ZeeApp(configuration)) {
            app.Send(Adoption(document));
            var workspace = TestWorkspaces.OpenStored(app).Workspace;
            Assert.Contains(new SetupCompletedChanged(false), app.Send(new AdoptSetupCompletion(Completed: false)));
            var fresh = Flowing(app.Send(new StartSetup(workspace, SetupEntry.FirstRun)));
            Assert.Equal((true, false), (fresh.OpensGuide, fresh.OpensZeeFromWelcome));
            var finished = app.Send(new FinishSetup(Guid.NewGuid()));
            Assert.Contains(new SetupCompletedChanged(true), finished);
            Assert.Contains(new SetupFinished(workspace, first), finished);
        }
        using (var app = new ZeeApp(configuration)) {
            var workspace = TestWorkspaces.OpenStored(app).Workspace;
            // The store adopted once: what an installed release kept no longer counts.
            Assert.Contains(new SetupCompletedChanged(true), app.Send(new AdoptSetupCompletion(Completed: false)));
            var again = Flowing(app.Send(new StartSetup(workspace, SetupEntry.FirstRun)));
            Assert.Equal((false, true), (again.OpensGuide, again.OpensZeeFromWelcome));
            Assert.True(Flowing(app.Send(new StartSetup(workspace, SetupEntry.Rerun))).OpensGuide);
        }
        using var adopting = new StorageDirectory();
        using (var app = new ZeeApp(new AppConfiguration(adopting.Path, DevicePlatform.Desktop))) {
            app.Send(Adoption(document));
            Assert.Contains(new SetupCompletedChanged(true), app.Send(new AdoptSetupCompletion(Completed: true)));
        }
        using var reopened = new ZeeApp(new AppConfiguration(adopting.Path, DevicePlatform.Desktop));
        Assert.Contains(new SetupCompletedChanged(true), reopened.Send(new AdoptSetupCompletion(Completed: false)));
    }

    /// Once setup is done, Zee invites the person to bring Arc while its data
    /// is on the device, until they import or dismiss it; the device store
    /// keeps that they did. A browser setup does not choose first brings no
    /// invitation.
    [Fact]
    public void ArcInvitationShowsAfterSetupUntilSettledAndStaysSettled() {
        using var directory = new StorageDirectory();
        var document = SavedSession().Document["session"]!.AsObject();
        var configuration = new AppConfiguration(directory.Path, DevicePlatform.Desktop);
        using (var app = new ZeeApp(configuration)) {
            app.Send(Adoption(document));
            var workspace = TestWorkspaces.OpenStored(app).Workspace;
            app.Send(new AdoptSetupCompletion(Completed: false));
            Assert.Null(app.Query(new GetImportInvitation([ImportSource.Arc])).Source);
            app.Send(new StartSetup(workspace, SetupEntry.FirstRun));
            app.Send(new FinishSetup(Guid.NewGuid()));
            Assert.Null(app.Query(new GetImportInvitation([ImportSource.Chrome])).Source);
            Assert.Equal(ImportSource.Arc, app.Query(new GetImportInvitation([ImportSource.Chrome, ImportSource.Arc])).Source);
            app.Send(new SettleImportInvitation(ImportSource.Arc));
            Assert.Null(app.Query(new GetImportInvitation([ImportSource.Arc])).Source);
        }
        using var reopened = new ZeeApp(configuration);
        TestWorkspaces.OpenStored(reopened);
        Assert.Null(reopened.Query(new GetImportInvitation([ImportSource.Arc])).Source);
    }
}
