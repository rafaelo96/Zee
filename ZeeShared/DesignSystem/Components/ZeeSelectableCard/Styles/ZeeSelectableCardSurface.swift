import SwiftUI

struct ZeeSelectableCardSurface: View {
    // MARK: - Variables

    let isSelected: Bool
    let density: ZeeSelectableCardDensity
    let tint: Color?
    let configuration: ButtonStyleConfiguration

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var contrast
    @State private var isHovering = false

    var body: some View {
        let tint = tint ?? ZeeBrandTheme.accent
        let shape = ZeeSelectableCardShape(cornerRadius: density.cornerRadius)

        configuration.label
            .padding(density.padding)
            .frame(maxWidth: density.fillsWidth ? .infinity : nil)
            .background(background(tint: tint), in: shape)
            .overlay {
                shape.strokeBorder(
                    isSelected ? tint : ZeeBrandTheme.line,
                    lineWidth: borderWidth
                )
            }
            .contentShape(shape)
            .zeeFocusShape(shape)
            .zeePressFeedback(
                isPressed: configuration.isPressed,
                isEnabled: isEnabled
            )
            .animation(
                ZeeMotion.press.unlessReducingMotion(reduceMotion),
                value: isSelected
            )
            .onHover { isHovering = $0 && isEnabled }
    }

    // MARK: - Actions - Drawing

    private var borderWidth: CGFloat {
        isSelected || contrast == .increased
            ? ZeeSelectableCardMetrics.selectedBorderWidth
            : density.restingBorderWidth
    }

    private func background(tint: Color) -> Color {
        switch (isSelected, configuration.isPressed, isHovering) {
        case (true, true, _):
            tint.opacity(ZeeButtonMetrics.tintEmphasizedFill)
        case (true, false, _):
            tint.opacity(ZeeSelectableCardMetrics.selectedFillOpacity)
        case (false, true, _):
            ZeeColor.selection
        case (false, false, true):
            ZeeColor.hover
        case (false, false, false):
            density.showsRestingFill ? ZeeColor.chromeSurface : .clear
        }
    }
}

#if DEBUG
    #Preview("Card surface") {
        @Previewable @State var selected = false
        ZeeSelectableCard(isSelected: selected, accessibilityLabel: Text("Banner"), action: { selected.toggle() }) {
            Label("Banner", systemImage: "flag.fill").frame(maxWidth: .infinity, alignment: .leading)
        }.padding().frame(width: 320)
    }
#endif
