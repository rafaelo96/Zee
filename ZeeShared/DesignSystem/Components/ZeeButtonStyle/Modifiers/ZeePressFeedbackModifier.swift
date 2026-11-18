import SwiftUI

struct ZeePressFeedbackModifier: ViewModifier {
    let isPressed: Bool
    let isEnabled: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .scaleEffect(
                (isPressed ? ZeeButtonMetrics.pressedScale : 1).unlessReducingMotion(reduceMotion)
            )
            .opacity(isEnabled ? 1 : ZeeButtonMetrics.disabledOpacity)
            .animation(
                ZeeMotion.press.unlessReducingMotion(reduceMotion),
                value: isPressed
            )
    }
}
