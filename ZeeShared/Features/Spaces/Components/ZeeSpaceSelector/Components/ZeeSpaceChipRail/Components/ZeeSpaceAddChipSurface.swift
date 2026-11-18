import SwiftUI

struct ZeeSpaceAddChipSurface<LabelContent: View>: View {
    let tint: Color
    let isPressed: Bool
    let label: LabelContent

    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovering = false

    private var shape: RoundedRectangle {
        RoundedRectangle(
            cornerRadius: ZeeSpaceChipMetrics.cornerRadius,
            style: .continuous
        )
    }

    var body: some View {
        label
            .font(
                ZeeTypography.sans(
                    ZeeButtonMetrics.standardLabelSize,
                    weight: .semibold
                )
            )
            .foregroundStyle(tint)
            .padding(.horizontal, ZeeSpaceChipMetrics.horizontalPadding)
            .frame(height: ZeeSpaceChipMetrics.height)
            .background(
                tint.opacity(
                    isPressed
                        ? ZeeButtonMetrics.tintEmphasizedFill
                        : isHovering ? ZeeButtonMetrics.tintRestFill : 0
                ),
                in: shape
            )
            .overlay {
                shape.strokeBorder(
                    tint.opacity(ZeeButtonMetrics.tintEmphasizedStroke),
                    style: StrokeStyle(
                        lineWidth: ZeeSpaceChipMetrics.restingStrokeWidth,
                        dash: ZeeSpaceChipMetrics.dashPattern
                    )
                )
            }
            .contentShape(
                .rect(
                    cornerRadius: ZeeSpaceChipMetrics.cornerRadius,
                    style: .continuous
                )
            )
            .zeeFocusShape(shape)
            .zeePressFeedback(
                isPressed: isPressed,
                isEnabled: isEnabled
            )
            .onHover { isHovering = $0 && isEnabled }
    }
}

#if DEBUG
    #Preview("Component") {
        ZeeSpaceAddChipSurface(tint: .indigo, isPressed: false, label: Label("New Space", systemImage: "plus"))
            .padding()
    }
#endif
