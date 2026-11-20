import SwiftUI

/// One wave of the Zee mark's landscape: the band under a curving crest, in a
/// unit square, filled with its own gradient. The waves match the app icon's,
/// back to front in Zee's order: coral, red, sun, cyan and ocean.
struct ZeeLandscapeWave: Shape {
    // MARK: - Static Variables

    static let coral = ZeeLandscapeWave(
        start: 480,
        curves: [((240, 420), (420, 470), (620, 380)), ((820, 290), (900, 260), (1024, 250))],
        fill: LinearGradient(
            colors: [ZeeBrandPalette.coral, ZeeBrandPalette.red],
            startPoint: UnitPoint(x: 0.5, y: 0.24), endPoint: UnitPoint(x: 0.5, y: 0.61)))
    static let red = ZeeLandscapeWave(
        start: 600,
        curves: [((260, 540), (440, 590), (640, 500)), ((840, 410), (900, 390), (1024, 380))],
        fill: LinearGradient(
            colors: [ZeeBrandPalette.red, ZeeBrandPalette.redDeep],
            startPoint: UnitPoint(x: 0.5, y: 0.37), endPoint: UnitPoint(x: 0.5, y: 0.72)))
    static let sun = ZeeLandscapeWave(
        start: 690,
        curves: [((280, 640), (460, 680), (660, 600)), ((860, 520), (900, 500), (1024, 490))],
        fill: LinearGradient(
            colors: [ZeeBrandPalette.sun, ZeeBrandPalette.orange],
            startPoint: UnitPoint(x: 0.5, y: 0.48), endPoint: UnitPoint(x: 0.5, y: 0.78)))
    static let cyan = ZeeLandscapeWave(
        start: 760,
        curves: [((260, 700), (480, 760), (700, 680)), ((920, 600), (920, 600), (1024, 590))],
        fill: LinearGradient(
            colors: [ZeeBrandPalette.cyan, ZeeBrandPalette.sky, ZeeBrandPalette.ocean],
            startPoint: UnitPoint(x: 0.5, y: 0.58), endPoint: UnitPoint(x: 0.5, y: 0.94)))
    static let ocean = ZeeLandscapeWave(
        start: 880,
        curves: [((300, 820), (520, 870), (740, 820)), ((960, 770), (940, 760), (1024, 760))],
        fill: LinearGradient(
            colors: [ZeeBrandPalette.ocean, ZeeBrandPalette.deep],
            startPoint: UnitPoint(x: 0.5, y: 0.74), endPoint: UnitPoint(x: 0.5, y: 1)))

    /// Back to front.
    static let all = [coral, red, sun, cyan, ocean]

    // MARK: - Variables

    /// The crest's height at the left edge, on the icon's 1024-point grid.
    let start: CGFloat
    /// Cubic segments of the crest, left to right, as control, control and end
    /// points on the same grid.
    let curves: [((CGFloat, CGFloat), (CGFloat, CGFloat), (CGFloat, CGFloat))]
    let fill: LinearGradient

    // MARK: - Actions - Drawing

    func path(in rect: CGRect) -> Path {
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + rect.width * x / 1024, y: rect.minY + rect.height * y / 1024)
        }
        var path = Path()
        path.move(to: point(0, start))
        for (first, second, end) in curves {
            path.addCurve(
                to: point(end.0, end.1), control1: point(first.0, first.1), control2: point(second.0, second.1))
        }
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
