namespace ZeeCore.Contracts;

/// The border drawn around a badge.
public sealed class BadgeTrim {
    #region Types

    /// Each platform draws each border, so its renderer switches over the kind.
    public enum Kinds { None, Shield, Line, DoubleLine, Laurel, Sunburst, DoubleRing, Seal, Beaded }

    #endregion

    #region Variables

    public static readonly BadgeTrim None = new(Kinds.None, "none", "None", BadgeVocabulary.Baseline);
    public static readonly BadgeTrim Shield = new(Kinds.Shield, "shield", "Shield", BadgeVocabulary.Baseline);
    public static readonly BadgeTrim Line = new(Kinds.Line, "line", "Line", BadgeVocabulary.Studio);
    public static readonly BadgeTrim DoubleLine = new(Kinds.DoubleLine, "doubleLine", "Double Line", BadgeVocabulary.Studio);
    public static readonly BadgeTrim Laurel = new(Kinds.Laurel, "laurel", "Laurel", BadgeVocabulary.Baseline);
    public static readonly BadgeTrim Sunburst = new(Kinds.Sunburst, "sunburst", "Sunburst", BadgeVocabulary.Baseline, isCounted: true);
    public static readonly BadgeTrim DoubleRing = new(Kinds.DoubleRing, "doubleRing", "Double Ring", BadgeVocabulary.Baseline);
    public static readonly BadgeTrim Seal = new(Kinds.Seal, "seal", "Seal", BadgeVocabulary.Baseline);
    public static readonly BadgeTrim Beaded = new(Kinds.Beaded, "beaded", "Beaded", BadgeVocabulary.Studio, isCounted: true);

    public static IReadOnlyList<BadgeTrim> All { get; } = [None, Shield, Line, DoubleLine, Laurel, Sunburst, DoubleRing, Seal, Beaded];

    public Kinds Kind { get; }
    public string Name { get; }

    /// The border's name in the gallery.
    [Localized]
    public string Title { get; }

    /// The first vocabulary that draws the border.
    public BadgeVocabulary DrawnSince { get; }

    /// Whether the border is made of repeated elements, and so reads the
    /// badge's trim detail.
    public bool IsCounted { get; }

    #endregion

    #region Constructors

    private BadgeTrim(Kinds kind, string name, string title, BadgeVocabulary drawnSince, bool isCounted = false) {
        Kind = kind;
        Name = name;
        Title = title;
        DrawnSince = drawnSince;
        IsCounted = isCounted;
    }

    #endregion

    #region Actions - Lookup

    public static BadgeTrim? Named(string? name) => All.FirstOrDefault(trim => trim.Name == name);

    #endregion
}
