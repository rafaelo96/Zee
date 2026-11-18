import Foundation

/// The steps of making a badge, in the order arms are composed: the Forge's
/// step bar on the Mac, and the Studio's groups everywhere.
struct BrowserBadgeStudioStep: Hashable, Identifiable, Sendable {
    // MARK: - Types

    /// Each step shows its own choices. ``BrowserBadgeForge`` switches on the
    /// kind to choose that step's concrete sections.
    enum Kinds: Sendable {
        case start
        case shape
        case field
        case band
        case emblem
        case border
        case finish
        case sidebar
    }

    // MARK: - Static Variables

    static let start = BrowserBadgeStudioStep(
        kind: .start, name: "start", title: "Start from", symbol: "sparkles", isBadgeOnly: false,
        summary: { branding in
            SpaceHouse.all.first { $0.isWorn(by: branding) }?.title
                ?? SpaceScheme.all.first { $0.isWorn(by: branding) }?.title ?? "Custom"
        })
    static let shape = BrowserBadgeStudioStep(
        kind: .shape, name: "shape", title: "Shape", symbol: "shield", isBadgeOnly: true,
        summary: { $0.badge.backplate.title })
    static let field = BrowserBadgeStudioStep(
        kind: .field, name: "field", title: "Field", symbol: "square.grid.2x2", isBadgeOnly: true,
        summary: { $0.badge.fieldDivision.title })
    static let band = BrowserBadgeStudioStep(
        kind: .band, name: "band", title: "Band", symbol: "rectangle.center.inset.filled", isBadgeOnly: true,
        summary: { $0.badge.ordinary.title })
    static let emblem = BrowserBadgeStudioStep(
        kind: .emblem, name: "emblem", title: "Emblem", symbol: "seal", isBadgeOnly: false,
        summary: { branding in
            guard branding.iconStyle == .layeredBadge else { return "Icon" }
            let charge = branding.badge.resolvedCharge
            return charge.kind == .heraldic ? (charge.symbol ?? branding.badge.symbol).title : charge.kind.title
        })
    static let border = BrowserBadgeStudioStep(
        kind: .border, name: "border", title: "Border", symbol: "square.dashed", isBadgeOnly: true,
        summary: { $0.badge.trim.title })
    static let finish = BrowserBadgeStudioStep(
        kind: .finish, name: "finish", title: "Finish", symbol: "light.max", isBadgeOnly: true,
        summary: { $0.badge.finish.title })
    static let sidebar = BrowserBadgeStudioStep(
        kind: .sidebar, name: "sidebar", title: "Sidebar", symbol: "sidebar.left", isBadgeOnly: false,
        summary: { $0.themeMode == .gradient ? "Gradient" : $0.bannerPattern.title })

    /// Every step, in the step bar's order.
    static let all: [BrowserBadgeStudioStep] = [start, shape, field, band, emblem, border, finish, sidebar]

    // MARK: - Variables

    let kind: Kinds
    let name: String
    let title: LocalizedStringResource
    let symbol: String

    /// Whether the step shapes only a badge, so an icon has no use for it.
    let isBadgeOnly: Bool

    /// What a branding has chosen at this step, in a word or two.
    let summary: @Sendable (SpaceBranding) -> LocalizedStringResource

    var id: String { name }

    // MARK: - Initializers

    private init(
        kind: Kinds, name: String, title: LocalizedStringResource, symbol: String, isBadgeOnly: Bool,
        summary: @escaping @Sendable (SpaceBranding) -> LocalizedStringResource
    ) {
        self.kind = kind
        self.name = name
        self.title = title
        self.symbol = symbol
        self.isBadgeOnly = isBadgeOnly
        self.summary = summary
    }

    // MARK: - Actions - Identity

    static func == (lhs: BrowserBadgeStudioStep, rhs: BrowserBadgeStudioStep) -> Bool {
        lhs.name == rhs.name
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}
