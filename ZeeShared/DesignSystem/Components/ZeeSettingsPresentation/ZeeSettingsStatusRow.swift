import SwiftUI

struct ZeeSettingsStatusRow<Status: View>: View {
    let title: LocalizedStringResource
    private let status: Status

    init(
        _ title: LocalizedStringResource,
        @ViewBuilder status: () -> Status
    ) {
        self.title = title
        self.status = status()
    }

    var body: some View {
        HStack(
            alignment: .center,
            spacing: ZeeSettingsPresentationMetrics.statusSpacing
        ) {
            Text(title)
            Spacer(minLength: 0)
            status
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#if DEBUG
    #Preview("Component") {
        Form {
            ZeeSettingsStatusRow("Sync") {
                Label("Up to date", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
            }
        }.zeeSettingsForm().frame(width: 400, height: 150)
    }
#endif
