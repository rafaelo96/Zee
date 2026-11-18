import SwiftUI

/// The material every sidebar layer above the base UI is drawn with: pinned
/// tiles, the selected tab, folders, Split View groups, the address field, the
/// extension strip and widget cards.
///
/// One choice for the whole device, made in Look and Feel and read where each
/// layer draws it, from ``BrowserDeviceAppearanceStore``, so changing it never
/// changes a window's environment. Reduce Transparency renders every member
/// opaque on its own.
struct ZeeSurfaceMaterial: Hashable, Sendable {
    // MARK: - Static Variables

    static let ultraThin = ZeeSurfaceMaterial(
        name: "ultraThin", title: "Ultra Thin", material: .ultraThinMaterial)
    static let thin = ZeeSurfaceMaterial(name: "thin", title: "Thin", material: .thinMaterial)
    static let regular = ZeeSurfaceMaterial(name: "regular", title: "Regular", material: .regularMaterial)
    static let thick = ZeeSurfaceMaterial(name: "thick", title: "Thick", material: .thickMaterial)
    static let ultraThick = ZeeSurfaceMaterial(
        name: "ultraThick", title: "Ultra Thick", material: .ultraThickMaterial)
    /// From the most see-through to the most solid.
    static let all = [ultraThin, thin, regular, thick, ultraThick]
    static let standard = regular

    // MARK: - Variables

    /// The persisted spelling.
    let name: String
    let title: LocalizedStringResource
    let material: Material

    /// Where this material sits in ``all``.
    var position: Int { Self.all.firstIndex(of: self) ?? 0 }

    // MARK: - Initializers

    private init(name: String, title: LocalizedStringResource, material: Material) {
        self.name = name
        self.title = title
        self.material = material
    }

    // MARK: - Actions - Lookup

    static func named(_ name: String?) -> ZeeSurfaceMaterial? {
        all.first { $0.name == name }
    }

    /// The material at `position` in ``all``, held to its ends.
    static func at(position: Int) -> ZeeSurfaceMaterial {
        all[min(max(position, 0), all.count - 1)]
    }
}

// MARK: - Hashable

extension ZeeSurfaceMaterial {
    static func == (lhs: ZeeSurfaceMaterial, rhs: ZeeSurfaceMaterial) -> Bool {
        lhs.name == rhs.name
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

extension ZeeSurfaceMaterial {
    /// The device's choice, or `override` where a view draws one of its own.
    @MainActor
    static func shown(_ override: ZeeSurfaceMaterial?) -> ZeeSurfaceMaterial {
        override ?? BrowserDeviceAppearanceStore.shared.surfaceMaterial
    }
}

extension EnvironmentValues {
    /// A material that replaces the device's choice under it, as a preview
    /// that shows each one sets. Nil draws the device's choice.
    @Entry var zeeSurfaceMaterial: ZeeSurfaceMaterial? = nil
}
