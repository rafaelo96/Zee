import SwiftUI

enum ZeeStartPageMarkMetrics {
    static let cornerRadiusRatio: CGFloat = 0.22
    static let glyphWeightRatio: CGFloat = 0.1
    static let borderOpacity: CGFloat = 0.14
    static let borderWidth: CGFloat = 0.5
    /// The sky, deep blue at the left into sky blue at the top right, as the icon's.
    static let skyColors = [ZeeBrandPalette.deep, ZeeBrandPalette.sky]
    static let skyStart = UnitPoint(x: 0, y: 0.6)
    static let skyEnd = UnitPoint(x: 1, y: 0)
    static let glyphShadowOpacity = 0.25
}
