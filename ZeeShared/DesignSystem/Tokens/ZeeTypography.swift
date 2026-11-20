import SwiftUI

/// Type roles for Zee-authored content.
///
/// Zee speaks in Apple's own type: SF Pro Rounded, bold, for its brand voice,
/// and SF Pro for supporting copy and controls, so it reads as native to the
/// Mac. Both ship with the system, so nothing is embedded in the bundle.
enum ZeeTypography {
    /// The weight of the rounded display face.
    static let displayWeight = Font.Weight.bold

    static let controlTitle = Font.body.weight(.medium)
    static let metadata = Font.caption
    static let compactMetadata = Font.caption2
    static let badge = Font.caption2.monospaced().weight(.semibold)

    /// The rounded display face for `style`'s role, at `size`.
    static func display(_ size: CGFloat, relativeTo style: Font.TextStyle) -> Font {
        display(size)
    }

    /// The rounded display face at a fixed size, for hand-tuned layouts (the
    /// onboarding wizard) whose line breaks are composed by hand.
    static func display(_ size: CGFloat) -> Font {
        .system(size: size, weight: displayWeight, design: .rounded)
    }

    static func sans(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight)
    }

    // MARK: - Named display roles

    /// Title of a single page or pane inside a Zee-authored flow.
    static let displayPageSize: CGFloat = 24
    /// Heading that opens a group of rows inside a pane.
    static let displaySectionSize: CGFloat = 17

    static var displayPage: Font { display(displayPageSize, relativeTo: .title2) }
    static var displaySection: Font { display(displaySectionSize, relativeTo: .title3) }
}
