import SwiftUI

/// A Space's badge at any size: plate, field, band, edge, trim, and charge,
/// composed from paths and colored from the badge's own tinctures or the
/// Space's.
struct BrowserSpaceBadgeIcon: View, Equatable {
    let branding: SpaceBranding
    var size: CGFloat = 44
    var rasterizesLayers = true

    /// The plate's diameter as a fraction of the icon, before ``SpaceBadge/plateScale``.
    static let plateFraction: CGFloat = 0.78

    nonisolated static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.branding.badge == rhs.branding.badge && lhs.branding.colors == rhs.branding.colors
            && lhs.size == rhs.size && lhs.rasterizesLayers == rhs.rasterizesLayers
    }

    var body: some View {
        let badge = branding.badge
        let plate = BrowserSpaceBadgePlateShape(backplate: badge.backplate, scallops: badge.sealTeeth)
        let plateSide = size * Self.plateFraction * CGFloat(badge.plateScale)
        let plateRect = CGRect(
            x: (size - plateSide) / 2, y: (size - plateSide) / 2, width: plateSide, height: plateSide)
        ZStack {
            if badge.backplate != .none {
                BrowserSpaceBadgeField(
                    division: badge.fieldDivision,
                    divisionCount: badge.divisionCount,
                    finish: badge.finish,
                    sheenAngle: badge.sheenAngle,
                    primaryColor: color(at: badge.backplateColorIndex),
                    secondaryColor: color(at: badge.secondaryFieldColorIndex)
                )
                .frame(width: plateSide, height: plateSide)
                .clipShape(plate)

                BrowserSpaceBadgeOrdinaryView(
                    ordinary: badge.ordinary,
                    width: badge.ordinaryWidth,
                    plate: plate,
                    color: color(at: badge.ordinaryColorIndex),
                    size: plateSide
                )

                if badge.showsOutline {
                    plate.stroke(color(at: badge.edgeColorIndex), lineWidth: max(0.6, size * 0.012))
                        .frame(width: plateSide, height: plateSide)
                }
                if badge.edgeWidth > 0 {
                    plate
                        .stroke(
                            color(at: badge.edgeColorIndex),
                            style: StrokeStyle(
                                lineWidth: max(0.75, plateSide * 0.06 * CGFloat(badge.edgeWidth)), lineJoin: .round)
                        )
                        .frame(width: plateSide, height: plateSide)
                        .clipShape(plate)
                }
            }

            BrowserSpaceBadgeTrimView(
                trim: badge.trim,
                weight: badge.trimWeight,
                detail: badge.trimDetail,
                plate: plate,
                plateRect: plateRect,
                color: color(at: badge.trimColorIndex),
                size: size
            )

            BrowserSpaceBadgeChargeView(
                charge: badge.resolvedCharge,
                layout: badge.chargeLayout,
                scale: badge.chargeScale,
                offset: badge.chargeOffset,
                weight: badge.chargeWeight,
                color: color(at: badge.symbolColorIndex),
                size: size
            )
        }
        .frame(width: size, height: size)
        .modifier(BrowserSpaceBadgeRasterization(enabled: rasterizesLayers))
        .modifier(BrowserSpaceBadgeDepthModifier(depth: badge.depth, size: size))
        .accessibilityHidden(true)
    }

    private func color(at index: Int) -> Color {
        let colors = branding.badge.layerColors(spaceColors: branding.colors)
        return colors[(0..<colors.count).contains(index) ? index : 0].color
    }
}

/// The shadow that lifts a badge off its background.
struct BrowserSpaceBadgeDepthModifier: ViewModifier {
    let depth: BadgeDepth
    let size: CGFloat

    func body(content: Content) -> some View {
        switch depth.kind {
        case .none:
            content
        case .soft:
            content.shadow(color: .black.opacity(0.28), radius: size * 0.04, y: size * 0.02)
        case .lifted:
            content.shadow(color: .black.opacity(0.36), radius: size * 0.1, y: size * 0.06)
        }
    }
}
