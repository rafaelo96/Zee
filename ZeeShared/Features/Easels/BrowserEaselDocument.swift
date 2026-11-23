import CoreGraphics
import Foundation
import SwiftUI

/// An easel's canvas as its note keeps it: text, images, drawing, shapes and
/// arrows placed freely, front to back. The core keeps the document as the
/// note's text, so it is compact JSON in whole points: an easel syncs and
/// exports as its note does, within a note's limits.
struct BrowserEaselDocument: Codable, Equatable, Sendable {
    // MARK: - Static Variables

    static let version = 1

    // MARK: - Variables

    var v = Self.version
    var items: [BrowserEaselItem] = []

    // MARK: - Actions - Coding

    /// The document a note's text holds, or an empty one for an empty or
    /// unreadable text, so an easel always opens.
    static func decode(_ text: String) -> BrowserEaselDocument {
        guard !text.isEmpty, let data = text.data(using: .utf8),
            let document = try? JSONDecoder().decode(BrowserEaselDocument.self, from: data)
        else { return BrowserEaselDocument() }
        return document
    }

    /// The document as the note's text keeps it.
    func encoded() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        guard let data = try? encoder.encode(self) else { return "" }
        return String(decoding: data, as: UTF8.self)
    }

    /// How many bytes the document takes as text.
    var byteCount: Int { encoded().utf8.count }
}

/// One thing on an easel, in canvas points. A text, an image or a shape
/// fills its frame; a stroke's points sit within its frame, from its origin;
/// an arrow runs from its origin to its origin offset by its size, which may
/// be negative.
struct BrowserEaselItem: Codable, Equatable, Identifiable, Sendable {
    // MARK: - Types

    enum Kind: String, Codable, CaseIterable, Sendable {
        case text
        case image
        case stroke
        case rectangle
        case oval
        case arrow
    }

    // MARK: - Variables

    var id: UUID
    var kind: Kind
    var x: Int
    var y: Int
    var w: Int
    var h: Int
    var color: BrowserEaselColor = .ink
    /// The words of a text.
    var text: String?
    /// The image an image shows, which `BrowserNoteImageStore` keeps.
    var image: UUID?
    /// A stroke's points, from the frame's origin, as `[x, y]` pairs.
    var points: [[Int]]?

    // MARK: - Variables - Geometry

    /// The rectangle the item covers, its size made positive.
    var frame: CGRect {
        CGRect(x: x, y: y, width: w, height: h).standardized
    }

    /// The item moved by `offset`.
    func moved(by offset: CGSize) -> BrowserEaselItem {
        var item = self
        item.x += Int(offset.width.rounded())
        item.y += Int(offset.height.rounded())
        return item
    }

    /// The item stretched so its frame is `frame`, its stroke scaled with it.
    func resized(to frame: CGRect) -> BrowserEaselItem {
        var item = self
        let old = self.frame
        let width = max(BrowserEaselMetrics.minimumItemSize, frame.width)
        let height = max(BrowserEaselMetrics.minimumItemSize, frame.height)
        if kind == .stroke, let points, old.width > 0, old.height > 0 {
            let sx = width / old.width
            let sy = height / old.height
            item.points = points.map { [Int((Double($0[0]) * sx).rounded()), Int((Double($0[1]) * sy).rounded())] }
        }
        item.x = Int(frame.minX.rounded())
        item.y = Int(frame.minY.rounded())
        item.w = Int(width.rounded())
        item.h = Int(height.rounded())
        return item
    }

    // MARK: - Initializers

    init(
        id: UUID = UUID(), kind: Kind, frame: CGRect, color: BrowserEaselColor = .ink, text: String? = nil,
        image: UUID? = nil, points: [[Int]]? = nil
    ) {
        self.id = id
        self.kind = kind
        x = Int(frame.minX.rounded())
        y = Int(frame.minY.rounded())
        w = Int(frame.width.rounded())
        h = Int(frame.height.rounded())
        self.color = color
        self.text = text
        self.image = image
        self.points = points
    }

