import SwiftUI

/// Forwards to `ZeeTypography` so the wizard and the rest of the app share
/// one type scale. Kept as a name because the wizard's call sites are
/// hand-composed.
enum BrowserOnboardingTypography {
    static func display(_ size: CGFloat) -> Font {
        ZeeTypography.display(size)
    }

    static func sans(
        _ size: CGFloat,
        weight: Font.Weight = .regular
    ) -> Font {
        ZeeTypography.sans(size, weight: weight)
    }
}
