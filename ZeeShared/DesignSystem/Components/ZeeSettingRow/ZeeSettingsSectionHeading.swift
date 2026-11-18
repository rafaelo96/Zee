import SwiftUI

/// A settings section's title, drawn in the platform's own section-header style.
struct ZeeSettingsSectionHeading: View {
    let title: LocalizedStringKey

    var body: some View {
        Text(title)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
    }
}
