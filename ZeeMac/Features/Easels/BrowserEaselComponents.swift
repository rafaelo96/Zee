import AppKit
import SwiftUI

/// The easel's bar: its title, its tools, the color it draws with, an image
/// from a file, and its menu.
struct BrowserEaselToolbar: View {
    @Binding var title: String
    @Binding var tool: BrowserEaselTool
    @Binding var color: BrowserEaselColor
    let hasSelection: Bool
    let importImage: () -> Void
    let deleteSelection: () -> Void
    let deleteEasel: (() -> Void)?
    let recolorSelection: (BrowserEaselColor) -> Void

    var body: some View {
        HStack(spacing: ZeeSpacing.small) {
            TextField("Title", text: $title)
                .textFieldStyle(.plain)
                .font(ZeeTypography.display(BrowserEaselToolbarMetrics.titleSize))
                .foregroundStyle(ZeeBrandTheme.textDisplay)
                .frame(maxWidth: BrowserEaselToolbarMetrics.titleWidth, alignment: .leading)
                .accessibilityIdentifier("easel-title-field")

            Spacer(minLength: ZeeSpacing.small)

            HStack(spacing: ZeeSpacing.extraExtraSmall) {
                ForEach(BrowserEaselTool.allCases) { candidate in
                    Button {
                        tool = candidate
                    } label: {
                        Label {
                            Text(candidate.title)
                        } icon: {
                            Image(systemName: candidate.symbol)
                        }
                    }
                    // The chosen tool keeps its surface, so the bar says which draws.
                    .buttonStyle(ZeeChromeButtonStyle(showsRestingFill: tool == candidate))
                    .foregroundStyle(tool == candidate ? ZeeBrandTheme.accent : ZeeBrandTheme.textSecondary)
                    .help(Text(candidate.title))
                    .accessibilityAddTraits(tool == candidate ? .isSelected : [])
                }
            }

            colorMenu

            Button("Add Image…", systemImage: "photo.badge.plus", action: importImage)
                .help("Add Image…")
            Button("Delete Selection", systemImage: "trash", action: deleteSelection)
                .disabled(!hasSelection)
                .help("Delete Selection")

            if let deleteEasel {
                Menu {
                    Group {
                        Button("Delete Easel…", systemImage: "trash", role: .destructive, action: deleteEasel)
                    }
                    .zeeMenuActionLabelStyle()
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .fixedSize()
                .help("Easel Actions")
                .accessibilityLabel("Easel actions")
            }
        }
        .labelStyle(.iconOnly)
        .buttonStyle(ZeeChromeButtonStyle())
        .padding(.horizontal, ZeeSpacing.large)
        .padding(.vertical, ZeeSpacing.small)
    }

    private var colorMenu: some View {
        Menu {
            Group {
                ForEach(BrowserEaselColor.allCases) { candidate in
                    Button {
                        color = candidate
                        if hasSelection { recolorSelection(candidate) }
                    } label: {
                        Label {
                            Text(candidate.title)
                        } icon: {
                            Image(systemName: candidate == color ? "checkmark.circle.fill" : "circle.fill")
                        }
                    }
                    .tint(candidate.color)
                }
            }
            .zeeMenuActionLabelStyle()
        } label: {
            Image(systemName: "circle.fill")
                .foregroundStyle(color.color)
                .font(.system(size: BrowserEaselToolbarMetrics.swatchSize))
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .help("Color")
        .accessibilityLabel(Text("Color: \(String(localized: color.title))"))
    }
}

enum BrowserEaselToolbarMetrics {
    static let titleSize: CGFloat = 22
    static let titleWidth: CGFloat = 320
    static let swatchSize: CGFloat = 18
}

/// The canvas's ground: a quiet grid of dots.
struct BrowserEaselGrid: View {
    var body: some View {
        Canvas { context, size in
            let spacing = BrowserEaselViewMetrics.gridSpacing
            let dot = Path(ellipseIn: CGRect(x: -1, y: -1, width: 2, height: 2))
            var x = spacing
            while x < size.width {
                var y = spacing
                while y < size.height {
                    context.fill(dot.offsetBy(dx: x, dy: y), with: .color(ZeeBrandTheme.line))
                    y += spacing
                }
                x += spacing
            }
        }
    }
}

/// One item drawn in its frame.
struct BrowserEaselItemView: View {
    let item: BrowserEaselItem
    let isSelected: Bool
    let isEditing: Bool
    let image: NSImage?
    @Binding var text: String
    let focus: FocusState<BrowserEaselFocus?>.Binding
    let endEditing: () -> Void

    init(
        item: BrowserEaselItem, isSelected: Bool, isEditing: Bool, image: NSImage?, text: Binding<String>,
        focus: FocusState<BrowserEaselFocus?>.Binding, endEditing: @escaping () -> Void
    ) {
        self.item = item
        self.isSelected = isSelected
        self.isEditing = isEditing
        self.image = image
        _text = text
        self.focus = focus
        self.endEditing = endEditing
    }

    var body: some View {
        switch item.kind {
        case .text:
            textItem
        case .image:
            imageItem
        case .stroke:
            BrowserEaselStrokeShape(points: item.points ?? [])
                .stroke(item.color.color, style: strokeStyle)
                .contentShape(BrowserEaselStrokeShape(points: item.points ?? []).stroke(lineWidth: 12))
        case .rectangle:
            RoundedRectangle(cornerRadius: 4)
                .stroke(item.color.color, style: strokeStyle)
                .contentShape(.rect)
        case .oval:
            Ellipse()
                .stroke(item.color.color, style: strokeStyle)
                .contentShape(Ellipse())
        case .arrow:
            BrowserEaselArrowShape(start: arrowStart, end: arrowEnd)
                .stroke(item.color.color, style: strokeStyle)
                .contentShape(BrowserEaselArrowShape(start: arrowStart, end: arrowEnd).stroke(lineWidth: 14))
        }
    }

    private var strokeStyle: StrokeStyle {
        StrokeStyle(lineWidth: BrowserEaselMetrics.strokeWidth, lineCap: .round, lineJoin: .round)
    }

    /// Where an arrow starts and ends within its frame, which may have run
    /// up or left from where it was drawn.
    private var arrowStart: CGPoint {
        CGPoint(x: item.w < 0 ? -CGFloat(item.w) : 0, y: item.h < 0 ? -CGFloat(item.h) : 0)
    }

    private var arrowEnd: CGPoint {
        CGPoint(x: item.w < 0 ? 0 : CGFloat(item.w), y: item.h < 0 ? 0 : CGFloat(item.h))
    }

    @ViewBuilder
    private var textItem: some View {
        if isEditing {
            TextField("Text", text: $text, axis: .vertical)
                .textFieldStyle(.plain)
                .font(ZeeTypography.sans(BrowserEaselMetrics.textSize))
                .foregroundStyle(item.color.color)
                .focused(focus, equals: .text(item.id))
                .onSubmit(endEditing)
                .padding(ZeeSpacing.extraSmall)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        } else {
            Text(text)
                .font(ZeeTypography.sans(BrowserEaselMetrics.textSize))
                .foregroundStyle(item.color.color)
                .padding(ZeeSpacing.extraSmall)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .contentShape(.rect)
        }
    }

    @ViewBuilder
    private var imageItem: some View {
        if let image {
            Image(nsImage: image)
                .resizable()
                .clipShape(.rect(cornerRadius: 6))
        } else {
            RoundedRectangle(cornerRadius: 6)
                .fill(ZeeBrandTheme.quietFill)
                .overlay {
                    Label("This image is on another device", systemImage: "photo")
                        .font(.caption)
                        .foregroundStyle(ZeeBrandTheme.textSecondary)
                        .padding(ZeeSpacing.small)
                }
        }
    }
}

/// A stroke through points within its frame.
struct BrowserEaselStrokeShape: Shape {
    let points: [[Int]]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let located = points.compactMap { $0.count == 2 ? CGPoint(x: $0[0], y: $0[1]) : nil }
        guard let first = located.first else { return path }
        path.move(to: first)
        for point in located.dropFirst() { path.addLine(to: point) }
        return path
    }
}

/// A line from `start` to `end` with a head at `end`.
struct BrowserEaselArrowShape: Shape {
    let start: CGPoint
    let end: CGPoint

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: start)
        path.addLine(to: end)
        let angle = atan2(end.y - start.y, end.x - start.x)
        let length: CGFloat = 14
        for side in [CGFloat.pi * 0.82, -CGFloat.pi * 0.82] {
            path.move(to: end)
            path.addLine(to: CGPoint(x: end.x + cos(angle + side) * length, y: end.y + sin(angle + side) * length))
        }
        return path
    }
}

