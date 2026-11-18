import SwiftUI

struct BrowserOnboardingWelcomeCallToAction: View {
    let action: BrowserOnboardingWelcomeAction
    let cloudStatusDetail: String
    let perform: () -> Void
    let setUpWithoutCloud: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: perform) {
                HStack(spacing: 10) {
                    if action.waitsOnCloud {
                        ProgressView().controlSize(.small)
                    }
                    Text(action.opensZee ? "Open Zee" : "Continue")
                    Image(systemName: "arrow.right")
                }
                .frame(minWidth: 120)
            }
            .buttonStyle(.zeePrimary)
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)
            .disabled(action.waitsOnCloud)
            .accessibilityLabel(
                action.opensZee ? Text("Open Zee") : Text("Continue")
            )
            .accessibilityIdentifier("onboarding-welcome-continue")

            Text(
                action.waitsOnCloud
                    ? String(localized: "Checking iCloud for an existing setup…")
                    : cloudStatusDetail
            )
            .font(ZeeTypography.sans(12, weight: .medium))
            .foregroundStyle(ZeeBrandTheme.textSecondary)

            if action.offersSetupWithoutCloud {
                Button("Set Up Without iCloud", action: setUpWithoutCloud)
                    .buttonStyle(.zeeTertiary)
                    .accessibilityIdentifier("onboarding-welcome-setup-without-icloud")
            }
        }
    }
}
