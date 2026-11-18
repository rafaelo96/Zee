import CoreGraphics

/// The single field treatment: one radius, one hairline, and one focus ring.
enum ZeeFieldMetrics {
    static let cornerRadius: CGFloat = ZeeRadius.control
    static let height: CGFloat = 40
    static let horizontalPadding: CGFloat = ZeeSpacing.medium
    static let borderWidth: CGFloat = ZeeLayout.hairline
    static let focusRingWidth: CGFloat = ZeeLayout.focusRing
    static let focusRingOpacity = 0.32
}