/// The selected item's outline and the handle that resizes it from its
/// lower right corner.
struct BrowserEaselSelection: View {
    let frame: CGRect
    let resize: (CGRect) -> Void
    /// Says the resize ended, so it undoes as one change.
    let finish: () -> Void

    @State private var startFrame: CGRect?

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(ZeeBrandTheme.accent, style: StrokeStyle(lineWidth: 1.5, dash: [5, 3]))
                .frame(width: frame.width + 8, height: frame.height + 8)
                .offset(x: frame.minX - 4, y: frame.minY - 4)
                .allowsHitTesting(false)
            Circle()
                .fill(ZeeBrandTheme.accent)
                .overlay { Circle().strokeBorder(.white, lineWidth: 1.5) }
                .frame(width: BrowserEaselMetrics.handleSize, height: BrowserEaselMetrics.handleSize)
                .offset(
                    x: frame.maxX + 4 - BrowserEaselMetrics.handleSize / 2,
                    y: frame.maxY + 4 - BrowserEaselMetrics.handleSize / 2
                )
                .gesture(
                    DragGesture(coordinateSpace: .named(BrowserEaselViewMetrics.canvasSpace))
                        .onChanged { value in
                            let origin = startFrame ?? frame
                            if startFrame == nil { startFrame = frame }
                            resize(
                                CGRect(
                                    x: origin.minX, y: origin.minY, width: origin.width + value.translation.width,
                                    height: origin.height + value.translation.height))
                        }
                        .onEnded { _ in
                            startFrame = nil
                            finish()
                        }
                )
                .onHover { inside in
                    if inside {
                        NSCursor.frameResize(position: .bottomRight, directions: .all).push()
                    } else {
                        NSCursor.pop()
                    }
                }
                .accessibilityLabel("Resize")
        }
    }
}

