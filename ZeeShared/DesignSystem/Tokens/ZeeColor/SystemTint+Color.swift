import SwiftUI

extension SystemTint {
    /// The color for the core's tint. This is the one place a tint becomes a
    /// color.
    ///
    /// The core names tints after the system's colors, but Zee draws each in
    /// its own palette: purple, indigo and pink have no place in it, so they
    /// fall to the nearest Zee hue — deep blue, ocean and coral. Green keeps
    /// the house success tone, which the palette has no hue for.
    var color: Color {
        switch self {
        case .red: ZeeBrandPalette.red
        case .orange: ZeeBrandPalette.orange
        case .purple: ZeeBrandPalette.deep
        case .blue: ZeeBrandPalette.ocean
        case .indigo: ZeeBrandPalette.ocean
        case .teal: ZeeBrandPalette.cyan
        case .pink: ZeeBrandPalette.coral
        case .green: ZeeColor.success
        }
    }
}
