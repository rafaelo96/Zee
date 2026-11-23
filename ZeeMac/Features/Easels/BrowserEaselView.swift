import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// An easel as its tab shows it: a title, the tools, and a free canvas of
/// text, images, drawing, shapes and arrows. Each pause in a change saves the
/// canvas through the core as the easel's document; leaving the tab saves
/// what is left. Images the person pastes, drops or picks are kept on this Mac.
struct BrowserEaselView: View {
    let note: Note
    let save: (_ title: String, _ body: String) -> Void
    var delete: (() -> Void)?
    let images: BrowserNoteImageStore

    @State private var title: String
    @State private var document: BrowserEaselDocument
    @State private var tool = BrowserEaselTool.select
    @State private var color = BrowserEaselColor.ink
    @State private var selection: UUID?
    @State private var editingText: UUID?
    @State private var draft: BrowserEaselDraft?
    /// The item as it stood when the pointer began moving it, which each step
    /// of the drag moves from.
    @State private var moving: BrowserEaselItem?
    @State private var isConfirmingDelete = false
    @State private var isImportingImage = false
    @State private var imageCache = BrowserEaselImageCache()
    @FocusState private var focus: BrowserEaselFocus?

    init(
        note: Note, save: @escaping (_ title: String, _ body: String) -> Void, delete: (() -> Void)?,
        images: BrowserNoteImageStore
    ) {
        self.note = note
        self.save = save
        self.delete = delete
        self.images = images
        _title = State(initialValue: note.title)
        _document = State(initialValue: BrowserEaselDocument.decode(note.body))
    }

    var body: some View {
        VStack(spacing: 0) {
            BrowserEaselToolbar(
                title: $title, tool: $tool, color: $color, hasSelection: selection != nil,
                importImage: { isImportingImage = true }, deleteSelection: deleteSelection,
                deleteEasel: delete == nil ? nil : { isConfirmingDelete = true },
                recolorSelection: recolorSelection)
            Divider()
            ScrollView([.horizontal, .vertical]) {
                canvas
            }
            .background(ZeeBrandTheme.canvas)
        }
        .background(ZeeBrandTheme.canvas)
        .task(id: Snapshot(title: title, document: document)) {
            try? await Task.sleep(for: BrowserEaselViewMetrics.saveDelay)
            guard !Task.isCancelled else { return }
            saveIfChanged()
        }
        .onDisappear(perform: saveIfChanged)
        // Choosing a drawing tool ends what is being edited and clears the
        // selection; the select tool the canvas returns to after placing a
        // text leaves that text being edited.
        .onChange(of: tool) { _, chosen in
            guard chosen != .select else { return }
            if let editing = editingText { endEditing(editing) }
            selection = nil
        }
        .fileImporter(isPresented: $isImportingImage, allowedContentTypes: [.image]) { result in
            guard case .success(let url) = result else { return }
            let access = url.startAccessingSecurityScopedResource()
            defer { if access { url.stopAccessingSecurityScopedResource() } }
            if let image = NSImage(contentsOf: url) { add(image, at: nil) }
        }
        .confirmationDialog("Delete this easel?", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
            Button("Delete Easel", role: .destructive) { delete?() }
        } message: {
            Text("The easel is deleted on every device that syncs this Space. This can’t be undone.")
        }
    }

    // MARK: - Canvas

    private var canvas: some View {
        ZStack(alignment: .topLeading) {
            BrowserEaselGrid()
                .contentShape(.rect)
                .gesture(canvasGesture)
                .onTapGesture { location in tapCanvas(at: location) }

            ForEach(document.items) { item in
                BrowserEaselItemView(
                    item: item, isSelected: selection == item.id, isEditing: editingText == item.id,
                    image: item.image.flatMap { imageCache.image($0, in: images) },
                    text: textBinding(for: item.id), focus: $focus, endEditing: { endEditing(item.id) }
                )
                .frame(width: item.frame.width, height: item.frame.height)
                .offset(x: item.frame.minX, y: item.frame.minY)
                .allowsHitTesting(tool == .select)
                .onTapGesture(count: 2) { beginEditing(item) }
                .onTapGesture { select(item.id) }
                .gesture(moveGesture(for: item))
            }

            if let id = selection, let item = document.items.first(where: { $0.id == id }), editingText == nil {
                BrowserEaselSelection(frame: item.frame, resize: { resize(id, to: $0) })
            }

            if let draft {
                BrowserEaselDraftView(draft: draft, color: color)
                    .allowsHitTesting(false)
            }
        }
        .frame(
            width: BrowserEaselMetrics.canvasSize.width, height: BrowserEaselMetrics.canvasSize.height,
            alignment: .topLeading
        )
        .coordinateSpace(.named(BrowserEaselViewMetrics.canvasSpace))
        .focusable()
        .focused($focus, equals: .canvas)
        .focusEffectDisabled()
        .onDeleteCommand(perform: deleteSelection)
        .onPasteCommand(of: [.image, .png, .tiff, .fileURL]) { providers in
            load(providers, at: nil)
        }
        .onDrop(of: [.image, .fileURL], isTargeted: nil) { providers, location in
            load(providers, at: location)
            return true
        }
        .onExitCommand {
            selection = nil
            editingText = nil
        }
    }

