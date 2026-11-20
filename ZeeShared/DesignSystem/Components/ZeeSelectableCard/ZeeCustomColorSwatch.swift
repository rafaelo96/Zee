import SwiftUI

/// The last swatch of a row of colors: a circle the size of the others that
/// opens Zee's color field in a popover, for a color of the person's own. It wears
/// that color, ringed, while it is the one chosen, and a plus before.
struct ZeeCustomColorSwatch: View {
    // MARK: - Variables

    let title: LocalizedStringResource
    @Binding var color: Color
    let isSelected: Bool
    var diameter: CGFloat = 28
    var tint: Color? = nil

    @State private var isHovering = false
    @State private var isPicking = false

    // MARK: - Actions - Drawing

    var body: some View {
        Button {
            isPicking.toggle()
        } label: {
            Circle()
                .fill(
                    isSelected
                        ? AnyShapeStyle(color) : AnyShapeStyle(isHovering ? ZeeColor.hover : ZeeColor.chromeSurface)
                )
                .overlay {
                    Image(systemName: "plus")
                        .font(.system(size: diameter * 0.42, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .opacity(isSelected ? 0 : 1)
                }
                .overlay { Circle().strokeBorder(ZeeBrandTheme.line, lineWidth: ZeeLayout.hairline) }
                .frame(width: diameter, height: diameter)
                .padding(ZeeSelectableCardDensity.swatch.padding)
                .overlay {
                    Circle()
                        .strokeBorder(
                            tint ?? ZeeBrandTheme.accent, lineWidth: ZeeSelectableCardMetrics.selectedBorderWidth
                        )
                        .opacity(isSelected ? 1 : 0)
                }
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(title))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .onHover { isHovering = $0 }
        .help(Text(title))
        .zeePopover(isPresented: $isPicking, arrowEdge: .bottom) {
            ZeeColorField(color: $color)
        }
    }
}

#if DEBUG
    #Preview("Custom color swatch") {
        @Previewable @State var color = Color.orange
        @Previewable @State var chosen = false
        HStack(spacing: 16) {
            ZeeCustomColorSwatch(title: "Custom color", color: $color, isSelected: false)
            ZeeCustomColorSwatch(title: "Custom color", color: $color, isSelected: true)
            Toggle("Chosen", isOn: $chosen)
            ZeeCustomColorSwatch(title: "Custom color", color: $color, isSelected: chosen)
        }
        .padding(32)
    }
#endif
