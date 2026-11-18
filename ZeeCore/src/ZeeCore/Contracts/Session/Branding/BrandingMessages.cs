namespace ZeeCore.Contracts;

#region Queries

/// Branding as a Space keeps it once the core's range rules apply.
public sealed record NormalizedBranding(SpaceBranding Branding);

/// A look in the form the stored session keeps branding in, which every
/// later build reads.
public sealed record StoredLook(string Text);

/// A look read back from its stored form, or nil for text that holds none.
public sealed record RestoredLook(SpaceBranding? Look);

#endregion

#region Models - Zees

/// <summary>
/// A badge's custom figure: a heraldic <see cref="Symbol"/>, or <see cref="Text"/> naming
/// a system symbol, an emoji or the letters of a monogram in its <see cref="Style"/>.
/// </summary>
public sealed record BadgeCharge(BadgeChargeKind Kind, BadgeSymbol? Symbol = null, string? Text = null,
    BadgeMonogramStyle? Style = null);

#endregion

