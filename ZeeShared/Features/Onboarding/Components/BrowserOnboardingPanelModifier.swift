import SwiftUI

struct BrowserOnboardingPanelModifier: ViewModifier {
    func body(content: Content) -> some View {
        let shape = RoundedRectangle(
            cornerRadius: ZeeRadius.card,
            style: .continuous
        )
        return
            content
            .background(ZeeBrandTheme.canvas, in: shape)
            .overlay {
                shape.strokeBorder(
                    ZeeBrandTheme.line,
                    lineWidth: ZeeLayout.hairline
                )
            }
    }
}
