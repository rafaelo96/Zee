import SwiftUI

/// Animates identity-driven collection changes while honoring Reduce Motion.
struct ZeeCollectionMotionModifier<ID: Hashable>: ViewModifier {
    let ids: [ID]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.animation(
            ZeeMotion.collection.unlessReducingMotion(reduceMotion),
            value: ids
        )
    }
}
