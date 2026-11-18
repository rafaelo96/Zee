import SwiftUI

extension View {
    /// Pins a custom control's keyboard focus ring to the authored shape.
    func zeeFocusShape(_ shape: some Shape) -> some View {
        modifier(ZeePlatformFocusShapeModifier(shape: shape))
    }

    func zeeCapsuleInteractionShape() -> some View {
        contentShape(.capsule)
            .zeeFocusShape(Capsule())
    }

    /// Shared press acknowledgement, disabled treatment, and Reduce Motion gate.
    func zeePressFeedback(isPressed: Bool, isEnabled: Bool) -> some View {
        modifier(
            ZeePressFeedbackModifier(
                isPressed: isPressed,
                isEnabled: isEnabled
            )
        )
    }
}
