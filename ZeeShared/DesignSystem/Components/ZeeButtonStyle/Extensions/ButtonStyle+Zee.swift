import SwiftUI

extension ButtonStyle where Self == ZeeButtonStyle {
    static var zeePrimary: ZeeButtonStyle {
        ZeeButtonStyle(role: .primary)
    }

    static func zeePrimary(tint: Color) -> ZeeButtonStyle {
        ZeeButtonStyle(role: .primary, tint: tint)
    }

    static var zeeSecondary: ZeeButtonStyle {
        ZeeButtonStyle(role: .secondary)
    }

    static var zeeTertiary: ZeeButtonStyle {
        ZeeButtonStyle(role: .tertiary)
    }

    static func zeeTertiary(tint: Color) -> ZeeButtonStyle {
        ZeeButtonStyle(role: .tertiary, tint: tint)
    }

    static var zeeDestructive: ZeeButtonStyle {
        ZeeButtonStyle(role: .destructive)
    }

    static func zeeIcon(
        tint: Color? = nil,
        diameter: CGFloat = ZeeButtonMetrics.iconDiameter,
        isProminent: Bool = false
    ) -> ZeeButtonStyle {
        ZeeButtonStyle(
            role: .icon(diameter: diameter, isProminent: isProminent),
            tint: tint
        )
    }
}
