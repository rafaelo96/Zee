import SwiftUI

struct BrowserOnboardingWindowContent: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let request: BrowserOnboardingRequest
    let cloudSync: BrowserCloudSyncController
    let progress: BrowserOnboardingProgressStore
    let flow: BrowserOnboardingFlow
    let cloudWait: BrowserOnboardingCloudWait
    @Binding var selectedManualSpaceID: UUID?
    @Binding var customizationSpaceID: UUID?
    let close: () -> Void
    let openZee: () -> Void

    /// Which template's field the welcome shows, cycling through them all.

    var body: some View {
        BrowserOnboardingStage(step: flow.step) {
            VStack(spacing: 0) {
                if let customizationSpaceID, flow.review != nil {
                    BrowserImportSpaceCustomizationView(
                        flow: flow,
                        spaceID: customizationSpaceID,
                        previewSpace: flow.customizationPreviewSpace(
                            customizationSpaceID
                        ),
                        done: { self.customizationSpaceID = nil }
                    )
                } else {
                    BrowserOnboardingStepContent(
                        cloudSync: cloudSync,
                        progress: progress,
                        flow: flow,
                        cloudWait: cloudWait,
                        selectedManualSpaceID: $selectedManualSpaceID,
                        customizationSpaceID: $customizationSpaceID,
                        close: close,
                        openZee: openZee
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                if let failure = flow.completionFailure {
                    Text(failure)
                        .foregroundStyle(ZeeColor.danger)
                        .padding()
                }
            }
            .disabled(flow.isCompletingSetup)
        }
        .ignoresSafeArea()
        .frame(minWidth: 980, minHeight: 660)
        .tint(ZeeBrandTheme.accent)
        .background(BrowserOnboardingWindowConfigurator())
        .task {
            await start()
        }
        .task {
            await cloudWait.run()
        }
        .onChange(of: request) { _, newRequest in
            resetTransientState(for: newRequest)
        }
        .onChange(of: flow.step) { _, step in
            if step == .manualSetup { flow.manualSetup.repairSelection($selectedManualSpaceID) }
        }
        .onDisappear(perform: flow.cancelOperations)
        .animation(motion(ZeeMotion.onboardingStep), value: flow.step)
    }

    private func start() async {
        flow.start()
        flow.discoverInstalledSources()
        flow.manualSetup.repairSelection($selectedManualSpaceID)
    }

    private func resetTransientState(for request: BrowserOnboardingRequest) {
        customizationSpaceID = nil
        withAnimation(motion(ZeeMotion.onboardingStep)) {
            flow.reset(for: request)
        }
        selectedManualSpaceID = flow.manualSetup.spaces.first?.spaceID
    }

    private func motion(_ animation: Animation) -> Animation? {
        animation.unlessReducingMotion(reduceMotion)
    }
}
