import SwiftUI

/// The one `ButtonStyle` Zee draws.
///
/// Built on `ButtonStyle` so keyboard activation, focus, the disabled cascade,
/// and the button accessibility trait remain system-owned.
struct ZeeButtonStyle: ButtonStyle {
    let role: ZeeButtonRole
    /// Space-owned surfaces can override the role's default colour. Brand chrome
    /// leaves this `nil` and inherits `ZeeBrandTheme`.
    var tint: Color?

    func makeBody(configuration: Configuration) -> some View {
        ZeeButtonSurface(role: role, tint: tint, configuration: configuration)
    }
}
