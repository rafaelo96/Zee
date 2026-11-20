import SwiftUI

struct BrowserSpaceBannerBackground: View {
    let branding: SpaceBranding
    /// How much of whatever lies behind shows through, from 0, solid, to 1,
    /// the most glass the look allows. The system's Reduce Transparency keeps
    /// it solid.
    var transparency = 0.0

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast

    private let previewReduceTransparency: Bool?
    private let previewContrast: ColorSchemeContrast?

    init(branding: SpaceBranding, transparency: Double = 0) {
        self.branding = branding
        self.transparency = transparency
        previewReduceTransparency = nil
        previewContrast = nil
    }

    init(
        previewBranding branding: SpaceBranding,
        reduceTransparency: Bool,
        contrast: ColorSchemeContrast
    ) {
        self.branding = branding
        previewReduceTransparency = reduceTransparency
        previewContrast = contrast
    }

    var body: some View {
        GeometryReader { geometry in
            let colors = resolvedColors
            ZStack {
                ZeeColor.windowBackground.opacity(1 - shownTransparency)
                BrowserSpaceThemeField(
                    themeMode: branding.themeMode,
                    bannerPattern: branding.bannerPattern,
                    gradientAngle: branding.gradientAngle,
                    colors: colors,
                    size: geometry.size
                )
                .opacity(fieldOpacity)

                if readabilityOpacity > 0 {
                    Color.black.opacity(readabilityOpacity)
                }

                if branding.textureStrength > 0 {
                    BrowserSpaceThemeTexture()
                        .blendMode(.softLight)
                        .opacity(textureOpacity)
                }
            }
            .clipped()
        }
        .accessibilityHidden(true)
    }

    private var resolvedColors: [Color] {
        let colors = branding.colors.map(\.color)
        return colors.isEmpty ? [BrandColor.indigo.color] : colors
    }

    private var fieldOpacity: Double {
        effectiveReduceTransparency
            ? max(branding.bannerStrength, 0.85)
            : branding.bannerStrength * (1 - shownTransparency * BrowserSpaceBannerBackgroundMetrics.glassClearing)
    }

    /// The transparency drawn, which is none while the system reduces it.
    private var shownTransparency: Double {
        effectiveReduceTransparency ? 0 : min(max(transparency, 0), 1)
    }

    /// How strongly the grain lies over the sidebar, whatever its mode: the
    /// look's texture strength of a full grain, which is fainter while the
    /// system reduces transparency.
    private var textureOpacity: Double {
        branding.textureStrength * (effectiveReduceTransparency ? 0.24 : 0.38)
    }

    private var readabilityOpacity: Double {
        let configured =
            effectiveReduceTransparency
            ? max(branding.readabilityFade, 0.42)
            : branding.readabilityFade
        let increasedContrast = effectiveContrast == .increased ? 0.1 : 0
        return min(configured * 0.55 + increasedContrast, 0.7)
    }

    private var effectiveReduceTransparency: Bool {
        previewReduceTransparency ?? reduceTransparency
    }

    private var effectiveContrast: ColorSchemeContrast {
        previewContrast ?? contrast
    }
}

enum BrowserSpaceBannerBackgroundMetrics {
    /// How much of the look's color fully transparent glass gives up: most
    /// of it, while a breath stays so the sidebar still wears the Space.
    static let glassClearing = 0.75
}

#if DEBUG
    #Preview("Banner and gradient") {
        HStack(spacing: 16) {
            BrowserSpaceBannerBackground(branding: BrowserSpaceBrandingPreviewFixture.bannerBranding)
            BrowserSpaceBannerBackground(branding: BrowserSpaceBrandingPreviewFixture.gradientBranding)
        }.frame(width: 500, height: 360).padding()
    }
#endif
