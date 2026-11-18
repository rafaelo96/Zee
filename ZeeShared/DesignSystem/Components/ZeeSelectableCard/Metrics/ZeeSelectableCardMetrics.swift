import CoreGraphics

/// Selection-card measurements shared by every density.
enum ZeeSelectableCardMetrics {
    static let selectedBorderWidth: CGFloat = ZeeLayout.pinnedAccentBorderWidth
    static let contentSpacing: CGFloat = ZeeSpacing.medium
    static let selectedFillOpacity = ZeeButtonMetrics.tintRestFill
    static let checkmarkSize: CGFloat = 20
    static let checkmarkSymbol = "checkmark.circle.fill"
}
