import SwiftUI

struct ZeeButtonSurface: View {
    let role: ZeeButtonRole
    let tint: Color?
    let configuration: ButtonStyleConfiguration

    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovering = false

    var body: some View {
        rendered
            .zeePressFeedback(
                isPressed: configuration.isPressed,
                isEnabled: isEnabled
            )
            .onHover { isHovering = $0 && isEnabled }
    }

    @ViewBuilder
    private var rendered: some View {
        switch role {
        case .primary:
            primary
        case .secondary:
            secondary
        case .tertiary:
            tertiary
        case .destructive:
            destructive
        case .icon(let diameter, let isProminent):
            icon(diameter: diameter, isProminent: isProminent)
        }
    }

    private var primary: some View {
        configuration.label
            .font(
                ZeeTypography.sans(
                    ZeeButtonMetrics.prominentLabelSize,
                    weight: .bold
                )
            )
            .foregroundStyle(ZeeBrandPalette.ink)
            .padding(.horizontal, ZeeButtonMetrics.prominentHorizontalPadding)
            .frame(minHeight: ZeeButtonMetrics.prominentHeight)
            .background {
                Capsule().fill(
                    (tint ?? ZeeBrandPalette.butter)
                        .opacity(
                            configuration.isPressed
                                ? ZeeButtonMetrics.pressedFillOpacity
                                : 1
                        )
                )
            }
            .overlay {
                Capsule().strokeBorder(
                    ZeeBrandPalette.ink
                        .opacity(ZeeButtonMetrics.inkStrokeOpacity),
                    lineWidth: ZeeButtonMetrics.strokeWidth
                )
            }
            .zeeCapsuleInteractionShape()
    }

    private var secondary: some View {
        configuration.label
            .font(
                ZeeTypography.sans(
                    ZeeButtonMetrics.standardLabelSize,
                    weight: .semibold
                )
            )
            .foregroundStyle(ZeeBrandTheme.textDisplay)
            .padding(.horizontal, ZeeButtonMetrics.standardHorizontalPadding)
            .frame(minHeight: ZeeButtonMetrics.standardHeight)
            .background {
                Capsule().fill(
                    configuration.isPressed || isHovering
                        ? ZeeBrandTheme.surface
                        : ZeeBrandTheme.canvas
                )
            }
            .overlay {
                Capsule().strokeBorder(
                    ZeeBrandTheme.line,
                    lineWidth: ZeeButtonMetrics.strokeWidth
                )
            }
            .zeeCapsuleInteractionShape()
    }

    private var destructive: some View {
        let tint = resolvedTint
        return configuration.label
            .font(
                ZeeTypography.sans(
                    ZeeButtonMetrics.standardLabelSize,
                    weight: .semibold
                )
            )
            .foregroundStyle(resolvedTextTint)
            .padding(.horizontal, ZeeButtonMetrics.standardHorizontalPadding)
            .frame(minHeight: ZeeButtonMetrics.standardHeight)
            .background {
                Capsule().fill(tint.opacity(tintedFillOpacity(isEmphasized: false)))
            }
            .overlay {
                Capsule().strokeBorder(
                    tint.opacity(ZeeButtonMetrics.tintEmphasizedStroke),
                    lineWidth: ZeeButtonMetrics.strokeWidth
                )
            }
            .zeeCapsuleInteractionShape()
    }

    private var tertiary: some View {
        configuration.label
            .font(ZeeTypography.controlTitle)
            .foregroundStyle(resolvedTextTint)
            .padding(.horizontal, ZeeButtonMetrics.quietHorizontalPadding)
            .frame(minHeight: ZeeLayout.minimumHitTarget)
            .zeeInteractiveSurface(
                isSelected: false,
                isHovering: isHovering,
                cornerRadius: ZeeRadius.compact,
                isPressed: configuration.isPressed
            )
            .contentShape(.rect(cornerRadius: ZeeRadius.compact, style: .continuous))
            .zeeFocusShape(
                RoundedRectangle(cornerRadius: ZeeRadius.compact, style: .continuous)
            )
    }

    private func icon(diameter: CGFloat, isProminent: Bool) -> some View {
        // A quiet glyph is a neutral action and draws in the secondary text
        // colour; only a prominent one, or one given a tint, takes a colour.
        let tint = tint ?? (isProminent ? ZeeBrandTheme.accent : ZeeColor.textSecondary)
        let hitTarget = max(diameter, ZeeLayout.minimumHitTarget)
        return configuration.label
            .foregroundStyle(tint)
            .frame(width: diameter, height: diameter)
            .background {
                Circle().fill(
                    tint.opacity(tintedFillOpacity(isEmphasized: isProminent))
                )
            }
            .overlay {
                Circle().strokeBorder(
                    tint.opacity(
                        isProminent
                            ? ZeeButtonMetrics.tintEmphasizedStroke
                            : ZeeButtonMetrics.tintRestStroke
                    ),
                    lineWidth: isProminent
                        ? ZeeButtonMetrics.prominentStrokeWidth
                        : ZeeButtonMetrics.quietStrokeWidth
                )
            }
            .frame(width: hitTarget, height: hitTarget)
            .contentShape(.rect)
            .zeeFocusShape(Circle())
    }

    private var resolvedTint: Color { tint ?? ZeeBrandTheme.accent }
    private var resolvedTextTint: Color { tint ?? ZeeBrandTheme.accentText }

    private func tintedFillOpacity(isEmphasized: Bool) -> Double {
        switch (configuration.isPressed, isEmphasized || isHovering) {
        case (true, _):
            ZeeButtonMetrics.tintPressedFill
        case (false, true):
            ZeeButtonMetrics.tintEmphasizedFill
        case (false, false):
            ZeeButtonMetrics.tintRestFill
        }
    }
}

#if DEBUG
    #Preview("Button roles") {
        VStack(spacing: 16) {
            Button("Save Setup") {}.buttonStyle(.zeePrimary)
            Button("Back") {}.buttonStyle(.zeeSecondary)
            Button("Delete") {}.buttonStyle(.zeeDestructive)
            Button("Manage Filter Lists") {}.buttonStyle(.zeeTertiary)
            Button("Disabled") {}.buttonStyle(.zeePrimary).disabled(true)
        }.padding().frame(width: 300)
    }
#endif
