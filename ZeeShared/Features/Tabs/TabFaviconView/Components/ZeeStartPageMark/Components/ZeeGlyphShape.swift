import SwiftUI

/// Zee's glyph, the app icon's mark: an open dial with an arrow leaving it,
/// drawn from its 183.21 × 151.694 artwork and fitted, centered, in the rect.
struct ZeeGlyphShape: Shape {
    // MARK: - Static Variables

    static let artworkSize = CGSize(width: 183.21, height: 151.694)

    // MARK: - Actions

    func path(in rect: CGRect) -> Path {
        let scale = min(rect.width / Self.artworkSize.width, rect.height / Self.artworkSize.height)
        let origin = CGPoint(
            x: rect.midX - Self.artworkSize.width * scale / 2,
            y: rect.midY - Self.artworkSize.height * scale / 2)
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: origin.x + x * scale, y: origin.y + y * scale)
        }
        var path = Path()
        path.move(to: point(97.223, 0.175))
        path.addCurve(
            to: point(183.034, 97.223), control1: point(147.718, 3.278), control2: point(186.137, 46.728))
        path.addCurve(
            to: point(169.112, 140.458), control1: point(182.056, 113.142), control2: point(177.068, 127.862))
        path.addCurve(
            to: point(166.688, 144.1), control1: point(168.333, 141.693), control2: point(167.524, 142.907))
        path.addCurve(
            to: point(158.081, 147.369), control1: point(164.501, 146.295), control2: point(161.417, 147.574))
        path.addCurve(
            to: point(147.606, 135.523), control1: point(151.917, 146.991), control2: point(147.227, 141.687))
        path.addCurve(
            to: point(148.856, 131.025), control1: point(147.706, 133.9), control2: point(148.147, 132.379))
        path.addCurve(
            to: point(150.147, 129.085), control1: point(149.297, 130.386), control2: point(149.727, 129.739))
        path.addCurve(
            to: point(160.974, 95.867), control1: point(156.337, 119.437), control2: point(160.221, 108.121))
        path.addCurve(
            to: point(95.867, 22.236), control1: point(163.323, 57.558), control2: point(134.175, 24.594))
        path.addLine(to: point(95.859, 22.235))
        path.addCurve(
            to: point(22.236, 87.342), control1: point(57.551, 19.886), control2: point(24.59, 49.034))
        path.addCurve(
            to: point(28.94, 121.691), control1: point(21.481, 99.618), control2: point(23.961, 111.344))
        path.addCurve(
            to: point(31.487, 126.492), control1: point(29.728, 123.327), control2: point(30.577, 124.928))
        path.addLine(to: point(61.799, 105.325))
        path.addLine(to: point(56.044, 97.37))
        path.addCurve(
            to: point(60.611, 85.736), control1: point(52.873, 92.986), control2: point(55.305, 86.792))
        path.addLine(to: point(114.36, 75.042))
        path.addCurve(
            to: point(122.271, 85.978), control1: point(120.589, 73.803), control2: point(125.397, 80.45))
        path.addLine(to: point(95.296, 133.682))
        path.addCurve(
            to: point(82.818, 134.38), control1: point(92.633, 138.392), control2: point(85.989, 138.763))
        path.addLine(to: point(74.756, 123.235))
        path.addLine(to: point(45.531, 143.642))
        path.addLine(to: point(43.042, 145.38))
        path.addLine(to: point(37.47, 149.271))
        path.addCurve(
            to: point(28.374, 151.665), control1: point(34.866, 150.966), control2: point(31.714, 151.87))
        path.addCurve(
            to: point(19.388, 147.959), control1: point(24.915, 151.453), control2: point(21.802, 150.084))
        path.addCurve(
            to: point(16.962, 144.707), control1: point(18.556, 146.894), control2: point(17.747, 145.809))
        path.addCurve(
            to: point(13.317, 139.18), control1: point(15.682, 142.911), control2: point(14.466, 141.067))
        path.addCurve(
            to: point(0.175, 85.987), control1: point(3.92, 123.748), control2: point(-1.017, 105.387))
        path.addCurve(
            to: point(97.223, 0.175), control1: point(3.278, 35.492), control2: point(46.728, -2.927))
        path.closeSubpath()
        return path
    }
}
