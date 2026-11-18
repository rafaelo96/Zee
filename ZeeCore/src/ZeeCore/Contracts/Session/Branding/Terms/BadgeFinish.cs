namespace ZeeCore.Contracts;

/// The surface a badge is rendered with.
public sealed class BadgeFinish {
    #region Types

    /// Each platform paints each finish, so its renderer switches over the kind.
    public enum Kinds { Flat, Sheen, Embossed }

    #endregion

    #region Variables

    public static readonly BadgeFinish Flat = new(Kinds.Flat, "flat", "Flat", BadgeVocabulary.Baseline);
    public static readonly BadgeFinish Sheen = new(Kinds.Sheen, "sheen", "Sheen", BadgeVocabulary.Studio, hasAngle: true);
    public static readonly BadgeFinish Embossed = new(Kinds.Embossed, "embossed", "Embossed", BadgeVocabulary.Studio);

    public static IReadOnlyList<BadgeFinish> All { get; } = [Flat, Sheen, Embossed];

    public Kinds Kind { get; }
    public string Name { get; }

    /// The term's name in the Studio.
    [Localized]
    public string Title { get; }

    /// The first vocabulary that draws it.
    public BadgeVocabulary DrawnSince { get; }

    /// Whether the finish's light falls from a direction, and so reads the badge's sheen angle.
    public bool HasAngle { get; }

    #endregion

    #region Constructors

    private BadgeFinish(Kinds kind, string name, string title, BadgeVocabulary drawnSince, bool hasAngle = false) {
        Kind = kind;
        Name = name;
        Title = title;
        DrawnSince = drawnSince;
        HasAngle = hasAngle;
    }

    #endregion

    #region Actions - Lookup

    public static BadgeFinish? Named(string? name) => All.FirstOrDefault(finish => finish.Name == name);

    #endregion
}
