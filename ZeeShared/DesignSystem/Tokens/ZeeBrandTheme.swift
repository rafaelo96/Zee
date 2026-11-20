import SwiftUI

/// The scheme-aware semantic layer over `ZeeBrandPalette`.
///
/// `ZeeBrandPalette` holds Zee's fixed all-blue identity. `ZeeBrandTheme` names
/// the *roles* those hues play and flips each role between light and dark, so
/// Zee-authored chrome can adopt the brand without hardcoding an appearance.
///
/// Light is cloud white and mist under midnight text with an ocean-blue accent;
/// dark is Big Sur's midnight with the accent lifted to sky blue so it stays
/// legible. The warm half of the palette belongs to identity surfaces, not to
/// controls. Every pair below clears WCAG AA for text (4.5:1) or non-text
/// (3:1) in both schemes.
enum ZeeBrandTheme {
    // MARK: - Static Variables

    // Component pairs

    /// Ocean blue, lifted to sky blue for dark.
    static let accentLightComponents = ZeeBrandPalette.oceanComponents
    static let accentDarkComponents = ZeeBrandPalette.skyComponents

    /// The accent when it is *text* rather than a tint.
    ///
    /// `accent` is scoped to the 3:1 non-text minimum, which is all a fill, a stroke,
    /// or a glyph needs. A text-only control — `ZeeButtonStyle`'s `.tertiary` and
    /// `.destructive` roles — is text, and has to clear 4.5:1 against both `canvas`
    /// and `surface`. Ocean blue falls short on mist, so this role uses deep
    /// blue in light and sky blue in dark.
    static let accentTextLightComponents = ZeeBrandPalette.deepComponents
    static let accentTextDarkComponents = ZeeBrandPalette.skyComponents

    static let canvasLightComponents = ZeeBrandPalette.cloudComponents
    static let canvasDarkComponents = ZeeBrandPalette.midnightComponents

    static let surfaceLightComponents = ZeeBrandPalette.mistComponents
    static let surfaceDarkComponents = ZeeBrandPalette.midnightSoftComponents

    static let textDisplayLightComponents = ZeeBrandPalette.midnightComponents
    static let textDisplayDarkComponents = ZeeBrandPalette.cloudComponents
    /// Display text held back for supporting copy, at 0.7 on light surfaces
    /// and 0.6 on dark ones.
    static let textSecondaryLightOpacity = 0.7
    static let textSecondaryDarkOpacity = 0.6

    static let lineLightComponents = ZeeBrandPalette.midnightComponents
    static let lineDarkComponents = ZeeBrandPalette.cloudComponents
    /// Matches `ZeeBrandPalette.line`; the dark hairline is lifted because white
    /// on Midnight loses definition faster than Midnight on white.
    static let lineLightOpacity = 0.18
    static let lineDarkOpacity = 0.22

    /// A wash of display text, faint enough to sit under text without taking
    /// from its contrast.
    static let quietFillLightOpacity = 0.05
    static let quietFillDarkOpacity = 0.08

    // Semantic roles

    /// Brand accent for interactive emphasis and tint.
    static let accent = dynamic(light: accentLightComponents, dark: accentDarkComponents)
    /// What marks the chosen item on Zee's always-dark brand stage (the
    /// setup flow): white, because the stage's own blues would hide a blue
    /// ring on a blue swatch.
    static let stageSelection = ZeeBrandPalette.cloud
    /// Brand accent for text-weight controls. See `accentTextLightComponents`.
    static let accentText = dynamic(
        light: accentTextLightComponents,
        dark: accentTextDarkComponents
    )
    /// The page the content sits on.
    static let canvas = dynamic(light: canvasLightComponents, dark: canvasDarkComponents)
    /// A raised card or panel on the canvas.
    static let surface = dynamic(light: surfaceLightComponents, dark: surfaceDarkComponents)
    /// Display and body text on `canvas` or `surface`.
    static let textDisplay = dynamic(
        light: textDisplayLightComponents,
        dark: textDisplayDarkComponents
    )
    /// Supporting text beside `textDisplay`: captions, counts, hints and notes.
    static let textSecondary = dynamic(
        light: textDisplayLightComponents,
        lightOpacity: textSecondaryLightOpacity,
        dark: textDisplayDarkComponents,
        darkOpacity: textSecondaryDarkOpacity
    )
    /// Hairline separators and control borders.
    static let line = dynamic(
        light: lineLightComponents,
        lightOpacity: lineLightOpacity,
        dark: lineDarkComponents,
        darkOpacity: lineDarkOpacity
    )
    /// The quiet ground of a panel or control that sits on `canvas` without
    /// rising to `surface`.
    static let quietFill = dynamic(
        light: textDisplayLightComponents,
        lightOpacity: quietFillLightOpacity,
        dark: textDisplayDarkComponents,
        darkOpacity: quietFillDarkOpacity
    )

    // MARK: - Actions - Resolving

    /// The role values as flat colors, for surfaces that already know which
    /// appearance they render in.
    static func accent(_ colorScheme: ColorScheme) -> Color {
        components(accentLightComponents, accentDarkComponents, colorScheme).color
    }

    static func accentText(_ colorScheme: ColorScheme) -> Color {
        components(accentTextLightComponents, accentTextDarkComponents, colorScheme).color
    }

    static func canvas(_ colorScheme: ColorScheme) -> Color {
        components(canvasLightComponents, canvasDarkComponents, colorScheme).color
    }

    static func surface(_ colorScheme: ColorScheme) -> Color {
        components(surfaceLightComponents, surfaceDarkComponents, colorScheme).color
    }

    static func textDisplay(_ colorScheme: ColorScheme) -> Color {
        components(textDisplayLightComponents, textDisplayDarkComponents, colorScheme).color
    }

    static func line(_ colorScheme: ColorScheme) -> Color {
        let base = components(lineLightComponents, lineDarkComponents, colorScheme)
        return base.color.opacity(colorScheme == .dark ? lineDarkOpacity : lineLightOpacity)
    }

    private static func components(
        _ light: ZeeColorComponents,
        _ dark: ZeeColorComponents,
        _ colorScheme: ColorScheme
    ) -> ZeeColorComponents {
        colorScheme == .dark ? dark : light
    }

    // MARK: - Actions - Construction

    private static func dynamic(
        light: ZeeColorComponents,
        lightOpacity: Double = 1,
        dark: ZeeColorComponents,
        darkOpacity: Double = 1
    ) -> Color {
        ZeePlatformDynamicColor.make(
            light: light,
            lightOpacity: lightOpacity,
            dark: dark,
            darkOpacity: darkOpacity
        )
    }
}
