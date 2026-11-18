namespace ZeeCore.Contracts;

/// The shape a badge is drawn on.
public sealed class BadgeBackplate {
    #region Types

    /// Each platform draws each shape's outline, so its renderer switches over the kind.
    public enum Kinds { None, Circle, Shield, FrenchShield, Diamond, Seal, Hexagon, Octagon, RoundedSquare, Oval, Banner, Badge }

    #endregion

    #region Variables

    public static readonly BadgeBackplate None = new(Kinds.None, "none", "None", BadgeVocabulary.Baseline);
    public static readonly BadgeBackplate Circle = new(Kinds.Circle, "circle", "Round", BadgeVocabulary.Baseline);
    public static readonly BadgeBackplate Shield = new(Kinds.Shield, "shield", "Shield", BadgeVocabulary.Baseline);
    public static readonly BadgeBackplate FrenchShield = new(Kinds.FrenchShield, "frenchShield", "French Shield", BadgeVocabulary.Studio);
    public static readonly BadgeBackplate Diamond = new(Kinds.Diamond, "diamond", "Lozenge", BadgeVocabulary.Baseline);
    public static readonly BadgeBackplate Seal = new(Kinds.Seal, "seal", "Seal", BadgeVocabulary.Baseline, hasTeeth: true);
    public static readonly BadgeBackplate Hexagon = new(Kinds.Hexagon, "hexagon", "Hexagon", BadgeVocabulary.Baseline);
    public static readonly BadgeBackplate Octagon = new(Kinds.Octagon, "octagon", "Octagon", BadgeVocabulary.Customization);
    public static readonly BadgeBackplate RoundedSquare = new(Kinds.RoundedSquare, "roundedSquare", "Rounded Square",
        BadgeVocabulary.Customization);
    public static readonly BadgeBackplate Oval = new(Kinds.Oval, "oval", "Oval", BadgeVocabulary.Studio);
    public static readonly BadgeBackplate Banner = new(Kinds.Banner, "banner", "Banner", BadgeVocabulary.Studio);
    public static readonly BadgeBackplate Badge = new(Kinds.Badge, "badge", "Badge", BadgeVocabulary.Studio);

    public static IReadOnlyList<BadgeBackplate> All { get; } =
        [None, Circle, Shield, FrenchShield, Diamond, Seal, Hexagon, Octagon, RoundedSquare, Oval, Banner, Badge];

    public Kinds Kind { get; }
    public string Name { get; }

    /// The shape's name in the gallery.
    [Localized]
    public string Title { get; }

    /// The first vocabulary that draws the shape.
    public BadgeVocabulary DrawnSince { get; }

    /// Whether the shape's edge is scalloped, and so reads the badge's seal teeth.
    public bool HasTeeth { get; }

    #endregion

    #region Constructors

    private BadgeBackplate(Kinds kind, string name, string title, BadgeVocabulary drawnSince, bool hasTeeth = false) {
        Kind = kind;
        Name = name;
        Title = title;
        DrawnSince = drawnSince;
        HasTeeth = hasTeeth;
    }

    #endregion

    #region Actions - Lookup

    public static BadgeBackplate? Named(string? name) => All.FirstOrDefault(backplate => backplate.Name == name);

    #endregion
}
