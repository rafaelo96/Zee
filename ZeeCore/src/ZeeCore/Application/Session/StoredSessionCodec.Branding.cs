using System.Text.Json.Nodes;

using ZeeCore.Contracts;

namespace ZeeCore.Application;

internal static partial class StoredSessionCodec {
    #region Variables

    /// Branding stored before rendering versions were recorded is version one.
    private const int FirstRenderingVersion = 1;

    #endregion

    #region Actions - Branding

    /// A Space's branding, with the native reader's defaults for anything missing
    /// and for a term this build cannot name. Colors that are not color records
    /// are left out.
    internal static SpaceBranding DecodeBranding(JsonNode? node) {
        var value = Object(node);
        var fade = OptionalNumber(value[Key.ReadabilityFade]);
        var keepsReadable = Flag(value[Key.KeepsControlsReadable]);
        fade ??= keepsReadable ?? true ? SpaceBranding.LegacyReadabilityFade : 0;
        return new(Palette(value[Key.Colors]) ?? new([]),
            SpaceBannerPattern.Named(Text(value[Key.BannerPattern])) ?? SpaceBannerPattern.Solid,
            OptionalNumber(value[Key.BannerStrength]) ?? 1, fade.Value, keepsReadable ?? fade > 0,
            SpaceThemeMode.Named(Text(value[Key.ThemeMode])) ?? SpaceThemeMode.Banner,
            OptionalNumber(value[Key.GradientAngle]) ?? 0,
            Texture(Flag(value[Key.ShowsTexture]), OptionalNumber(value[Key.TextureStrength])),
            SpaceIconStyle.Named(Text(value[Key.IconStyle])) ?? SpaceIconStyle.SimpleSymbol,
            value[Key.SymbolColor] is JsonObject symbolColor ? DecodeColor(symbolColor) : null,
            DecodeZee(value[Key.Badge] as JsonObject ?? []),
            Integer(value[Key.RenderingVersion]) ?? FirstRenderingVersion,
            OptionalNumber(value[Key.FolderColorIntensity]) ?? 0,
            SpaceTextColorMode.Named(Text(value[Key.TextColorMode])) ?? SpaceTextColorMode.Automatic,
            Flag(value[Key.HasCustomAppearance]));
    }

    /// The texture strength a branding stored by any build lies under. A build
    /// that keeps only whether a texture shows writes the switch alone, and
    /// can turn it on over a strength of none: the switch decides, and a texture
    /// it shows with no strength of its own is full.
    internal static double Texture(bool? shows, double? strength) => shows switch {
        false => 0,
        true => strength is > 0 and var stored ? stored : 1,
        null => strength ?? 0
    };

    /// A branding as the stored session and sync keep it. Whether a texture
    /// shows is the switch builds before texture strength read, and the
    /// strength is written only where the switch alone can't say it, between
    /// none and full.
    internal static JsonObject Encode(SpaceBranding branding) {
        var value = new JsonObject {
            [Key.Colors] = Encode(branding.Colors),
            [Key.BannerPattern] = branding.BannerPattern.Name,
            [Key.BannerStrength] = branding.BannerStrength,
            [Key.ReadabilityFade] = branding.ReadabilityFade,
            [Key.KeepsControlsReadable] = branding.KeepsControlsReadable,
            [Key.ThemeMode] = branding.ThemeMode.Name,
            [Key.GradientAngle] = branding.GradientAngle,
            [Key.ShowsTexture] = branding.TextureStrength > 0,
            [Key.IconStyle] = branding.IconStyle.Name
        };
        if (branding.TextureStrength is > 0 and < 1) value[Key.TextureStrength] = branding.TextureStrength;
        if (branding.SymbolColor is { } symbolColor) value[Key.SymbolColor] = Encode(symbolColor);
        value[Key.Badge] = Encode(branding.Badge);
        value[Key.RenderingVersion] = branding.RenderingVersion;
        value[Key.FolderColorIntensity] = branding.FolderColorIntensity;
        value[Key.TextColorMode] = branding.TextColorMode.Name;
        if (branding.HasCustomAppearance is { } custom) value[Key.HasCustomAppearance] = custom;
        return value;
    }

    /// A badge composition. Missing layer indices read as the first color, the
    /// edge follows the trim, and every other parameter takes its neutral value.
    internal static SpaceBadge DecodeZee(JsonObject value) {
        int Index(string key, int fallback = 0) => Integer(value[key]) ?? fallback;
        double Measure(BadgeMeasure measure) => OptionalNumber(value[measure.Name]) ?? measure.Default;
        int Count(BadgeMeasure measure) => Integer(value[measure.Name]) ?? (int)measure.Default;
        return new(BadgeBackplate.Named(Text(value[Key.Backplate])) ?? BadgeBackplate.Shield,
            BadgeFieldDivision.Named(Text(value[Key.FieldDivision])) ?? BadgeFieldDivision.Plain,
            BadgeOrdinary.Named(Text(value[Key.Ordinary])) ?? BadgeOrdinary.None,
            BadgeTrim.Named(Text(value[Key.Trim])) ?? BadgeTrim.None,
            BadgeSymbol.Named(Text(value[Key.Symbol])) ?? BadgeSymbol.Fallback,
            BadgeChargeLayout.Named(Text(value[Key.ChargeLayout])) ?? BadgeChargeLayout.Single,
            Index(Key.BackplateColorIndex), Index(Key.SecondaryFieldColorIndex), Index(Key.OrdinaryColorIndex),
            Index(Key.TrimColorIndex), Index(Key.SymbolColorIndex), TolerantText(value[Key.StartingPresetId]),
            Index(Key.EdgeColorIndex, Index(Key.TrimColorIndex)), Palette(value[Key.Palette]),
            value[Key.Charge] is JsonObject charge ? DecodeCharge(charge) : null,
            Measure(BadgeMeasure.PlateScale), Measure(BadgeMeasure.EdgeWidth), Count(BadgeMeasure.DivisionCount),
            BadgeFinish.Named(Text(value[Key.Finish])) ?? BadgeFinish.Flat,
            Measure(BadgeMeasure.OrdinaryWidth), Measure(BadgeMeasure.TrimWeight), Count(BadgeMeasure.TrimDetail),
            Measure(BadgeMeasure.ChargeScale), Measure(BadgeMeasure.ChargeOffset),
            BadgeChargeWeight.Named(Text(value[Key.ChargeWeight])) ?? BadgeChargeWeight.Bold,
            Measure(BadgeMeasure.SheenAngle), Count(BadgeMeasure.SealTeeth), TolerantFlag(value[Key.ShowsOutline]) ?? false,
            BadgeDepth.Named(Text(value[Key.Depth])) ?? BadgeDepth.None);
    }

