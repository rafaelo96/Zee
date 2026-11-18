import CoreGraphics

/// Shared measurements for Space chips and their rail.
enum ZeeSpaceChipMetrics {
    static let baseHeight: CGFloat = 42
    static var height: CGFloat { max(baseHeight, ZeeLayout.minimumHitTarget) }
    static let cornerRadius: CGFloat = ZeeRadius.control
    static let horizontalPadding: CGFloat = ZeeSpacing.medium
    static let contentSpacing: CGFloat = ZeeSpacing.small
    static let railSpacing: CGFloat = ZeeSpacing.small
    static let iconSize: CGFloat = 24
    static let menuIconSize: CGFloat = 20
    static var lockSize: CGFloat { max(5, iconSize * 0.24) }
    static let selectedStrokeWidth: CGFloat = ZeeButtonMetrics.prominentStrokeWidth
    static let restingStrokeWidth: CGFloat = ZeeButtonMetrics.quietStrokeWidth
    static let selectedStrokeOpacity = 0.72
    static let dashPattern: [CGFloat] = [6, 5]
}
