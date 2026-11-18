namespace ZeeCore.Contracts;

/// The band or cross laid over a badge's field.
public sealed class BadgeOrdinary {
    #region Types

    /// Each platform draws each band's path, so its renderer switches over the kind.
    public enum Kinds { None, Pale, Fess, Bend, Chevron, Cross, Saltire, Chief, Bordure, Pall, Pile, Canton, Roundel }

    #endregion

    #region Variables

    public static readonly BadgeOrdinary None = new(Kinds.None, "none", "None", BadgeVocabulary.Baseline);
    public static readonly BadgeOrdinary Pale = new(Kinds.Pale, "pale", "Pale", BadgeVocabulary.Baseline);
    public static readonly BadgeOrdinary Fess = new(Kinds.Fess, "fess", "Fess", BadgeVocabulary.Baseline);
    public static readonly BadgeOrdinary Bend = new(Kinds.Bend, "bend", "Bend", BadgeVocabulary.Baseline);
    public static readonly BadgeOrdinary Chevron = new(Kinds.Chevron, "chevron", "Chevron", BadgeVocabulary.Baseline);
    public static readonly BadgeOrdinary Cross = new(Kinds.Cross, "cross", "Cross", BadgeVocabulary.Baseline);
    public static readonly BadgeOrdinary Saltire = new(Kinds.Saltire, "saltire", "Saltire", BadgeVocabulary.Baseline);
    public static readonly BadgeOrdinary Chief = new(Kinds.Chief, "chief", "Chief", BadgeVocabulary.Baseline);
    public static readonly BadgeOrdinary Bordure = new(Kinds.Bordure, "bordure", "Bordure", BadgeVocabulary.Baseline);
    public static readonly BadgeOrdinary Pall = new(Kinds.Pall, "pall", "Pall", BadgeVocabulary.Studio);
    public static readonly BadgeOrdinary Pile = new(Kinds.Pile, "pile", "Pile", BadgeVocabulary.Studio);
    public static readonly BadgeOrdinary Canton = new(Kinds.Canton, "canton", "Canton", BadgeVocabulary.Studio);
    public static readonly BadgeOrdinary Roundel = new(Kinds.Roundel, "roundel", "Roundel", BadgeVocabulary.Studio);

    public static IReadOnlyList<BadgeOrdinary> All { get; } =
        [None, Pale, Fess, Bend, Chevron, Cross, Saltire, Chief, Bordure, Pall, Pile, Canton, Roundel];

    public Kinds Kind { get; }
    public string Name { get; }

    /// The band's name in the gallery.
    [Localized]
    public string Title { get; }

    /// The first vocabulary that draws the band.
    public BadgeVocabulary DrawnSince { get; }

    #endregion

    #region Constructors

    private BadgeOrdinary(Kinds kind, string name, string title, BadgeVocabulary drawnSince) {
        Kind = kind;
        Name = name;
        Title = title;
        DrawnSince = drawnSince;
    }

    #endregion

    #region Actions - Lookup

    public static BadgeOrdinary? Named(string? name) => All.FirstOrDefault(ordinary => ordinary.Name == name);

    #endregion
}
