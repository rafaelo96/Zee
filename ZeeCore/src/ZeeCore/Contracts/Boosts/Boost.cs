using System.Globalization;
using System.Text;

namespace ZeeCore.Contracts;

#region Types

/// How a Boost restyles its site: the colors it paints the page's background,
/// text and links in, or null to leave each as the site has it, the font its
/// text wears, and how much larger or smaller its text reads.
public sealed record BoostLook(BrandColor? Background, BrandColor? Text, BrandColor? Accent, BoostFont Font, double TextScale) {
    #region Static Variables

    /// A look that changes nothing.
    public static BoostLook Unchanged { get; } = new(null, null, null, BoostFont.Site, 1);

    public const double MinimumTextScale = 0.5;
    public const double MaximumTextScale = 2;

    #endregion
}

/// What a page asks of the Boosts for its address: each Boost's stylesheet,
/// which the page keeps in its documents, and its script, which runs once in
/// each document, in a world of its own the page cannot reach.
public sealed record BoostScript(Guid Id, string Stylesheet, string Script);

/// A Boost's rule broke: it names no site Zee can match, or it holds more
/// than a Boost keeps.
public sealed record BoostDomainInvalid : Rejection;

public sealed record BoostTooLarge(int MaximumBytes, int MaximumHiddenElements) : Rejection;

/// A Boost names one the Space does not hold.
public sealed record UnknownBoost(Guid BoostId) : Rejection;

/// A Space holds as many Boosts as it keeps.
public sealed record BoostsFull(int Maximum) : Rejection;

#endregion

/// A person's restyling of one site, as Arc's Boosts did: a look the simple
/// editor makes, the elements they hid, and their own stylesheet and script.
/// A Boost belongs to the Space it was made in and applies to its site and
/// every subdomain of it, in that Space, or in every Space when
/// `AppliesToAllSpaces`. It travels with the Space's settings, so it syncs,
/// exports and goes with the Space.
public sealed record Boost(Guid Id, string Domain, bool IsOn, bool AppliesToAllSpaces, BoostLook Look, string Css, string Script,
    IReadOnlyList<string> HiddenElements, DateTimeOffset ModifiedAt) {
    #region Static Variables

    /// The most bytes a Boost's stylesheet or script holds, each.
    public const int MaximumSourceBytes = 64 * 1024;
    /// The most elements a Boost hides.
    public const int MaximumHiddenElements = 200;
    /// The longest selector a hidden element keeps.
    public const int MaximumSelectorLength = 1_024;
    /// The most Boosts a Space holds.
    public const int MaximumPerSpace = 200;
    /// The longest site name a Boost names.
    public const int MaximumDomainLength = 253;

    #endregion

    #region Initializers

    /// A Boost for the site `host` names, made now, which changes nothing yet.
    /// Null when `host` names no site a Boost can match.
    public static Boost? For(Guid id, string host, DateTimeOffset now) =>
        Normalized(host) is { } domain ? new(id, domain, IsOn: true, AppliesToAllSpaces: false, BoostLook.Unchanged, "", "", [], now) : null;

    #endregion

    #region Actions - Matching

    /// The site a host names as a Boost matches it: lowercased, without a
    /// leading `www.` or trailing dot. Null for one no Boost can match: an
    /// address, a name without a dot or one too long.
    public static string? Normalized(string? host) {
        if (string.IsNullOrWhiteSpace(host)) return null;
        string name = host.Trim().TrimEnd('.').ToLowerInvariant();
        if (name.StartsWith("www.", StringComparison.Ordinal)) name = name[4..];
        if (name.Length is 0 or > MaximumDomainLength || !name.Contains('.', StringComparison.Ordinal)) return null;
        if (name.Any(character => !(char.IsAsciiLetterOrDigit(character) || character is '-' or '.')) || name.Contains("..", StringComparison.Ordinal))
            return null;
        return name;
    }

    /// Whether the Boost applies to a page at `host`: its site, or a subdomain
    /// of it, never a name that merely ends the same way.
    public bool Matches(string? host) {
        if (Normalized(host) is not { } name) return false;
        return name == Domain || name.EndsWith("." + Domain, StringComparison.Ordinal);
    }

    #endregion

    #region Actions - Styling

    /// The stylesheet the Boost puts in each document: its look, then the
    /// elements it hides, then the person's own stylesheet, so theirs has the
    /// last word.
    public string Stylesheet() {
        var sheet = new StringBuilder();
        var look = Look;
        if (look.Background is { } background)
            sheet.Append("html, body { background-color: ").Append(Rgba(background)).Append(" !important; }\n");
        if (look.Text is { } text)
            sheet.Append("body, body :is(p, li, td, th, dd, dt, span, div, h1, h2, h3, h4, h5, h6, blockquote, figcaption) { color: ")
                .Append(Rgba(text)).Append(" !important; }\n");
        if (look.Accent is { } accent) sheet.Append("a, a * { color: ").Append(Rgba(accent)).Append(" !important; }\n");
        if (look.Font.Family is { } family) sheet.Append("body, body * { font-family: ").Append(family).Append(" !important; }\n");
        if (Math.Abs(look.TextScale - 1) > 0.001)
            sheet.Append("html { zoom: ").Append(look.TextScale.ToString("0.###", CultureInfo.InvariantCulture)).Append("; }\n");
        if (HiddenElements.Count > 0) sheet.Append(string.Join(",\n", HiddenElements)).Append(" { display: none !important; }\n");
        if (Css.Length > 0) sheet.Append(Css).Append('\n');
        return sheet.ToString();
    }

    private static string Rgba(BrandColor color) => string.Create(CultureInfo.InvariantCulture,
        $"rgba({Channel(color.Red)}, {Channel(color.Green)}, {Channel(color.Blue)}, {Math.Clamp(color.Alpha, 0, 1):0.###})");

    private static int Channel(double value) => (int)Math.Round(Math.Clamp(value, 0, 1) * 255, MidpointRounding.AwayFromZero);

    /// What a page runs for the Boost, or null while it is off.
    public BoostScript? Applied() => IsOn ? new(Id, Stylesheet(), Script) : null;

    #endregion

    #region Actions - Validation

    /// The Boost as a Space keeps it: its site normalized, its text scale in
    /// range and its hidden elements each once, without blank ones. Throws
    /// `Rejected` with `BoostDomainInvalid` for a site no Boost can match and
    /// `BoostTooLarge` for one holding more than a Boost keeps.
    public Boost Validated() {
        var domain = Normalized(Domain) ?? throw new Rejected(new BoostDomainInvalid());
        var hidden = HiddenElements.Select(selector => selector.Trim()).Where(selector => selector.Length > 0)
            .Distinct(StringComparer.Ordinal).ToArray();
        if (Encoding.UTF8.GetByteCount(Css) > MaximumSourceBytes || Encoding.UTF8.GetByteCount(Script) > MaximumSourceBytes
            || hidden.Length > MaximumHiddenElements || hidden.Any(selector => selector.Length > MaximumSelectorLength
                || selector.Contains('{', StringComparison.Ordinal) || selector.Contains('}', StringComparison.Ordinal)))
            throw new Rejected(new BoostTooLarge(MaximumSourceBytes, MaximumHiddenElements));
        var scale = double.IsFinite(Look.TextScale)
            ? Math.Clamp(Look.TextScale, BoostLook.MinimumTextScale, BoostLook.MaximumTextScale) : 1;
        return this with { Domain = domain, HiddenElements = hidden, Look = Look with { TextScale = scale } };
    }

    #endregion
}
