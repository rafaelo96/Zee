namespace ZeeCore.Contracts;

/// A number that sizes, counts or turns part of a zee: the range the
/// renderer draws it in, the value it takes unless set, and the badges it
/// shapes at all.
public sealed class BadgeMeasure {
    #region Variables

    public static readonly BadgeMeasure PlateScale = new("plateScale", 0.7, 1.15, 1, badge => badge.PlateScale);
    public static readonly BadgeMeasure EdgeWidth = new("edgeWidth", 0, 1, 0, badge => badge.EdgeWidth);
    public static readonly BadgeMeasure DivisionCount = new("divisionCount", 2, 8, SpaceBadge.DefaultDivisionCount, badge => badge.DivisionCount,
        badge => badge.FieldDivision.IsCounted, isCount: true);
    public static readonly BadgeMeasure OrdinaryWidth = new("ordinaryWidth", 0.5, 1.6, 1, badge => badge.OrdinaryWidth);
    public static readonly BadgeMeasure TrimWeight = new("trimWeight", 0.5, 2, 1, badge => badge.TrimWeight);
    public static readonly BadgeMeasure TrimDetail = new("trimDetail", 6, 24, SpaceBadge.DefaultTrimDetail, badge => badge.TrimDetail,
        badge => badge.Trim.IsCounted, isCount: true);
    public static readonly BadgeMeasure ChargeScale = new("chargeScale", 0.6, 1.5, 1, badge => badge.ChargeScale);
    public static readonly BadgeMeasure ChargeOffset = new("chargeOffset", -0.2, 0.2, 0, badge => badge.ChargeOffset);
    public static readonly BadgeMeasure SheenAngle = new("sheenAngle", 0, 360, 45, badge => badge.SheenAngle);
    public static readonly BadgeMeasure SealTeeth = new("sealTeeth", 6, 24, 12, badge => badge.SealTeeth,
        badge => badge.Backplate.HasTeeth, isCount: true);

    public static IReadOnlyList<BadgeMeasure> All { get; } =
        [PlateScale, EdgeWidth, DivisionCount, OrdinaryWidth, TrimWeight, TrimDetail, ChargeScale, ChargeOffset, SheenAngle, SealTeeth];

    public string Name { get; }
    public double Minimum { get; }
    public double Maximum { get; }

    /// The value a badge takes unless set, and which the Studio vocabulary is
    /// needed to draw it away from.
    public double Default { get; }

    /// Whether the measure counts whole pieces rather than sizing them.
    public bool IsCount { get; }

    private readonly Func<SpaceBadge, double> value;
    private readonly Func<SpaceBadge, bool> shapes;

    #endregion

    #region Constructors

    private BadgeMeasure(string name, double minimum, double maximum, double defaultValue, Func<SpaceBadge, double> value,
        Func<SpaceBadge, bool>? shapes = null, bool isCount = false) {
        Name = name;
        Minimum = minimum;
        Maximum = maximum;
        Default = defaultValue;
        IsCount = isCount;
        this.value = value;
        this.shapes = shapes ?? (_ => true);
    }

    #endregion

    #region Actions - Lookup

    public static BadgeMeasure? Named(string? name) => All.FirstOrDefault(measure => measure.Name == name);

    #endregion

    #region Actions - Values

    /// `measure` within the range; one that is not a number takes the default.
    public double Clamped(double measure) => double.IsFinite(measure) ? Math.Clamp(measure, Minimum, Maximum) : Default;

    /// A count within the range.
    public int Clamped(int count) => Math.Clamp(count, (int)Minimum, (int)Maximum);

    /// Whether `zee` draws this measure away from its default.
    public bool IsMoved(SpaceBadge badge) {
        ArgumentNullException.ThrowIfNull(badge);
        return shapes(badge) && value(badge) != Default;
    }

    #endregion
}
