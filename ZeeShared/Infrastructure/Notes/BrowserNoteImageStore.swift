import Foundation

/// The images a note shows, kept as files on this Mac beside the session.
///
/// A note's text names an image by its identity (`zee-note-image:<id>`), so
/// the note syncs as plain text within its Space's record while the image
/// itself stays on the device that captured it; another device shows that
/// the image lives elsewhere. A launch that keeps its session in memory keeps
/// its images in a temporary folder of its own, which nothing else reads.
struct BrowserNoteImageStore: Sendable {
    // MARK: - Static Variables

    static let directoryName = "NoteImages"
    static let scheme = "zee-note-image"
    /// The most bytes one image keeps.
    static let maximumBytes = 8 * 1024 * 1024

    // MARK: - Variables

    let rootDirectory: URL

    // MARK: - Initializers

    /// The store beside the session in `storageDirectory`, or in a temporary
    /// folder of this process when the session lives in memory.
    init(storageDirectory: URL?) {
        rootDirectory =
            storageDirectory?.appendingPathComponent(Self.directoryName, isDirectory: true)
            ?? FileManager.default.temporaryDirectory
            .appendingPathComponent("\(ProductIdentity.storageDirectoryName)-\(Self.directoryName)", isDirectory: true)
            .appendingPathComponent(String(ProcessInfo.processInfo.processIdentifier), isDirectory: true)
    }

    // MARK: - Actions - Files

    /// Keeps `png` and answers its identity, or nil when it is too large or
    /// cannot be written.
    func save(png: Data) -> UUID? {
        guard !png.isEmpty, png.count <= Self.maximumBytes else { return nil }
        let id = UUID()
        do {
            try FileManager.default.createDirectory(at: rootDirectory, withIntermediateDirectories: true)
            try png.write(to: fileURL(for: id), options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
            return id
        } catch {
            return nil
        }
    }

    /// The file of the image `id`, when this device holds it.
    func existingFileURL(for id: UUID) -> URL? {
        let url = fileURL(for: id)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    /// How a note's Markdown names the image `id`.
    static func markdown(for id: UUID, description: String) -> String {
        let alt = description.replacingOccurrences(of: "]", with: "").replacingOccurrences(of: "\n", with: " ")
        return "![\(alt)](\(scheme):\(id.uuidString))"
    }

    private func fileURL(for id: UUID) -> URL {
        rootDirectory.appendingPathComponent(id.uuidString).appendingPathExtension("png")
    }
}
