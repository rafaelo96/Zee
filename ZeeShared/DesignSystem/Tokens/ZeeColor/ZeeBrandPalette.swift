import SwiftUI

/// Zee's palette: bright, saturated color in the spirit of macOS Big Sur,
/// in an order of Zee's own. Ocean and deep blue, sky and cyan, then coral
/// and a vivid red, and a ribbon of sun gold. The colors
/// meet in fluid gradients, never as flat blocks, and never as violet,
/// purple, lavender or magenta. Space colors remain user-owned.
enum ZeeBrandPalette {
    // MARK: - Static Variables

    // Cool

    static let deepComponents = ZeeColorComponents(red: 19, green: 102, blue: 184)
    static let oceanComponents = ZeeColorComponents(red: 23, green: 137, blue: 221)
    static let skyComponents = ZeeColorComponents(red: 43, green: 180, blue: 240)
    static let cyanComponents = ZeeColorComponents(red: 63, green: 208, blue: 245)
    /// The cyan of the Zee mark itself, the open dial on the app icon.
    static let dialComponents = ZeeColorComponents(red: 0, green: 188, blue: 243)

    // Warm

    static let sunComponents = ZeeColorComponents(red: 255, green: 191, blue: 31)
    static let orangeComponents = ZeeColorComponents(red: 255, green: 138, blue: 31)
    static let coralComponents = ZeeColorComponents(red: 255, green: 90, blue: 72)
    /// A vivid red with a touch of rose, Zee's warmest color.
    static let redComponents = ZeeColorComponents(red: 249, green: 0, blue: 45)
    /// Red in shadow, for the foot of a warm surface. It darkens within red,
    /// never toward blue: where Big Sur's reds turn magenta, Zee's stay red.
    static let redDeepComponents = ZeeColorComponents(red: 184, green: 16, blue: 42)
    /// The pale band where Big Sur's sky meets its warm light.
    static let hazeComponents = ZeeColorComponents(red: 207, green: 224, blue: 252)

    // Grounds

    /// The dark ground: the deep blue of Big Sur's night.
    static let midnightComponents = ZeeColorComponents(red: 14, green: 26, blue: 51)
    /// Midnight lifted one step, for raised dark surfaces.
    static let midnightSoftComponents = ZeeColorComponents(red: 28, green: 43, blue: 74)
    /// The light ground, a cool white.
    static let cloudComponents = ZeeColorComponents(red: 247, green: 249, blue: 252)
    /// A light raised surface, a breath of sky in it.
    static let mistComponents = ZeeColorComponents(red: 232, green: 241, blue: 250)

    static let deep = deepComponents.color
    static let ocean = oceanComponents.color
    static let sky = skyComponents.color
    static let cyan = cyanComponents.color
    static let dial = dialComponents.color
    static let sun = sunComponents.color
    static let orange = orangeComponents.color
    static let coral = coralComponents.color
    static let red = redComponents.color
    static let redDeep = redDeepComponents.color
    static let haze = hazeComponents.color
    static let midnight = midnightComponents.color
    static let midnightSoft = midnightSoftComponents.color
    static let cloud = cloudComponents.color
    static let mist = mistComponents.color
    static let match = ocean
    static let line = midnight.opacity(ZeeOpacity.brandHairline)

    /// The brand's signature order, back to front: coral, red, a
    /// ribbon of sun, then cyan and ocean in front, for surfaces
    /// that carry the identity itself: the icon, the mark, the welcome.
    static let landscape = [coral, red, sun, cyan, ocean]
}
