import SwiftUI

/// Shared selectable surface for callers with custom card content.
struct ZeeSelectableCardStyle: ButtonStyle {
    let isSelected: Bool
    var density = ZeeSelectableCardDensity.regular
    var tint: Color?

    func makeBody(configuration: Configuration) -> some View {
        ZeeSelectableCardSurface(
            isSelected: isSelected,
            density: density,
            tint: tint,
            configuration: configuration
        )
    }
}
