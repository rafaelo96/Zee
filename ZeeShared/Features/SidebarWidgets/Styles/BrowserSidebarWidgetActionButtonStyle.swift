import SwiftUI

enum BrowserSidebarWidgetActionEmphasis {
    case prominent
    case quiet
}

/// Applies Zee action styling at widget-card dimensions.
struct BrowserSidebarWidgetActionButtonStyle: ButtonStyle {
    let emphasis: BrowserSidebarWidgetActionEmphasis

    func makeBody(configuration: Configuration) -> some View {
        BrowserSidebarWidgetActionSurface(
            emphasis: emphasis,
            configuration: configuration
        )
    }
}

private struct BrowserSidebarWidgetActionSurface: View {
    let emphasis: BrowserSidebarWidgetActionEmphasis
    let configuration: ButtonStyleConfiguration

    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovering = false

    var body: some View {
        rendered
            .contentShape(shape)
            .zeeFocusShape(shape)
            .zeePressFeedback(
                isPressed: configuration.isPressed,
                isEnabled: isEnabled
            )
            .onHover { isHovering = $0 && isEnabled }
    }

    @ViewBuilder
    private var rendered: some View {
        switch emphasis {
        case .prominent:
            labeled
                .browserReadableForeground(over: ZeeBrandTheme.accent)
                .background(
                    ZeeBrandTheme.accent.opacity(
                        configuration.isPressed
                            ? ZeeButtonMetrics.pressedFillOpacity
                            : 1
                    ),
                    in: shape
                )
                .overlay {
                    shape.strokeBorder(
                        ZeeBrandPalette.ink
                            .opacity(ZeeButtonMetrics.inkStrokeOpacity),
                        lineWidth: ZeeButtonMetrics.strokeWidth
                    )
                }
        case .quiet:
            labeled
                .foregroundStyle(.primary)
                .background {
                    ZeeSurfaceLayer(
                        shape: shape,
                        hoverTint: configuration.isPressed || isHovering ? ZeeColor.selection : nil
                    )
                }
                .overlay {
                    shape.strokeBorder(
                        ZeeColor.subtleBorder,
                        lineWidth: ZeeButtonMetrics.strokeWidth
                    )
                }
        }
    }

    private var labeled: some View {
        configuration.label
            .font(.subheadline.weight(.medium))
            .labelStyle(.titleAndIcon)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, ZeeSpacing.medium)
            .padding(.vertical, ZeeSpacing.extraSmall)
            .frame(
                maxWidth: .infinity,
                minHeight: BrowserSidebarWidgetDeckStyle.actionHeight
            )
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: ZeeRadius.control, style: .continuous)
    }
}