    internal static JsonObject Encode(SpaceBadge badge) {
        var value = new JsonObject {
            [Key.Backplate] = badge.Backplate.Name,
            [Key.FieldDivision] = badge.FieldDivision.Name,
            [Key.Ordinary] = badge.Ordinary.Name,
            [Key.Trim] = badge.Trim.Name,
            [Key.Symbol] = badge.Symbol.Name,
            [Key.ChargeLayout] = badge.ChargeLayout.Name,
            [Key.BackplateColorIndex] = badge.BackplateColorIndex,
            [Key.SecondaryFieldColorIndex] = badge.SecondaryFieldColorIndex,
            [Key.OrdinaryColorIndex] = badge.OrdinaryColorIndex,
            [Key.TrimColorIndex] = badge.TrimColorIndex,
            [Key.SymbolColorIndex] = badge.SymbolColorIndex
        };
        Put(value, Key.StartingPresetId, badge.StartingPresetId);
        value[Key.EdgeColorIndex] = badge.EdgeColorIndex;
        if (badge.Palette is { } palette) value[Key.Palette] = Encode(palette);
        if (badge.Charge is { } charge) value[Key.Charge] = Encode(charge);
        value[BadgeMeasure.PlateScale.Name] = badge.PlateScale;
        value[BadgeMeasure.EdgeWidth.Name] = badge.EdgeWidth;
        value[BadgeMeasure.DivisionCount.Name] = badge.DivisionCount;
        value[Key.Finish] = badge.Finish.Name;
        value[BadgeMeasure.OrdinaryWidth.Name] = badge.OrdinaryWidth;
        value[BadgeMeasure.TrimWeight.Name] = badge.TrimWeight;
        value[BadgeMeasure.TrimDetail.Name] = badge.TrimDetail;
        value[BadgeMeasure.ChargeScale.Name] = badge.ChargeScale;
        value[BadgeMeasure.ChargeOffset.Name] = badge.ChargeOffset;
        value[Key.ChargeWeight] = badge.ChargeWeight.Name;
        value[BadgeMeasure.SheenAngle.Name] = badge.SheenAngle;
        value[BadgeMeasure.SealTeeth.Name] = badge.SealTeeth;
        value[Key.ShowsOutline] = badge.ShowsOutline;
        value[Key.Depth] = badge.Depth.Name;
        return value;
    }

    /// A custom figure. An unknown kind draws nothing, a heraldic figure this
    /// build cannot name is the mountain, and a monogram is serif unless it says.
    internal static BadgeCharge DecodeCharge(JsonObject value) {
        var text = TolerantText(value[Key.Value]) ?? "";
        var kind = BadgeChargeKind.Named(TolerantText(value[Key.Kind])) ?? BadgeChargeKind.None;
        return kind.Kind switch {
            BadgeChargeKind.Kinds.Heraldic => new(kind, BadgeSymbol.Named(text) ?? BadgeSymbol.Fallback),
            BadgeChargeKind.Kinds.System or BadgeChargeKind.Kinds.Emoji => new(kind, Text: text),
            BadgeChargeKind.Kinds.Monogram => new(kind, Text: text,
                Style: BadgeMonogramStyle.Named(TolerantText(value[Key.Style])) ?? BadgeMonogramStyle.Serif),
            _ => new(BadgeChargeKind.None)
        };
    }

    internal static JsonObject Encode(BadgeCharge charge) {
        var value = new JsonObject { [Key.Kind] = charge.Kind.Name };
        if (charge.Kind == BadgeChargeKind.Heraldic && charge.Symbol is { } symbol) value[Key.Value] = symbol.Name;
        else if (charge.Kind != BadgeChargeKind.None) value[Key.Value] = charge.Text ?? "";
        if (charge.Kind == BadgeChargeKind.Monogram) value[Key.Style] = (charge.Style ?? BadgeMonogramStyle.Serif).Name;
        return value;
    }

    private static ColorPalette? Palette(JsonNode? node) =>
        node is JsonArray colors ? new([.. colors.OfType<JsonObject>().Select(DecodeColor)]) : null;

    private static JsonArray Encode(ColorPalette palette) => new(palette.Colors.Select(color => (JsonNode?)Encode(color)).ToArray());

    #endregion
}