    /// Drawing and shapes follow the pointer from where it went down.
    private var canvasGesture: some Gesture {
        DragGesture(minimumDistance: 1, coordinateSpace: .named(BrowserEaselViewMetrics.canvasSpace))
            .onChanged { value in
                guard tool.drawsByDragging else { return }
                if tool == .draw {
                    var points = draft?.points ?? [value.startLocation]
                    points.append(value.location)
                    draft = BrowserEaselDraft(
                        tool: tool, start: value.startLocation, end: value.location, points: points)
                } else {
                    draft = BrowserEaselDraft(tool: tool, start: value.startLocation, end: value.location, points: [])
                }
            }
            .onEnded { _ in
                guard let finished = draft else { return }
                draft = nil
                if let item = finished.item(color: color) {
                    document.items.append(item)
                    selection = nil
                }
            }
    }

    private func moveGesture(for item: BrowserEaselItem) -> some Gesture {
        DragGesture(minimumDistance: 2, coordinateSpace: .named(BrowserEaselViewMetrics.canvasSpace))
            .onChanged { value in
                guard tool == .select, editingText != item.id else { return }
                let start = moving?.id == item.id ? moving ?? item : item
                if moving?.id != item.id { moving = item }
                selection = item.id
                update(item.id) { _ in start.moved(by: value.translation) }
            }
            .onEnded { _ in moving = nil }
    }

    // MARK: - Actions - Items

    private func tapCanvas(at location: CGPoint) {
        if let editing = editingText { endEditing(editing) }
        guard tool == .text else {
            selection = nil
            focus = .canvas
            return
        }
        let frame = CGRect(origin: location, size: BrowserEaselMetrics.newTextSize)
        let item = BrowserEaselItem(kind: .text, frame: frame, color: color, text: "")
        document.items.append(item)
        tool = .select
        beginEditing(item)
    }

    private func select(_ id: UUID) {
        if let editing = editingText, editing != id { endEditing(editing) }
        selection = id
        if editingText != id { focus = .canvas }
    }

    private func beginEditing(_ item: BrowserEaselItem) {
        guard item.kind == .text else { return }
        selection = item.id
        editingText = item.id
        // The field appears with this change, so focus moves on the next turn.
        DispatchQueue.main.async { focus = .text(item.id) }
    }

