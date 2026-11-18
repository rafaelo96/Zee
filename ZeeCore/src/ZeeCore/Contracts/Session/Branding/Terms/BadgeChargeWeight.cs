namespace ZeeCore.Contracts;

/// The stroke weight of a badge's figure.
public sealed class BadgeChargeWeight {
    #region Types

    /// Each platform maps each weight to its own font weight, so its renderer switches over the kind.
    public enum Kinds { Light, Regular, Bold }

    #endregion

    #region Variables

    public static readonly BadgeChargeWeight Light = new(Kinds.Light, "light", "Light", BadgeVocabulary.Studio);
    public static readonly BadgeChargeWeight Regular = new(Kinds.Regular, "regular", "Regular", BadgeVocabulary.Studio);
    public static readonly BadgeChargeWeight Bold = new(Kinds.Bold, "bold", "Bold", BadgeVocabulary.Baseline);

    public static IReadOnlyList<BadgeChargeWeight> All { get; } = [Light, Regular, Bold];

    public Kinds Kind { get; }
    public string Name { get; }

    /// The term's name in the Studio.
    [Localized]
    public string Title { get; }

    /// The first vocabulary that draws it.
    public BadgeVocabulary DrawnSince { get; }

    #endregion

    #region Constructors

    private BadgeChargeWeight(Kinds kind, string name, string title, BadgeVocabulary drawnSince) {
        Kind = kind;
        Name = name;
        Title = title;
        DrawnSince = drawnSince;
    }

    #endregion

    #region Actions - Lookup

    public static BadgeChargeWeight? Named(string? name) => All.FirstOrDefault(chargeWeight => chargeWeight.Name == name);

    #endregion
}
