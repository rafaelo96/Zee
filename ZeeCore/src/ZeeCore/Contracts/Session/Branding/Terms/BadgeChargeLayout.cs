namespace ZeeCore.Contracts;

/// How many figures a badge repeats, and how.
public sealed class BadgeChargeLayout {
    #region Types

    /// Each platform places each arrangement's figures, so its renderer switches over the kind.
    public enum Kinds { Single, Paired, Trio, Quad, Ring }

    #endregion

    #region Variables

    public static readonly BadgeChargeLayout Single = new(Kinds.Single, "single", "One", BadgeVocabulary.Baseline);
    public static readonly BadgeChargeLayout Paired = new(Kinds.Paired, "paired", "Two", BadgeVocabulary.Baseline);
    public static readonly BadgeChargeLayout Trio = new(Kinds.Trio, "trio", "Three", BadgeVocabulary.Baseline);
    public static readonly BadgeChargeLayout Quad = new(Kinds.Quad, "quad", "Four", BadgeVocabulary.Studio);
    public static readonly BadgeChargeLayout Ring = new(Kinds.Ring, "ring", "Ring", BadgeVocabulary.Studio);

    public static IReadOnlyList<BadgeChargeLayout> All { get; } = [Single, Paired, Trio, Quad, Ring];

    public Kinds Kind { get; }
    public string Name { get; }

    /// The term's name in the Studio.
    [Localized]
    public string Title { get; }

    /// The first vocabulary that draws it.
    public BadgeVocabulary DrawnSince { get; }

    #endregion

    #region Constructors

    private BadgeChargeLayout(Kinds kind, string name, string title, BadgeVocabulary drawnSince) {
        Kind = kind;
        Name = name;
        Title = title;
        DrawnSince = drawnSince;
    }

    #endregion

    #region Actions - Lookup

    public static BadgeChargeLayout? Named(string? name) => All.FirstOrDefault(chargeLayout => chargeLayout.Name == name);

    #endregion
}
