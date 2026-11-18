namespace ZeeCore.Contracts;

/// How a badge's field is divided.
public sealed class BadgeFieldDivision {
    #region Types

    /// Each platform draws each division's geometry, so its renderer switches over the kind.
    public enum Kinds { Plain, PerPale, PerFess, PerBend, PerChevron, Quarterly, PerSaltire, Gyronny, Barry, Paly, Checky }

    #endregion

    #region Variables

    // Titles are one word: they caption gallery cards that already show the division.
    public static readonly BadgeFieldDivision Plain = new(Kinds.Plain, "plain", "Plain", BadgeVocabulary.Baseline);
    public static readonly BadgeFieldDivision PerPale = new(Kinds.PerPale, "perPale", "Vertical", BadgeVocabulary.Baseline);
    public static readonly BadgeFieldDivision PerFess = new(Kinds.PerFess, "perFess", "Horizontal", BadgeVocabulary.Baseline);
    public static readonly BadgeFieldDivision PerBend = new(Kinds.PerBend, "perBend", "Diagonal", BadgeVocabulary.Baseline);
    public static readonly BadgeFieldDivision PerChevron = new(Kinds.PerChevron, "perChevron", "Chevron", BadgeVocabulary.Baseline);
    public static readonly BadgeFieldDivision Quarterly = new(Kinds.Quarterly, "quarterly", "Quartered", BadgeVocabulary.Baseline);
    public static readonly BadgeFieldDivision PerSaltire = new(Kinds.PerSaltire, "perSaltire", "Crossed", BadgeVocabulary.Studio);
    public static readonly BadgeFieldDivision Gyronny = new(Kinds.Gyronny, "gyronny", "Wedges", BadgeVocabulary.Studio, isCounted: true);
    public static readonly BadgeFieldDivision Barry = new(Kinds.Barry, "barry", "Bars", BadgeVocabulary.Studio, isCounted: true);
    public static readonly BadgeFieldDivision Paly = new(Kinds.Paly, "paly", "Stripes", BadgeVocabulary.Studio, isCounted: true);
    public static readonly BadgeFieldDivision Checky = new(Kinds.Checky, "checky", "Checks", BadgeVocabulary.Studio, isCounted: true);

    public static IReadOnlyList<BadgeFieldDivision> All { get; } =
        [Plain, PerPale, PerFess, PerBend, PerChevron, Quarterly, PerSaltire, Gyronny, Barry, Paly, Checky];

    public Kinds Kind { get; }
    public string Name { get; }

    /// The division's name in the gallery.
    [Localized]
    public string Title { get; }

    /// The first vocabulary that draws the division.
    public BadgeVocabulary DrawnSince { get; }

    /// Whether the division repeats a number of pieces, and so reads the
    /// badge's division count.
    public bool IsCounted { get; }

    #endregion

    #region Constructors

    private BadgeFieldDivision(Kinds kind, string name, string title, BadgeVocabulary drawnSince, bool isCounted = false) {
        Kind = kind;
        Name = name;
        Title = title;
        DrawnSince = drawnSince;
        IsCounted = isCounted;
    }

    #endregion

    #region Actions - Lookup

    public static BadgeFieldDivision? Named(string? name) => All.FirstOrDefault(division => division.Name == name);

    #endregion
}
