import SwiftUI

/// Edits a monogram emblem's letters and their style.
struct BrowserBadgeStudioMonogramEmblemControls: View {
    @Binding var monogram: String
    @Binding var monogramStyle: BadgeMonogramStyle

    var body: some View {
        BrowserBadgeStudioTextField(title: "One or two letters", text: $monogram)
        Picker("Letter style", selection: $monogramStyle) {
            Text("Serif").tag(BadgeMonogramStyle.serif)
            Text("Sans").tag(BadgeMonogramStyle.sans)
        }.pickerStyle(.segmented)
    }
}
