using System.Text.Json.Nodes;

using ZeeCore.Contracts;
using ZeeCore.Domain;

namespace ZeeCore.Application;

/// A Space's Boosts as the stored session, the sync record and a browser-data
/// file all keep them: one object each, its colors as colors are kept
/// elsewhere, its font by name and its time in the stored form's seconds.
internal static partial class StoredSessionCodec {
    #region Actions - Boosts

    /// The Boosts `node` holds, or null when it holds none. A Boost that does
    /// not read, or that a Space would not keep, is left out, so one a later
    /// build wrote never costs the others.
    internal static IReadOnlyList<Boost>? DecodeBoosts(JsonNode? node) {
        if (node is not JsonArray items) return null;
        List<Boost> boosts = [];
        foreach (var item in items.OfType<JsonObject>().Take(Boost.MaximumPerSpace)) {
            try {
                if (DecodeBoost(item) is { } boost && boosts.All(kept => kept.Id != boost.Id)) boosts.Add(boost);
            } catch (Exception error) when (error is Rejected or BrowserRuleException or InvalidOperationException or FormatException) {
                // Left out, as the summary says.
            }
        }
        return boosts;
    }

    private static Boost? DecodeBoost(JsonObject value) {
        if (!Guid.TryParse(TolerantText(value[Key.Id]), out var id) || TolerantText(value[Key.Domain]) is not { } domain) return null;
        var look = value[Key.Look] as JsonObject;
        BrandColor? Color(string key) => look?[key] is JsonObject color ? DecodeColor(color) : null;
        var boost = new Boost(id, domain, TolerantFlag(value[Key.IsOn]) ?? true, TolerantFlag(value[Key.AllSpaces]) ?? false,
            new(Color(Key.Background), Color(Key.Text), Color(Key.Accent), BoostFont.Named(TolerantText(look?[Key.Font])) ?? BoostFont.Site,
                look?[Key.TextScale] is { } scale ? Number(scale) : 1),
            TolerantText(value[Key.Css]) ?? "", TolerantText(value[Key.Script]) ?? "",
            [.. (value[Key.Hidden] as JsonArray ?? []).Select(TolerantText).OfType<string>()],
            OptionalDate(value[Key.ModifiedAt]) ?? ReferenceEpoch);
        return boost.Validated();
    }

    internal static JsonArray EncodeBoosts(IReadOnlyList<Boost> boosts) => new([.. boosts.Select(boost => (JsonNode)Encode(boost))]);

    private static JsonObject Encode(Boost boost) {
        var look = new JsonObject { [Key.Font] = boost.Look.Font.Name, [Key.TextScale] = boost.Look.TextScale };
        if (boost.Look.Background is { } background) look[Key.Background] = Encode(background);
        if (boost.Look.Text is { } text) look[Key.Text] = Encode(text);
        if (boost.Look.Accent is { } accent) look[Key.Accent] = Encode(accent);
        return new JsonObject {
            [Key.Id] = boost.Id.ToString("D"),
            [Key.Domain] = boost.Domain,
            [Key.IsOn] = boost.IsOn,
            [Key.AllSpaces] = boost.AppliesToAllSpaces,
            [Key.Look] = look,
            [Key.Css] = boost.Css,
            [Key.Script] = boost.Script,
            [Key.Hidden] = new JsonArray([.. boost.HiddenElements.Select(selector => (JsonNode)selector)]),
            [Key.ModifiedAt] = Seconds(boost.ModifiedAt)
        };
    }

    #endregion
}
