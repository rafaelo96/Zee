namespace ZeeCore.Contracts;

/// A heraldic figure a badge can carry: its bundled artwork when it has any,
/// else the system glyph that draws it.
public sealed class BadgeSymbol {
    #region Variables

    // The Beetle draws the ladybug glyph and is named for it; Oak draws Leaf's
    // glyph, so it stays readable but isn't offered.
    public static readonly BadgeSymbol Dragon = new("dragon", "Dragon", BadgeVocabulary.Studio, "flame.fill", "BadgeCharge-dragon");
    public static readonly BadgeSymbol Direwolf = new("direwolf", "Direwolf", BadgeVocabulary.Studio, "dog.fill", "BadgeCharge-direwolf");
    public static readonly BadgeSymbol Lion = new("lion", "Lion", BadgeVocabulary.Studio, "pawprint.fill", "BadgeCharge-lion");
    public static readonly BadgeSymbol Stag = new("stag", "Stag", BadgeVocabulary.Studio, "leaf.fill", "BadgeCharge-stag");
    public static readonly BadgeSymbol Raven = new("raven", "Raven", BadgeVocabulary.Studio, "bird.fill", "BadgeCharge-raven");
    public static readonly BadgeSymbol Griffin = new("griffin", "Griffin", BadgeVocabulary.Studio, "bird.fill", "BadgeCharge-griffin");
    public static readonly BadgeSymbol Eagle = new("eagle", "Eagle", BadgeVocabulary.Studio, "shield.fill", "BadgeCharge-eagle");
    public static readonly BadgeSymbol Bear = new("bear", "Bear", BadgeVocabulary.Studio, "shield.fill", "BadgeCharge-bear");
    public static readonly BadgeSymbol Boar = new("boar", "Boar", BadgeVocabulary.Studio, "shield.fill", "BadgeCharge-boar");
    public static readonly BadgeSymbol Fox = new("fox", "Fox", BadgeVocabulary.Studio, "shield.fill", "BadgeCharge-fox");
    public static readonly BadgeSymbol Horse = new("horse", "Horse", BadgeVocabulary.Studio, "shield.fill", "BadgeCharge-horse");
    public static readonly BadgeSymbol Unicorn = new("unicorn", "Unicorn", BadgeVocabulary.Studio, "shield.fill", "BadgeCharge-unicorn");
    public static readonly BadgeSymbol Wyvern = new("wyvern", "Wyvern", BadgeVocabulary.Studio, "shield.fill", "BadgeCharge-wyvern");
    public static readonly BadgeSymbol Hydra = new("hydra", "Hydra", BadgeVocabulary.Studio, "shield.fill", "BadgeCharge-hydra");
    public static readonly BadgeSymbol Serpent = new("serpent", "Serpent", BadgeVocabulary.Studio, "shield.fill", "BadgeCharge-serpent");
    public static readonly BadgeSymbol Kraken = new("kraken", "Kraken", BadgeVocabulary.Studio, "shield.fill", "BadgeCharge-kraken");
    public static readonly BadgeSymbol Seahorse = new("seahorse", "Seahorse", BadgeVocabulary.Studio, "shield.fill", "BadgeCharge-seahorse");
    public static readonly BadgeSymbol Scorpion = new("scorpion", "Scorpion", BadgeVocabulary.Studio, "shield.fill", "BadgeCharge-scorpion");
    public static readonly BadgeSymbol Bat = new("bat", "Bat", BadgeVocabulary.Studio, "shield.fill", "BadgeCharge-bat");
    public static readonly BadgeSymbol Falcon = new("falcon", "Falcon", BadgeVocabulary.Studio, "shield.fill", "BadgeCharge-falcon");
    public static readonly BadgeSymbol Rose = new("rose", "Rose", BadgeVocabulary.Studio, "shield.fill", "BadgeCharge-rose");
    public static readonly BadgeSymbol Lily = new("lily", "Fleur-de-lis", BadgeVocabulary.Studio, "shield.fill", "BadgeCharge-lily");
    public static readonly BadgeSymbol Pine = new("pine", "Pine", BadgeVocabulary.Studio, "shield.fill", "BadgeCharge-pine");
    public static readonly BadgeSymbol Willow = new("willow", "Willow", BadgeVocabulary.Studio, "shield.fill", "BadgeCharge-willow");
    public static readonly BadgeSymbol Swords = new("swords", "Crossed Swords", BadgeVocabulary.Studio, "shield.fill", "BadgeCharge-swords");
    public static readonly BadgeSymbol Axes = new("axes", "Crossed Axes", BadgeVocabulary.Studio, "shield.fill", "BadgeCharge-axes");
    public static readonly BadgeSymbol Sword = new("sword", "Sword", BadgeVocabulary.Studio, "shield.fill", "BadgeCharge-sword");
    public static readonly BadgeSymbol Trident = new("trident", "Trident", BadgeVocabulary.Studio, "shield.fill", "BadgeCharge-trident");
    public static readonly BadgeSymbol Anchor = new("anchor", "Anchor", BadgeVocabulary.Studio, "shield.fill", "BadgeCharge-anchor");
    public static readonly BadgeSymbol Castle = new("castle", "Castle", BadgeVocabulary.Studio, "shield.fill", "BadgeCharge-castle");
    public static readonly BadgeSymbol Scales = new("scales", "Scales", BadgeVocabulary.Studio, "shield.fill", "BadgeCharge-scales");
    public static readonly BadgeSymbol DragonHead = new("dragonHead", "Dragon Head", BadgeVocabulary.Studio, "shield.fill", "BadgeCharge-dragonHead");
    public static readonly BadgeSymbol Hound = new("hound", "Hound", BadgeVocabulary.ExpandedCharges, "dog.fill", null);
    public static readonly BadgeSymbol Paw = new("paw", "Paw", BadgeVocabulary.ExpandedCharges, "pawprint.fill", null);
    public static readonly BadgeSymbol Hare = new("hare", "Hare", BadgeVocabulary.Baseline, "hare.fill", null);
    public static readonly BadgeSymbol Bird = new("bird", "Bird", BadgeVocabulary.Baseline, "bird.fill", null);
    public static readonly BadgeSymbol Fish = new("fish", "Fish", BadgeVocabulary.Baseline, "fish.fill", null);
    public static readonly BadgeSymbol Bee = new("bee", "Beetle", BadgeVocabulary.Baseline, "ladybug.fill", null);
    public static readonly BadgeSymbol Shell = new("shell", "Shell", BadgeVocabulary.Baseline, "fossil.shell.fill", null);
    public static readonly BadgeSymbol Sun = new("sun", "Sun", BadgeVocabulary.Baseline, "sun.max.fill", null);
    public static readonly BadgeSymbol RisingSun = new("risingSun", "Rising Sun", BadgeVocabulary.ExpandedCharges, "sun.horizon.fill", null);
    public static readonly BadgeSymbol Crescent = new("crescent", "Crescent", BadgeVocabulary.Baseline, "moon.fill", null);
    public static readonly BadgeSymbol Star = new("star", "Star", BadgeVocabulary.Baseline, "star.fill", null);
    public static readonly BadgeSymbol Sparkles = new("sparkles", "Sparkles", BadgeVocabulary.Baseline, "sparkles", null);
    public static readonly BadgeSymbol Lightning = new("lightning", "Lightning", BadgeVocabulary.Baseline, "bolt.fill", null);
    public static readonly BadgeSymbol Flame = new("flame", "Flame", BadgeVocabulary.Baseline, "flame.fill", null);
    public static readonly BadgeSymbol Snowflake = new("snowflake", "Snowflake", BadgeVocabulary.ExpandedCharges, "snowflake", null);
    public static readonly BadgeSymbol Drop = new("drop", "Drop", BadgeVocabulary.ExpandedCharges, "drop.fill", null);
    public static readonly BadgeSymbol Mountain = new("mountain", "Mountain", BadgeVocabulary.Baseline, "mountain.2.fill", null);
    public static readonly BadgeSymbol Tree = new("tree", "Tree", BadgeVocabulary.Baseline, "tree.fill", null);
    public static readonly BadgeSymbol Oak = new("oak", "Oak", BadgeVocabulary.Baseline, "leaf.fill", null, isOffered: false);
    public static readonly BadgeSymbol Leaf = new("leaf", "Leaf", BadgeVocabulary.Baseline, "leaf.fill", null);
    public static readonly BadgeSymbol Fern = new("fern", "Frond", BadgeVocabulary.Baseline, "laurel.leading", null);
    public static readonly BadgeSymbol Flower = new("flower", "Flower", BadgeVocabulary.ExpandedCharges, "camera.macro", null);
    public static readonly BadgeSymbol Waves = new("waves", "Waves", BadgeVocabulary.Baseline, "water.waves", null);
    public static readonly BadgeSymbol Tower = new("tower", "Tower", BadgeVocabulary.Baseline, "building.columns.fill", null);
    public static readonly BadgeSymbol Book = new("book", "Book", BadgeVocabulary.Baseline, "book.closed.fill", null);
    public static readonly BadgeSymbol Key = new("key", "Key", BadgeVocabulary.Baseline, "key.fill", null);
    public static readonly BadgeSymbol Hammer = new("hammer", "Hammer", BadgeVocabulary.Baseline, "hammer.fill", null);
    public static readonly BadgeSymbol Compass = new("compass", "Compass", BadgeVocabulary.Baseline, "location.north.circle.fill", null);
    public static readonly BadgeSymbol Sailboat = new("sailboat", "Sailboat", BadgeVocabulary.Baseline, "sailboat.fill", null);
    public static readonly BadgeSymbol Crown = new("crown", "Crown", BadgeVocabulary.ExpandedCharges, "crown.fill", null);
    public static readonly BadgeSymbol Horn = new("horn", "Horn", BadgeVocabulary.ExpandedCharges, "horn.fill", null);
    public static readonly BadgeSymbol CrossedBanners = new("crossedBanners", "Banners", BadgeVocabulary.ExpandedCharges, "flag.2.crossed.fill", null);