/// What the pointer is drawing, before it lets go.
struct BrowserEaselDraftView: View {
    let draft: BrowserEaselDraft
    let color: BrowserEaselColor

    var body: some View {
        let style = StrokeStyle(lineWidth: BrowserEaselMetrics.strokeWidth, lineCap: .round, lineJoin: .round)
        switch draft.tool {
        case .draw:
            Path { path in
                guard let first = draft.points.first else { return }
                path.move(to: first)
                for point in draft.points.dropFirst() { path.addLine(to: point) }
            }
            .stroke(color.color, style: style)
        case .rectangle:
            RoundedRectangle(cornerRadius: 4)
                .stroke(color.color, style: style)
                .frame(width: draft.frame.width, height: draft.frame.height)
                .offset(x: draft.frame.minX, y: draft.frame.minY)
        case .oval:
            Ellipse()
                .stroke(color.color, style: style)
                .frame(width: draft.frame.width, height: draft.frame.height)
                .offset(x: draft.frame.minX, y: draft.frame.minY)
        case .arrow:
            BrowserEaselArrowShape(start: draft.start, end: draft.end)
                .stroke(color.color, style: style)
        case .select, .text:
            EmptyView()
        }
    }
}

/// The images an easel shows, read from their files once.
@MainActor
@Observable
final class BrowserEaselImageCache {
    @ObservationIgnored private var loaded: [UUID: NSImage] = [:]
    @ObservationIgnored private var missing: Set<UUID> = []

    func image(_ id: UUID, in store: BrowserNoteImageStore) -> NSImage? {
        if let image = loaded[id] { return image }
        guard !missing.contains(id) else { return nil }
        guard let url = store.existingFileURL(for: id), let image = NSImage(contentsOf: url) else {
            missing.insert(id)
            return nil
        }
        loaded[id] = image
        return image
    }

    /// `image` as PNG data, as the image store keeps it.
    static func png(from image: NSImage) -> Data? {
        guard let tiff = image.tiffRepresentation, let bitmap = NSBitmapImageRep(data: tiff) else { return nil }
        return bitmap.representation(using: .png, properties: [:])
    }
}
