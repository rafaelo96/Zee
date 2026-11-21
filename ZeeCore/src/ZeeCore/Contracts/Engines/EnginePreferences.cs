namespace ZeeCore.Contracts;

/// The device's default and website engine choices. Null follows the
/// composition's recommended default. `SavesBattery` opens new pages in
/// WebKit while the system saves power, unless a site's or Space's choice
/// decides. They never become sync records.
public sealed record EnginePreferences(EngineKind? DefaultEngine, IReadOnlyList<SiteEngineRule> Rules, bool SavesBattery = false) {
    #region Variables

    public IReadOnlyList<SiteEngineRule> Rules {
        get;
        init => field = [.. value];
    } = [.. Rules];

    #endregion

    #region Actions - Equality

    public bool Equals(EnginePreferences? other) => other is not null
        && DefaultEngine == other.DefaultEngine && Rules.SequenceEqual(other.Rules) && SavesBattery == other.SavesBattery;

    public override int GetHashCode() => HashCode.Combine(DefaultEngine, Rules.Count);

    #endregion
}