    public static IReadOnlyList<BadgeSymbol> All { get; } = [
        Dragon, Direwolf, Lion, Stag, Raven, Griffin, Eagle, Bear, Boar, Fox, Horse, Unicorn, Wyvern, Hydra, Serpent,
        Kraken, Seahorse, Scorpion, Bat, Falcon, Rose, Lily, Pine, Willow, Swords, Axes, Sword, Trident, Anchor, Castle,
        Scales, DragonHead, Hound, Paw, Hare, Bird, Fish, Bee, Shell, Sun, RisingSun, Crescent, Star, Sparkles, Lightning,
        Flame, Snowflake, Drop, Mountain, Tree, Oak, Leaf, Fern, Flower, Waves, Tower, Book, Key, Hammer, Compass, Sailboat,
        Crown, Horn, CrossedBanners
    ];

    /// The figure a badge draws when it names none this build can read.
    public static BadgeSymbol Fallback => Mountain;

    public string Name { get; }

    /// The figure's name in the gallery.
    [Localized]
    public string Title { get; }

    /// The first vocabulary that draws the figure.
    public BadgeVocabulary DrawnSince { get; }

    /// The system glyph that draws the figure where it has no artwork.
    public string SystemImage { get; }

    /// The bundled artwork that draws the figure, if it has any.
    public string? AssetName { get; }

    /// Whether the gallery offers the figure.
    public bool IsOffered { get; }

    #endregion

    #region Constructors

    private BadgeSymbol(string name, string title, BadgeVocabulary drawnSince, string systemImage, string? assetName,
        bool isOffered = true) {
        Name = name;
        Title = title;
        DrawnSince = drawnSince;
        SystemImage = systemImage;
        AssetName = assetName;
        IsOffered = isOffered;
    }

    #endregion

    #region Actions - Lookup

    public static BadgeSymbol? Named(string? name) => All.FirstOrDefault(symbol => symbol.Name == name);

    #endregion
}
