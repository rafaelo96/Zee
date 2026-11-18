import SwiftUI

extension View {
    func zeeSettingsForm(
        maxWidth: CGFloat = BrowserSettingsLayout.maximumReadableContentWidth
    ) -> some View {
        modifier(ZeePlatformSettingsFormModifier(maxWidth: maxWidth))
    }
}
