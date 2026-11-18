import SwiftUI

/// The dashed "one more" chip.
struct ZeeSpaceAddChipStyle: ButtonStyle {
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        ZeeSpaceAddChipSurface(
            tint: tint,
            isPressed: configuration.isPressed,
            label: configuration.label
        )
    }
}
