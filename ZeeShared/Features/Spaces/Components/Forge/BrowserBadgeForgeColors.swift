import SwiftUI

/// A part of the badge that wears a color of its own.
struct BrowserBadgeForgeLayer: Hashable, Identifiable, Sendable {
    // MARK: - Static Variables

    static let field = BrowserBadgeForgeLayer(
        slot: 0, title: "Field", index: \.backplateColorIndex, badgeStep: .shape,
        badgeHint: "Choose a shape to color its field", draws: { $0.backplate != .none })
    static let secondField = BrowserBadgeForgeLayer(
        slot: 1, title: "Second field", index: \.secondaryFieldColorIndex, badgeStep: .field,
        badgeHint: "Divide the field to use a second color",
        draws: { $0.backplate != .none && $0.fieldDivision != .plain })
    static let band = BrowserBadgeForgeLayer(
        slot: 2, title: "Band", index: \.ordinaryColorIndex, badgeStep: .band,
        badgeHint: "Choose a band to color it", draws: { $0.backplate != .none && $0.ordinary != .none })
    static let emblem = BrowserBadgeForgeLayer(
        slot: 3, title: "Emblem", index: \.symbolColorIndex, badgeStep: .emblem,
        badgeHint: "Choose an emblem to color it", draws: { $0.resolvedCharge.kind != .none }, isIconFigure: true)
    static let border = BrowserBadgeForgeLayer(
        slot: 4, title: "Border", index: \.trimColorIndex, badgeStep: .border,
        badgeHint: "Choose a border to color it", draws: { $0.trim != .none })
    static let edge = BrowserBadgeForgeLayer(
        slot: 5, title: "Edge", index: \.edgeColorIndex, badgeStep: .shape,
        badgeHint: "Give the shape an edge to color it",
        draws: { $0.backplate != .none && ($0.edgeWidth > 0 || $0.showsOutline) })

    /// Every layer, in the order its swatches show and its palette entries sit.
    static let all: [BrowserBadgeForgeLayer] = [field, secondField, band, emblem, border, edge]

    // MARK: - Variables

    /// The layer's entry in a badge palette with a color for each layer.
    let slot: Int
    let title: LocalizedStringResource

    /// The badge's index into its colors for this layer.
    let index: WritableKeyPath<SpaceBadge, Int> & Sendable

    /// The step that gives a badge this layer, and what to do there, for a
    /// badge that doesn't draw it.
    let badgeStep: BrowserBadgeStudioStep
    let badgeHint: LocalizedStringResource

    /// Whether a badge draws this layer.
    let draws: @Sendable (SpaceBadge) -> Bool

    /// Whether the layer is the figure an icon draws in place of a badge.
    let isIconFigure: Bool

    var id: Int { slot }

    // MARK: - Initializers

    private init(
        slot: Int, title: LocalizedStringResource, index: WritableKeyPath<SpaceBadge, Int> & Sendable,
        badgeStep: BrowserBadgeStudioStep, badgeHint: LocalizedStringResource,
        draws: @escaping @Sendable (SpaceBadge) -> Bool, isIconFigure: Bool = false
    ) {
        self.slot = slot
        self.title = title
        self.index = index
        self.badgeStep = badgeStep
        self.badgeHint = badgeHint
        self.draws = draws
        self.isIconFigure = isIconFigure
    }

    // MARK: - Actions - Drawing

    /// The layers whose colors `branding`'s stage shows: every layer of a
    /// badge, drawn or not, or an icon's one figure.
    static func shown(by branding: SpaceBranding) -> [BrowserBadgeForgeLayer] {
        branding.iconStyle == .layeredBadge ? all : all.filter(\.isIconFigure)
    }

    /// The layer's name on `branding`'s stage: an icon's figure is its color.
    func title(in branding: SpaceBranding) -> LocalizedStringResource {
        branding.iconStyle == .layeredBadge || !isIconFigure ? title : "Color"
    }

    /// Whether `branding` draws this layer at all. An icon draws only its
    /// figure.
    func isDrawn(by branding: SpaceBranding) -> Bool {
        branding.iconStyle == .layeredBadge ? draws(branding.badge) : isIconFigure
    }

    /// The step that gives `branding` this layer: an icon becomes a zee
    /// under Emblem first.
    func enablingStep(for branding: SpaceBranding) -> BrowserBadgeStudioStep {
        branding.iconStyle == .layeredBadge ? badgeStep : .emblem
    }

    /// What to do to draw this layer in `branding`.
    func enablingHint(for branding: SpaceBranding) -> LocalizedStringResource {
        branding.iconStyle == .layeredBadge ? badgeHint : "Choose Badge under Emblem to color the badge"
    }

    // MARK: - Actions - Identity

