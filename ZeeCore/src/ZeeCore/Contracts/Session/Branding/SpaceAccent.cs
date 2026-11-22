namespace ZeeCore.Contracts;

/// The accent a Space shows in places too small for its branding: the system
/// color it tints small marks with, Zee's look a new Space of the accent
/// wears, the house look the badge style starts from, and the look a Space
/// stored before branding existed wears.
///
/// The stored session and synced Space records spell an accent as its `Name`,
/// so a name never changes. An accent travels as its index in `All`, so `All`
/// is append-only.
public sealed class SpaceAccent {
    #region Static Variables

    /// Winter.
    public static readonly SpaceAccent Indigo = new(name: "indigo", tint: SystemTint.Indigo,
        legacyColors: [Tincture.Ink, Tincture.Ocean, Tincture.Gold], house: SpaceHouse.Winter.Look, swatch: Tincture.Indigo,
        zee: [Tincture.ZeeOcean, Tincture.ZeeSky]);
    /// Sun.
    public static readonly SpaceAccent Orange = new(name: "orange", tint: SystemTint.Orange,
        legacyColors: [Tincture.Ember, Tincture.Gold, Tincture.Ocean], house: SpaceHouse.Sun.Look, swatch: Tincture.Ember,
        zee: [Tincture.ZeeOrange, Tincture.ZeeSun]);
    /// Meadow.
    public static readonly SpaceAccent Teal = new(name: "teal", tint: SystemTint.Teal,
        legacyColors: [Tincture.Teal, Tincture.Ocean, Tincture.Sand], house: SpaceHouse.Meadow.Look, swatch: Tincture.Teal,
        zee: [Tincture.ZeeCyan, Tincture.ZeeOcean]);
    /// Lion.
    public static readonly SpaceAccent Rose = new(name: "rose", tint: SystemTint.Pink,
        legacyColors: [Tincture.Rose, Tincture.Indigo, Tincture.Sand], house: SpaceHouse.Lion.Look, swatch: Tincture.Rose,
        zee: [Tincture.ZeeRed, Tincture.ZeeCoral]);

    public static IReadOnlyList<SpaceAccent> All { get; } = [Indigo, Orange, Teal, Rose];

    /// The angle Zee's look runs its gradient at: straight down the sidebar.
    private const double ZeeGradientAngle = 90;

    #endregion

    #region Variables

    public string Name { get; }

    /// The system color the accent tints small marks with.
    public SystemTint Tint { get; }

    /// The palette a Space stored before branding existed wears: its
    /// background, primary and secondary color.
    public IReadOnlyList<BrandColor> LegacyColors { get; }

    /// The house look the badge style gives a Space of this accent: a deep field, a related
    /// tincture a step above it and one luminous charge, with the zee
    /// composed for it. A Space keeps its copy when this changes.
    public SpaceBranding House { get; }

    /// The one color that stands for the accent, which a color from elsewhere,
    /// such as another browser's Space, is matched against.
    public BrandColor Swatch { get; }

    /// The two colors of Zee's own palette a new simple or modern Space of
    /// this accent wears, the first leading.
    public IReadOnlyList<BrandColor> ZeeColors { get; }

    /// Zee's own look for a new Space of this accent: a gradient of its two
    /// Zee colors down the sidebar, a plain icon, and a round mountain badge
    /// for when the person shows a badge instead.
    public SpaceBranding ZeeLook { get; }

    #endregion

    #region Constructors

    private SpaceAccent(string name, SystemTint tint, IReadOnlyList<Tincture> legacyColors, SpaceBranding house, Tincture swatch,
        IReadOnlyList<Tincture> zee) {
        Name = name;
        Tint = tint;
        LegacyColors = [.. legacyColors.Select(tincture => tincture.Color)];
        House = house;
        Swatch = swatch.Color;
        ZeeColors = [.. zee.Select(tincture => tincture.Color)];
        ZeeLook = SpaceBranding.Painted(ZeeColors, SpaceBannerPattern.Diagonal, strength: 1, SpaceBranding.LegacyReadabilityFade,
            SpaceThemeMode.Gradient, ZeeGradientAngle, textureStrength: 0);
    }

    #endregion

    #region Actions - Lookup

    public static SpaceAccent? Named(string? name) => All.FirstOrDefault(accent => accent.Name == name);

    /// The accent whose swatch lies nearest `color` in red, green and blue,
    /// the first in `All` on a tie.
    public static SpaceAccent Nearest(BrandColor color) {
        ArgumentNullException.ThrowIfNull(color);
        return All.MinBy(accent => Math.Pow(color.Red - accent.Swatch.Red, 2) + Math.Pow(color.Green - accent.Swatch.Green, 2)
            + Math.Pow(color.Blue - accent.Swatch.Blue, 2))!;
    }

    #endregion
}
