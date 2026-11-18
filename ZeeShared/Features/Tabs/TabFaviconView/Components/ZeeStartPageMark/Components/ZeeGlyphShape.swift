import SwiftUI

/// The "Z" of the Zee mark, drawn as a single stroke path in a unit square.
struct ZeeGlyphShape: Shape {
    func path(in rect: CGRect) -> Path {
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + rect.width * x, y: rect.minY + rect.height * y)
        }
        var path = Path()
        path.move(to: point(0.32, 0.30))
        path.addLine(to: point(0.68, 0.30))
        path.addLine(to: point(0.32, 0.70))
        path.addLine(to: point(0.68, 0.70))
        return path
    }
}
