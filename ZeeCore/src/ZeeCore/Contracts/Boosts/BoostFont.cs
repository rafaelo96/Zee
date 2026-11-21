namespace ZeeCore.Contracts;

/// The font a Boost gives its site's text: the site's own, or one of the
/// Mac's families. A font travels as its index in `All`, so `All` is
/// append-only, and a Boost stores it by `Name`.
public sealed class BoostFont {
    #region Static Variables

    public static readonly BoostFont Site = new(name: "site", title: "Site's Own", family: null);
    public static readonly BoostFont System = new(name: "system", title: "System",
        family: "-apple-system, BlinkMacSystemFont, system-ui, sans-serif");
    public static readonly BoostFont Serif = new(name: "serif", title: "Serif", family: "\"New York\", ui-serif, Georgia, serif");
    public static readonly BoostFont Rounded = new(name: "rounded", title: "Rounded", family: "ui-rounded, \"SF Pro Rounded\", system-ui, sans-serif");
    public static readonly BoostFont Mono = new(name: "mono", title: "Monospaced", family: "ui-monospace, \"SF Mono\", Menlo, monospace");

    /// The fonts, in the order the editor offers them.
    public static IReadOnlyList<BoostFont> All { get; } = [Site, System, Serif, Rounded, Mono];

    #endregion

    #region Variables

    public string Name { get; }

    /// What the editor calls the font.
    [Localized]
    public string Title { get; }

    public string TitleComment { get; } = "A font a Boost can give a website's text.";

    /// The CSS families the font asks for, or null to keep the site's own.
    public string? Family { get; }

    #endregion

    #region Constructors

    private BoostFont(string name, string title, string? family) {
        Name = name;
        Title = title;
        Family = family;
    }

    #endregion

    #region Actions - Lookup

    public static BoostFont? Named(string? name) => All.FirstOrDefault(font => font.Name == name);

    #endregion
}
