namespace ZeeCore.Contracts;

/// The letterforms of a monogram charge.
public sealed class BadgeMonogramStyle {
    #region Types

    /// Each platform chooses each style's typeface, so its renderer switches over the kind.
    public enum Kinds { Serif, Sans }

    #endregion

    #region Variables

    public static readonly BadgeMonogramStyle Serif = new(Kinds.Serif, "serif", "Serif", BadgeVocabulary.Studio);
    public static readonly BadgeMonogramStyle Sans = new(Kinds.Sans, "sans", "Sans", BadgeVocabulary.Studio);

    public static IReadOnlyList<BadgeMonogramStyle> All { get; } = [Serif, Sans];

    public Kinds Kind { get; }
    public string Name { get; }

    /// The term's name in the Studio.
    [Localized]
    public string Title { get; }

    /// The first vocabulary that draws it.
    public BadgeVocabulary DrawnSince { get; }

    #endregion

    #region Constructors

    private BadgeMonogramStyle(Kinds kind, string name, string title, BadgeVocabulary drawnSince) {
        Kind = kind;
        Name = name;
        Title = title;
        DrawnSince = drawnSince;
    }

    #endregion

    #region Actions - Lookup

    public static BadgeMonogramStyle? Named(string? name) => All.FirstOrDefault(monogramStyle => monogramStyle.Name == name);

    #endregion
}