    static func == (lhs: BrowserBadgeForgeLayer, rhs: BrowserBadgeForgeLayer) -> Bool {
        lhs.slot == rhs.slot
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(slot)
    }
}

extension SpaceBranding {
    // MARK: - Zee layers

    func forgeColor(of layer: BrowserBadgeForgeLayer) -> BrandColor {
        if iconStyle == .simpleSymbol, layer.isIconFigure { return resolvedSymbolColor }
        let colors = badge.layerColors(spaceColors: self.colors)
        let index = badge[keyPath: layer.index]
        return colors.indices.contains(index) ? colors[index] : colors[0]
    }

    /// Whether every layer already has a palette entry of its own.
    var hasLayeredBadgePalette: Bool {
        badge.palette?.count == BrowserBadgeForgeLayer.all.count
            && BrowserBadgeForgeLayer.all.allSatisfy { badge[keyPath: $0.index] == $0.slot }
    }

    /// Paints one layer. The first time, the badge takes a palette of its own
    /// with an entry for each layer, copied from what each layer wears, so a
    /// layer's color changes only that layer and never the sidebar.
    mutating func setForgeColor(_ color: BrandColor, of layer: BrowserBadgeForgeLayer) {
        hasCustomAppearance = true
        if iconStyle == .simpleSymbol, layer.isIconFigure {
            symbolColor = color
            return
        }
        if !hasLayeredBadgePalette {
            let worn = BrowserBadgeForgeLayer.all.map { layer -> BrandColor in
                let colors = badge.layerColors(spaceColors: self.colors)
                let index = badge[keyPath: layer.index]
                return colors.indices.contains(index) ? colors[index] : colors[0]
            }
            badge.palette = ColorPalette(colors: worn)
            for layer in BrowserBadgeForgeLayer.all { badge[keyPath: layer.index] = layer.slot }
        }
        badge.palette?[layer.slot] = color
    }

    // MARK: - Sidebar colors

    func forgeColor(of role: BrowserSpaceBrandColorRole) -> BrandColor {
        colors.indices.contains(role.slot) ? colors[role.slot] : (colors.last ?? .indigo)
    }

    /// Paints one sidebar color, giving the Space's palette every role up to
    /// this one.
    mutating func setForgeColor(_ color: BrandColor, of role: BrowserSpaceBrandColorRole) {
        hasCustomAppearance = true
        while colors.count <= role.slot { colors.append(colors.last ?? color) }
        colors[role.slot] = color
    }
}

/// The tinctures the templates are made of, in rows as wide as there are
/// templates: the darkest row first, each row running from its neutrals
/// through the hues.
struct BrowserBadgeForgePalette: View {
    // MARK: - Static Variables

    /// The templates hold different numbers of tinctures, so a column for
    /// each left gaps and strays at the foot of the grid. Every tincture once,
    /// in rows of one lightness, fills it.
    private static let rows: [[BrandColor]] = {
        var tinctures: [BrandColor] = []
        for tincture in SpaceHouse.all.flatMap(\.tinctures)
        where !tinctures.contains(where: { $0.matches(tincture) }) {
            tinctures.append(tincture)
        }
        let width = SpaceHouse.all.count
        let byLightness = tinctures.sorted { $0.luminance < $1.luminance }
        return stride(from: 0, to: byLightness.count, by: width).map { start in
            byLightness[start..<min(start + width, byLightness.count)].sorted { $0.precedesInPalette($1) }
        }
    }()

    // MARK: - Variables

    let title: LocalizedStringResource
    var caption: LocalizedStringResource? = nil
    let color: BrandColor
    let select: (BrandColor) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                if let caption {
                    Text(caption).font(.caption).foregroundStyle(.secondary)
                }
            }
            // Each swatch's ring already holds its color clear of the next, so
            // the grid adds only a little room of its own.
            Grid(horizontalSpacing: ZeeSpacing.extraSmall, verticalSpacing: ZeeSpacing.extraSmall) {
                ForEach(Self.rows, id: \.self) { row in
                    GridRow {
                        ForEach(row, id: \.self) { tincture($0) }
                    }
                }
            }
            ColorPicker(
                "Custom",
                selection: Binding(get: { color.color }, set: { select(BrandColor(color: $0)) }),
                supportsOpacity: false
            )
        }
        .padding(14)
        .fixedSize()
    }

    // MARK: - Actions - Drawing

    private func tincture(_ tincture: BrandColor) -> some View {
        ZeeSelectableCard(
            isSelected: tincture.matches(color), accessibilityLabel: Text(tincture.title), density: .swatch
        ) {
            select(tincture)
        } content: {
            Circle()
                .fill(tincture.color)
                .frame(width: 24, height: 24)
                .overlay { Circle().strokeBorder(ZeeColor.subtleBorder) }
        }
        .help(Text(tincture.title))
    }
}
