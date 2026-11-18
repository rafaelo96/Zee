import SwiftUI

/// macOS Settings keeps the form canvas transparent inside its window chrome.
struct ZeePlatformSettingsFormModifier: ViewModifier {
    let maxWidth: CGFloat

    func body(content: Content) -> some View {
        content
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .frame(maxWidth: maxWidth)
    }
}