    /// A stroke through `path`, in canvas points, simplified so it keeps
    /// only the points that bend it, and placed in the frame that holds it.
    static func stroke(through path: [CGPoint], color: BrowserEaselColor) -> BrowserEaselItem? {
        let kept = simplified(path, tolerance: BrowserEaselMetrics.strokeTolerance)
        guard kept.count > 1 else { return nil }
        let minX = kept.map(\.x).min() ?? 0
        let minY = kept.map(\.y).min() ?? 0
        let maxX = kept.map(\.x).max() ?? 0
        let maxY = kept.map(\.y).max() ?? 0
        let frame = CGRect(
            x: minX, y: minY, width: max(1, maxX - minX), height: max(1, maxY - minY))
        let points = kept.map { [Int(($0.x - minX).rounded()), Int(($0.y - minY).rounded())] }
        return BrowserEaselItem(kind: .stroke, frame: frame, color: color, points: points)
    }

    /// `points` with those that stray less than `tolerance` from the line
    /// between their neighbours left out (Ramer–Douglas–Peucker).
    static func simplified(_ points: [CGPoint], tolerance: CGFloat) -> [CGPoint] {
        guard points.count > 2, let first = points.first, let last = points.last else { return points }
        var farthest = 0
        var distance: CGFloat = 0
        for index in 1..<(points.count - 1) {
            let candidate = perpendicularDistance(points[index], from: first, to: last)
            if candidate > distance {
                distance = candidate
                farthest = index
            }
        }
        guard distance > tolerance else { return [first, last] }
        let before = simplified(Array(points[...farthest]), tolerance: tolerance)
        let after = simplified(Array(points[farthest...]), tolerance: tolerance)
        return before.dropLast() + after
    }

    private static func perpendicularDistance(_ point: CGPoint, from start: CGPoint, to end: CGPoint) -> CGFloat {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let length = (dx * dx + dy * dy).squareRoot()
        guard length > 0 else { return hypot(point.x - start.x, point.y - start.y) }
        return abs(dy * point.x - dx * point.y + end.x * start.y - end.y * start.x) / length
    }
}

/// The colors an easel draws with: Zee's ink and palette, by name, so a
/// document reads the same in light and dark.
enum BrowserEaselColor: String, Codable, CaseIterable, Identifiable, Sendable {
    case ink
    case ocean
    case sky
    case cyan
    case sun
    case orange
    case coral
    case red

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .ink: ZeeBrandTheme.textDisplay
        case .ocean: ZeeBrandPalette.ocean
        case .sky: ZeeBrandPalette.sky
        case .cyan: ZeeBrandPalette.cyan
        case .sun: ZeeBrandPalette.sun
        case .orange: ZeeBrandPalette.orange
        case .coral: ZeeBrandPalette.coral
        case .red: ZeeBrandPalette.red
        }
    }

    var title: LocalizedStringResource {
        switch self {
        case .ink: "Ink"
        case .ocean: "Ocean"
        case .sky: "Sky Blue"
        case .cyan: "Cyan"
        case .sun: "Sun"
        case .orange: "Orange"
        case .coral: "Coral"
        case .red: "Red"
        }
    }
}

extension BrowserEaselDocument {
    /// The size an image is placed at: its own, no wider or taller than the
    /// canvas shows it comfortably.
    static func placedSize(for size: CGSize) -> CGSize {
        guard size.width > 0, size.height > 0 else { return CGSize(width: 320, height: 240) }
        let scale = min(1, BrowserEaselMetrics.maximumPlacedImage / max(size.width, size.height))
        return CGSize(width: size.width * scale, height: size.height * scale)
    }

    /// Where something new goes when nothing chose: under everything else,
    /// at the left margin.
    var nextFreeOrigin: CGPoint {
        let bottom = items.map { $0.frame.maxY }.max() ?? 0
        return CGPoint(x: BrowserEaselMetrics.margin, y: bottom + BrowserEaselMetrics.margin)
    }
}

enum BrowserEaselMetrics {
    /// How far a stroke's point may stray from the line before it is kept.
    static let strokeTolerance: CGFloat = 1.5
    /// The smallest an item is made.
    static let minimumItemSize: CGFloat = 12
    /// How large the canvas is.
    static let canvasSize = CGSize(width: 4000, height: 3000)
    static let strokeWidth: CGFloat = 3
    static let textSize: CGFloat = 17
    static let newTextSize = CGSize(width: 240, height: 44)
    static let handleSize: CGFloat = 10
    /// The most an image is placed at, across its longer side.
    static let maximumPlacedImage: CGFloat = 480
    /// The room left between something new and what is already there.
    static let margin: CGFloat = 40
}
