namespace ZeeCore.Contracts;

/// How far a badge stands off the banner.
public sealed class BadgeDepth {
    #region Types

    /// Each platform casts each depth's shadow, so its renderer switches over the kind.
    public enum Kinds { None, Soft, Lifted }

    #endregion

    #region Variables

    public static readonly BadgeDepth None = new(Kinds.None, "none", "None", BadgeVocabulary.Baseline);
    public static readonly BadgeDepth Soft = new(Kinds.Soft, "soft", "Soft", BadgeVocabulary.Studio);
    public static readonly BadgeDepth Lifted = new(Kinds.Lifted, "lifted", "Lifted", BadgeVocabulary.Studio);

    public static IReadOnlyList<BadgeDepth> All { get; } = [None, Soft, Lifted];

    public Kinds Kind { get; }
    public string Name { get; }

    /// The term's name in the Studio.
    [Localized]
    public string Title { get; }

    /// The first vocabulary that draws it.
    public BadgeVocabulary DrawnSince { get; }

    #endregion

    #region Constructors

    private BadgeDepth(Kinds kind, string name, string title, BadgeVocabulary drawnSince) {
        Kind = kind;
        Name = name;
        Title = title;
        DrawnSince = drawnSince;
    }

    #endregion

    #region Actions - Lookup

    public static BadgeDepth? Named(string? name) => All.FirstOrDefault(depth => depth.Name == name);

    #endregion
}