    /// Ends editing `id`, removing a text left empty.
    private func endEditing(_ id: UUID) {
        if editingText == id { editingText = nil }
        if let item = document.items.first(where: { $0.id == id }), item.kind == .text,
            (item.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        {
            document.items.removeAll { $0.id == id }
            if selection == id { selection = nil }
        }
        if focus == .text(id) { focus = .canvas }
    }

    private func textBinding(for id: UUID) -> Binding<String> {
        Binding(
            get: { document.items.first(where: { $0.id == id })?.text ?? "" },
            set: { text in
                update(id) { item in
                    var edited = item
                    edited.text = text
                    return edited
                }
            })
    }

    private func update(_ id: UUID, _ change: (BrowserEaselItem) -> BrowserEaselItem) {
        guard let index = document.items.firstIndex(where: { $0.id == id }) else { return }
        document.items[index] = change(document.items[index])
    }

    private func resize(_ id: UUID, to frame: CGRect) {
        update(id) { $0.resized(to: frame) }
    }

    private func deleteSelection() {
        guard editingText == nil, let id = selection else { return }
        document.items.removeAll { $0.id == id }
        selection = nil
    }

    private func recolorSelection(_ color: BrowserEaselColor) {
        guard let id = selection else { return }
        update(id) { item in
            var edited = item
            edited.color = color
            return edited
        }
    }

    // MARK: - Actions - Images

    /// Loads the images or image files `providers` carry, placing them at
    /// `location`, or where the canvas has room.
    private func load(_ providers: [NSItemProvider], at location: CGPoint?) {
        for provider in providers {
            if provider.canLoadObject(ofClass: NSImage.self) {
                _ = provider.loadObject(ofClass: NSImage.self) { object, _ in
                    guard let image = object as? NSImage else { return }
                    Task { @MainActor in add(image, at: location) }
                }
            } else if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    guard let url, let image = NSImage(contentsOf: url) else { return }
                    Task { @MainActor in add(image, at: location) }
                }
            }
        }
    }

    /// Keeps `image` on this Mac and places it on the canvas.
    private func add(_ image: NSImage, at location: CGPoint?) {
        guard let png = BrowserEaselImageCache.png(from: image), let id = images.save(png: png) else {
            BrowserNoticeCenter.shared.post(.failure(String(localized: "That image couldn’t be added.")))
            return
        }
        let size = BrowserEaselDocument.placedSize(for: image.size)
        let origin = location ?? document.nextFreeOrigin
        let item = BrowserEaselItem(kind: .image, frame: CGRect(origin: origin, size: size), image: id)
        document.items.append(item)
        tool = .select
        selection = item.id
    }

    // MARK: - Actions - Saving

    private func saveIfChanged() {
        let body = document.items.isEmpty && note.body.isEmpty ? "" : document.encoded()
        guard title != note.title || body != note.body else { return }
        guard body.utf8.count <= Note.maximumBodyBytes else {
            BrowserNoticeCenter.shared.post(
                .failure(String(localized: "This easel is full. Remove something to keep your latest change.")))
            return
        }
        save(title, body)
    }

    private struct Snapshot: Equatable {
        let title: String
        let document: BrowserEaselDocument
    }
}

// MARK: - Focus

/// What has the keyboard in an easel: the canvas, for deleting and pasting,
/// or the text being edited.
enum BrowserEaselFocus: Hashable {
    case canvas
    case text(UUID)
}

// MARK: - Tools

enum BrowserEaselTool: String, CaseIterable, Identifiable {
    case select
    case text
    case draw
    case rectangle
    case oval
    case arrow

    var id: String { rawValue }

    var title: LocalizedStringResource {
        switch self {
        case .select: "Select"
        case .text: "Text"
        case .draw: "Draw"
        case .rectangle: "Rectangle"
        case .oval: "Oval"
        case .arrow: "Arrow"
        }
    }

    var symbol: String {
        switch self {
        case .select: "cursorarrow"
        case .text: "textformat"
        case .draw: "pencil.tip"
        case .rectangle: "rectangle"
        case .oval: "oval"
        case .arrow: "arrow.up.right"
        }
    }

    /// Whether the tool makes its item by dragging across the canvas.
    var drawsByDragging: Bool {
        self == .draw || self == .rectangle || self == .oval || self == .arrow
    }
}

/// What the pointer is drawing before it lets go.
struct BrowserEaselDraft {
    let tool: BrowserEaselTool
    let start: CGPoint
    let end: CGPoint
    let points: [CGPoint]

    var frame: CGRect {
        CGRect(x: start.x, y: start.y, width: end.x - start.x, height: end.y - start.y).standardized
    }

    /// The item the drag made, or nil for one too small to keep.
    func item(color: BrowserEaselColor) -> BrowserEaselItem? {
        switch tool {
        case .draw:
            return BrowserEaselItem.stroke(through: points, color: color)
        case .arrow:
            guard hypot(end.x - start.x, end.y - start.y) >= BrowserEaselMetrics.minimumItemSize else { return nil }
            var item = BrowserEaselItem(kind: .arrow, frame: .zero, color: color)
            item.x = Int(start.x.rounded())
            item.y = Int(start.y.rounded())
            item.w = Int((end.x - start.x).rounded())
            item.h = Int((end.y - start.y).rounded())
            return item
        case .rectangle, .oval:
            let minimum = BrowserEaselMetrics.minimumItemSize
            guard frame.width >= minimum, frame.height >= minimum
            else { return nil }
            return BrowserEaselItem(kind: tool == .oval ? .oval : .rectangle, frame: frame, color: color)
        case .select, .text:
            return nil
        }
    }
}

enum BrowserEaselViewMetrics {
    static let canvasSpace = "easel-canvas"
    static let saveDelay: Duration = .milliseconds(600)
    static let gridSpacing: CGFloat = 24
}
