using ZeeCore.Domain;

namespace ZeeCore.Contracts;

/// The range rules for a Space's banner branding. The badge's heraldic vocabulary
/// stays with the native renderer; the core owns the palette size, the banner
/// strengths, the gradient angle, the badge's layer colors pointing at a color
/// that exists, its composition parameters within the ranges the renderer draws
/// and its custom figure, so the branding the core stages for sync is the one
/// every device renders.
public sealed partial record SpaceBranding {
    #region Static Variables

    internal const int MaximumColorCount = 3;
    internal const int MaximumBadgePaletteCount = 6;

    /// The Space color used when a branding record has none: Zee's ocean blue.
    internal static BrandColor DefaultColor => Tincture.ZeeOcean.Color;

    #endregion

    #region Actions - Normalization

    /// The branding with every rule the core owns applied, as every client
    /// writes it: its banner strength in today's units, at most three colors
    /// and never none, strengths, fades and color components within 0 through
    /// 1, the gradient angle within a turn, and badge layers addressing a color
    /// that exists. The badge's own palette is dropped when it holds no color,
    /// its composition parameters stay within the ranges the renderer draws,
    /// and a custom figure that is the badge's own symbol is no custom figure.
    /// It announces the readability and rendering vocabulary its values need.
    internal static SpaceBranding Normalized(SpaceBranding branding) {
        ArgumentNullException.ThrowIfNull(branding);
        branding = branding.InTodaysUnits();
        var colors = branding.Colors.Colors.Take(MaximumColorCount).Select(NormalizedColor).ToArray();
        if (colors.Length == 0) colors = [DefaultColor];
        var palette = branding.Badge.Palette?.Colors.Take(MaximumBadgePaletteCount).Select(NormalizedColor).ToArray();
        if (palette is { Length: 0 }) palette = null;
        int layers = LayerColorCount(palette?.Length, colors.Length);
        var badge = branding.Badge;
        return Announced(branding with {
            Colors = new(colors),
            BannerStrength = Unit(branding.BannerStrength),
            ReadabilityFade = Unit(branding.ReadabilityFade),
            GradientAngle = NormalizedAngle(branding.GradientAngle),
            TextureStrength = Unit(branding.TextureStrength),
            FolderColorIntensity = Unit(branding.FolderColorIntensity),
            SymbolColor = branding.SymbolColor is { } symbol ? NormalizedColor(symbol) : null,
            Badge = badge with {
                Palette = palette is null ? null : new(palette),
                BackplateColorIndex = LayerIndex(badge.BackplateColorIndex, layers),
                SecondaryFieldColorIndex = LayerIndex(badge.SecondaryFieldColorIndex, layers),
                OrdinaryColorIndex = LayerIndex(badge.OrdinaryColorIndex, layers),
                TrimColorIndex = LayerIndex(badge.TrimColorIndex, layers),
                SymbolColorIndex = LayerIndex(badge.SymbolColorIndex, layers),
                EdgeColorIndex = LayerIndex(badge.EdgeColorIndex, layers),
                Charge = NormalizedCharge(badge.Charge, badge.Symbol),
                PlateScale = BadgeMeasure.PlateScale.Clamped(badge.PlateScale),
                EdgeWidth = BadgeMeasure.EdgeWidth.Clamped(badge.EdgeWidth),
                DivisionCount = BadgeMeasure.DivisionCount.Clamped(badge.DivisionCount),
                OrdinaryWidth = BadgeMeasure.OrdinaryWidth.Clamped(badge.OrdinaryWidth),
                TrimWeight = BadgeMeasure.TrimWeight.Clamped(badge.TrimWeight),
                TrimDetail = BadgeMeasure.TrimDetail.Clamped(badge.TrimDetail),
                ChargeScale = BadgeMeasure.ChargeScale.Clamped(badge.ChargeScale),
                ChargeOffset = BadgeMeasure.ChargeOffset.Clamped(badge.ChargeOffset),
                SheenAngle = BadgeMeasure.SheenAngle.Clamped(badge.SheenAngle),
                SealTeeth = BadgeMeasure.SealTeeth.Clamped(badge.SealTeeth)
            }
        });
    }

