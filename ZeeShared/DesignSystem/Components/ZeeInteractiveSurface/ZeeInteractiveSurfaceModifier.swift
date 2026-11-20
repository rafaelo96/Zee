import SwiftUI

/// Geometry shared by selected, pressed, and hovered browser surfaces.
enum ZeeInteractiveSurfaceMetrics {
    static let defaultSelectedBorderWidth: CGFloat = 0.5
    static let increasedContrastBorderWidth: CGFloat = 1.5
    static let selectedShadowRadius: CGFloat = 4
    static let selectedShadowYOffset: CGFloat = 1.5
}

struct ZeeInteractiveSurfaceModifier: ViewModifier {
    let isSelected: Bool
    var selectionEmphasis = false
    let isHovering: Bool
    let cornerRadius: CGFloat
    let isPressed: Bool
    let showsRestingSurface: Bool
    let selectedBorderColor: Color
    let selectedBorderWidth: CGFloat
    var customSelectedFill: Color? = nil
    var customHoverFill: Color? = nil
    var customRestingFill: Color? = nil
    var restingBorderColor: Color = .clear

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.deviceColorScheme) private var deviceColorScheme

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(
            cornerRadius: cornerRadius,
            style: .continuous
        )
        let isEmphasized = isSelected || isPressed

        content
            .background {
                surface(in: shape)
                    .overlay { if selectionEmphasis { shape.fill(ZeeColor.hover) } }
            }
            .overlay {
                shape
                    .strokeBorder(
                        isEmphasized ? selectedBorderColor : restingBorderColor,
                        lineWidth: borderWidth
                    )
                    .allowsHitTesting(false)
            }
            .shadow(
                color: .black.opacity(shadowOpacity),
                radius: isEmphasized
                    ? ZeeInteractiveSurfaceMetrics.selectedShadowRadius
                    : 0,
                y: isEmphasized
                    ? ZeeInteractiveSurfaceMetrics.selectedShadowYOffset
                    : 0
            )
            .animation(accessibleSurfaceAnimation, value: isHovering)
            .animation(accessibleSurfaceAnimation, value: selectionEmphasis)
            // Selection shows at once, as browsers switch tabs; only a press
            // eases in. Fading a selected surface in and out redraws its
            // shadow, its glow and the content it covers every frame, on two
            // surfaces at every tab switch.
            .animation(accessibleSurfaceAnimation, value: isPressed)
            // Content on the material reads in the material's scheme.
            .environment(
                \.colorScheme,
                showsMaterial ? ZeeSurfaceTone.shownScheme(over: colorScheme, window: deviceColorScheme) : colorScheme
            )
    }

    /// Whether the surface draws the device's material under the content.
    private var showsMaterial: Bool { isSelected || isPressed || showsRestingSurface }

    /// Selected, pressed and resting surfaces are layers of the device's
    /// material, wearing their accent tint; hover is only ever a tint, laid
    /// over that material or, on a plain row, alone.
    @ViewBuilder
    private func surface(in shape: RoundedRectangle) -> some View {
        if showsMaterial {
            ZeeSurfaceLayer(
                shape: shape,
                tint: isSelected || isPressed ? customSelectedFill : customRestingFill,
                hoverTint: isHovering ? hoverFill : nil
            )
        } else if isHovering {
            shape.fill(hoverFill)
        }
    }

    private var hoverFill: Color { customHoverFill ?? ZeeColor.hover }

    private var borderWidth: CGFloat {
        guard contrast == .increased else { return selectedBorderWidth }
        return max(
            ZeeInteractiveSurfaceMetrics.increasedContrastBorderWidth,
            selectedBorderWidth
        )
    }

    private var shadowOpacity: Double {
        guard isSelected || isPressed, !reduceTransparency else { return 0 }
        return ZeeOpacity.interactionSelectionShadow
    }

    private var accessibleSurfaceAnimation: Animation? {
        ZeeMotion.surface.unlessReducingMotion(reduceMotion)
    }
}

/// Owns pointer hover state for controls that use Zee's shared interaction
/// surface but do not otherwise need to react to hover themselves.
private struct ZeeHoverSurfaceModifier: ViewModifier {
    let isSelected: Bool
    let cornerRadius: CGFloat
    let isPressed: Bool
    let showsRestingSurface: Bool
    let selectedBorderColor: Color
    let selectedBorderWidth: CGFloat

    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovering = false

    func body(content: Content) -> some View {
        content
            .zeeInteractiveSurface(
                isSelected: isSelected,
                isHovering: isHovering && isEnabled,
                cornerRadius: cornerRadius,
                isPressed: isPressed && isEnabled,
                showsRestingSurface: showsRestingSurface,
                selectedBorderColor: selectedBorderColor,
                selectedBorderWidth: selectedBorderWidth
            )
            .onHover { isHovering = $0 }
    }
}

extension View {
    func zeeInteractiveSurface(
        isSelected: Bool,
        isHovering: Bool,
        cornerRadius: CGFloat = ZeeRadius.compact,
        selectionEmphasis: Bool = false,
        isPressed: Bool = false,
        showsRestingSurface: Bool = false,
        selectedBorderColor: Color = ZeeColor.selectedBorder,
        selectedBorderWidth: CGFloat =
            ZeeInteractiveSurfaceMetrics.defaultSelectedBorderWidth
    ) -> some View {
        modifier(
            ZeeInteractiveSurfaceModifier(
                isSelected: isSelected,
                selectionEmphasis: selectionEmphasis,
                isHovering: isHovering,
                cornerRadius: cornerRadius,
                isPressed: isPressed,
                showsRestingSurface: showsRestingSurface,
                selectedBorderColor: selectedBorderColor,
                selectedBorderWidth: selectedBorderWidth
            )
        )
    }

    func zeeHoverSurface(
        isSelected: Bool = false,
        cornerRadius: CGFloat = ZeeRadius.compact,
        isPressed: Bool = false,
        showsRestingSurface: Bool = false,
        selectedBorderColor: Color = ZeeColor.selectedBorder,
        selectedBorderWidth: CGFloat =
            ZeeInteractiveSurfaceMetrics.defaultSelectedBorderWidth
    ) -> some View {
        modifier(
            ZeeHoverSurfaceModifier(
                isSelected: isSelected,
                cornerRadius: cornerRadius,
                isPressed: isPressed,
                showsRestingSurface: showsRestingSurface,
                selectedBorderColor: selectedBorderColor,
                selectedBorderWidth: selectedBorderWidth
            )
        )
    }
}
