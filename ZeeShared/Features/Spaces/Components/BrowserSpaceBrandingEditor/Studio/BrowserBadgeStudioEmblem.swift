import SwiftUI

struct BrowserBadgeStudioEmblem: View {
    let context: BrowserBadgeStudioContext
    let symbol: String
    /// Shows the controls without their card or color row, for a studio
    /// that frames them and paints the emblem elsewhere.
    let isEmbedded: Bool
    @State private var source: BadgeChargeKind
    // The fields each emblem source edits, kept while another source is shown.
    @State var search = ""
    @State var showsAll = false
    @State var systemName = "sparkles"
    @State var emoji = "🦁"
    @State var monogram = "C"
    @State var monogramStyle = BadgeMonogramStyle.serif
    @State var choosesEmoji = false

    init(context: BrowserBadgeStudioContext, symbol: String, isEmbedded: Bool = false) {
        self.context = context
        self.symbol = symbol
        self.isEmbedded = isEmbedded
        _source = State(initialValue: context.value.badge.resolvedCharge.kind)
    }

    var body: some View {
        Group {
            if isEmbedded {
                VStack(alignment: .leading, spacing: 16) { controls }
            } else {
                BrowserBadgeStudioGroup(step: .emblem, preview: context.compact ? context.value : nil, symbol: symbol) {
                    controls
                }
            }
        }
        .onAppear { load(context.value.badge.resolvedCharge) }
        .onChange(of: source) { _, _ in commitSource() }
        .onChange(of: context.value.badge.resolvedCharge) { _, charge in
            // Empty in-progress text stays editable instead of removing its field.
            if charge != BadgeCharge.none { load(charge) }
        }
        .onChange(of: systemName) { _, _ in if source == .system { commitSource() } }
        .onChange(of: emoji) { _, _ in if source == .emoji { commitSource() } }
        .onChange(of: monogram) { _, _ in if source == .monogram { commitSource() } }
        .onChange(of: monogramStyle) { _, _ in if source == .monogram { commitSource() } }
    }

    @ViewBuilder private var controls: some View {
        let value = context.badge(\.charge)
        ZeeSettingRow("Source", setting: value.resettable("Emblem")) {
            Picker("Emblem source", selection: $source) {
                ForEach(BadgeChargeKind.all, id: \.self) { Text($0.title).tag($0) }
            }.labelsHidden().fixedSize()
        }
        sourceControls
        if source != .none {
            if source.isTinted, !isEmbedded {
                BrowserBadgeStudioColorRow(context: context, title: "Emblem color", path: \.symbolColorIndex)
            }
            context.picker("Arrangement", \.chargeLayout, options: BadgeChargeLayout.all)
            context.slider("Size", \.chargeScale, range: BadgeMeasure.chargeScale.range)
            context.slider("Vertical offset", \.chargeOffset, range: BadgeMeasure.chargeOffset.range)
            if source.takesWeight, source != .heraldic || context.value.badge.symbol.assetName == nil {
                context.picker("Weight", \.chargeWeight, options: BadgeChargeWeight.all)
            }
        }
    }

    @ViewBuilder private var sourceControls: some View {
        switch source.kind {
        case .heraldic:
            BrowserBadgeStudioHeraldicEmblemControls(context: context, search: $search, showsAll: $showsAll)
        case .system:
            BrowserSystemSymbolPicker(selection: $systemName)
        case .emoji:
            BrowserBadgeStudioEmojiEmblemControls(emoji: $emoji, choosesEmoji: $choosesEmoji)
        case .monogram:
            BrowserBadgeStudioMonogramEmblemControls(monogram: $monogram, monogramStyle: $monogramStyle)
        case .none:
            EmptyView()
        }
    }

    private func commitSource() {
        context.badge(\.charge).binding.wrappedValue = source.studioSource.charge(in: self)
    }

    private func load(_ charge: BadgeCharge) {
        source = charge.kind
        charge.kind.studioSource.load(charge, into: self)
    }
}

#if DEBUG
    #Preview("Interactive badge controls") {
        @Previewable @State var branding = BrowserSpaceBrandingPreviewFixture.badgeBranding
        Form {
            BrowserBadgeStudioEmblem(
                context: BrowserBadgeStudioContext(
                    branding: $branding, defaults: BrowserSpaceBrandingPreviewFixture.badgeBranding, compact: false),
                symbol: "crown.fill")
        }.zeeSettingsForm().frame(width: 480, height: 650)
    }
#endif
