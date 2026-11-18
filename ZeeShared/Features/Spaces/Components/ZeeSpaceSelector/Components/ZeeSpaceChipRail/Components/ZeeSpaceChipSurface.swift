import SwiftUI

struct ZeeSpaceChipSurface<LabelContent: View>: View {
    let tint: Color
    let isSelected: Bool
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
                    weight: isSelected ? .bold : .medium
                )
            )
            .foregroundStyle(ZeeBrandTheme.textDisplay)
            .padding(.horizontal, ZeeSpaceChipMetrics.horizontalPadding)
            .frame(height: ZeeSpaceChipMetrics.height)
            .background(fill, in: shape)
            .overlay {
                shape.strokeBorder(
                    isSelected
                        ? tint.opacity(ZeeSpaceChipMetrics.selectedStrokeOpacity)
                        : ZeeBrandTheme.line,
                    lineWidth: isSelected
                        ? ZeeSpaceChipMetrics.selectedStrokeWidth
                        : ZeeSpaceChipMetrics.restingStrokeWidth
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

    private var fill: Color {
        if isSelected {
            return tint.opacity(
                isPressed
                    ? ZeeButtonMetrics.tintPressedFill
                    : ZeeButtonMetrics.tintEmphasizedFill
            )
        }
        if isPressed || isHovering {
            return ZeeBrandTheme.surface
        }
        return ZeeBrandTheme.canvas
    }
}

#if DEBUG
    #Preview("Selected and unselected") {
        HStack {
            ZeeSpaceChipSurface(
                tint: .indigo, isSelected: true, isPressed: false, label: Label("Work", systemImage: "briefcase.fill"))
            ZeeSpaceChipSurface(
                tint: .orange, isSelected: false, isPressed: false, label: Label("Personal", systemImage: "house.fill"))
        }.padding()
    }
#endif