    /// `look` with the readability and rendering vocabulary it announces worked
    /// out from its values.
    internal static SpaceBranding Announced(SpaceBranding look) {
        ArgumentNullException.ThrowIfNull(look);
        return look with { KeepsControlsReadable = look.ReadabilityFade > 0, RenderingVersion = NeededRenderingVersion(look) };
    }

    /// A badge's custom figure as the renderer draws it: names and letters
    /// trimmed, one emoji, a monogram of at most two capitals, nothing drawn in
    /// place of an empty one, and none at all when it is the badge's own symbol.
    private static BadgeCharge? NormalizedCharge(BadgeCharge? charge, BadgeSymbol symbol) {
        if (charge is null) return null;
        var figure = charge.Kind.Normalized(charge);
        return figure.Kind == BadgeChargeKind.Heraldic && figure.Symbol == symbol ? null : figure;
    }

    /// A strength, fade, intensity or color component, kept within 0 through 1.
    /// A value that is not a number falls back to `fallback`.
    private static double Unit(double value, double fallback = 0) => double.IsFinite(value) ? Math.Clamp(value, 0, 1) : fallback;

    /// Degrees in [0, 360).
    private static double NormalizedAngle(double angle) {
        if (!double.IsFinite(angle)) return 0;
        double remainder = angle % 360;
        return remainder >= 0 ? remainder : remainder + 360;
    }

    /// How many colors a badge's layer indices can address: its own palette
    /// when it has one, else the Space's colors, and never fewer than one.
    private static int LayerColorCount(int? badgePaletteCount, int spaceColorCount) =>
        Math.Max(badgePaletteCount ?? spaceColorCount, 1);

    /// A layer index outside the addressable colors falls back to the first.
    private static int LayerIndex(int index, int colorCount) => index >= 0 && index < colorCount ? index : 0;

    private static BrandColor NormalizedColor(BrandColor color) =>
        new(Unit(color.Red), Unit(color.Green), Unit(color.Blue), Unit(color.Alpha, 1));

    #endregion

    #region Actions - Rendering vocabulary

    /// The rendering vocabulary `branding` needs, which is the version it
    /// announces: the newest vocabulary any of its terms is drawn since, and
    /// the Studio's when it sets a Studio parameter or a color of its own.
    /// Every Apple client computes it this way when it writes a branding.
    internal static int NeededRenderingVersion(SpaceBranding branding) {
        ArgumentNullException.ThrowIfNull(branding);
        var badge = branding.Badge;
        BadgeVocabulary[] needed = [
            branding.BannerPattern.DrawnSince, badge.Symbol.DrawnSince, badge.Backplate.DrawnSince, badge.FieldDivision.DrawnSince,
            badge.Ordinary.DrawnSince, badge.Trim.DrawnSince, badge.ChargeLayout.DrawnSince, badge.Finish.DrawnSince,
            badge.Depth.DrawnSince, badge.ChargeWeight.DrawnSince,
            branding.SymbolColor is null ? BadgeVocabulary.Baseline : BadgeVocabulary.Customization,
            UsesStudioParameters(badge) ? BadgeVocabulary.Studio : BadgeVocabulary.Baseline
        ];
        return needed.Max(vocabulary => vocabulary.Version);
    }

    /// Whether the badge moves a measure only the Studio vocabulary draws off
    /// its default, draws an outline, or wears colors or a figure of its own.
    private static bool UsesStudioParameters(SpaceBadge badge) =>
        badge.Palette is not null || badge.Charge is not null || badge.ShowsOutline
        || BadgeMeasure.All.Any(measure => measure.IsMoved(badge));

    #endregion
}
