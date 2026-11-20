import SwiftUI

/// A Space's Badge Studio: the badge on the Space's own sidebar field, and
/// one step of its making at a time, beside the window's live sidebar.
///
/// Given its Space, the studio leads with the Space's customization style.
/// Modern and Simple show their own simpler editors, with the whole studio
/// in Advanced under them.
struct BrowserBadgeForge: View {
    @Binding var branding: SpaceBranding
    @Binding var symbol: String
    @Binding var step: BrowserBadgeStudioStep
    /// The Space's name, for a page that doesn't already let a person edit it.
    var name: Binding<String>? = nil
    /// Whether the page lists the steps, each opening on a page of its own,
    /// in place of the step bar: a phone has no room for eight segments.
    var listsSteps = false
    /// Whether the stage carries the step bar; a step's own page has none.
    var showsStepBar = true
    /// The Space whose customization style the studio shows, or nil for the
    /// whole studio alone.
    var spaceID: UUID? = nil

    @State private var initialAppearance: SpaceBranding?
    @State private var history: [SpaceBranding] = []
    @State private var editingStart: SpaceBranding?
    /// The look Undo put back, which is not itself a change to remember.
    @State private var restoredBranding: SpaceBranding?
    @State private var choosesEmoji = false
    @State private var showsAdvanced = false

    private var context: BrowserBadgeStudioContext {
        BrowserBadgeStudioContext(
            branding: $branding,
            defaults: branding.startingLook ?? initialAppearance ?? branding,
            compact: false, previewBranding: editingStart)
    }

    private var isIcon: Bool { branding.iconStyle == .simpleSymbol }

    /// The step shown: the one chosen, unless an icon has no use for it.
    private var shownStep: BrowserBadgeStudioStep {
        isIcon && step.isBadgeOnly ? .emblem : step
    }

    /// The style the studio shows the Space's look in.
    private var style: BrowserCustomizationStyle {
        spaceID.map { BrowserDeviceAppearanceStore.shared.customizationStyle(for: $0) } ?? .heraldic
    }

    var body: some View {
        BrowserSettingsPane(.spaces) {
            if let spaceID {
                BrowserSpaceStyleSection(spaceID: spaceID, branding: $branding)
            }
            switch style.look.kind {
            case .heraldic:
                studio
            case .modern:
                BrowserSpaceModernEditor(branding: $branding, symbol: $symbol)
                advancedStudio
            case .simple:
                BrowserSpaceSimpleEditor(branding: $branding, symbol: $symbol)
                advancedStudio
            }
        }
        #if os(iOS)
            .modifier(
                BrowserBadgeForgeStepPages(isEnabled: listsSteps) { step in
                    BrowserBadgeForge(branding: $branding, symbol: $symbol, step: .constant(step), showsStepBar: false)
                        .navigationTitle(Text(step.title))
                        .navigationBarTitleDisplayMode(.inline)
                })
        #endif
        #if os(macOS)
            .environment(\.browserSettingsColumnWidth, BrowserBadgeForgeMetrics.columnWidth)
        #endif
        .environment(
            \.badgeStudioEditingChanged,
            BrowserBadgeStudioEditingAction { editing in
                // A drag is one change to undo, and the galleries keep their
                // compositions while it runs.
                if editing {
                    if editingStart == nil { editingStart = branding }
                } else if let start = editingStart {
                    editingStart = nil
                    if start != branding { remember(start) }
                }
            }
        )
        .onAppear { if initialAppearance == nil { initialAppearance = branding } }
        .onChange(of: branding) { previous, current in
            if let restored = restoredBranding {
                restoredBranding = nil
                if current == restored { return }
            }
            guard editingStart == nil else { return }
            remember(previous)
        }
        .accessibilityIdentifier("space-customization-controls")
    }

    // MARK: - Steps

    /// Every step of the studio: listed, or the chosen one under the stage.
    @ViewBuilder private var studio: some View {
        if listsSteps {
            stepList
        } else {
            stepSections
        }
    }

    /// The whole studio, folded under Advanced beneath a simpler editor.
    @ViewBuilder private var advancedStudio: some View {
        BrowserAppearanceAdvancedHeader(isExpanded: $showsAdvanced)
        if showsAdvanced {
            studio
        }
    }

    /// The stage over every step, each showing what it has chosen.
    private var stepList: some View {
        Section {
            ForEach(BrowserBadgeStudioStep.all) { step in
                NavigationLink(value: step) {
                    LabeledContent {
                        Text(step.summary(branding))
                    } label: {
                        Label {
                            Text(step.title)
                        } icon: {
                            Image(systemName: step.symbol)
                        }
                    }
                }
                .disabled(isIcon && step.isBadgeOnly)
                .accessibilityIdentifier("space-forge-step-\(step.name)")
            }
        } header: {
            stageHeader
        }
    }

    @ViewBuilder
    private var stepSections: some View {
        switch shownStep.kind {
        case .start:
            startSections
        case .shape:
            shapeSections
        case .field:
            fieldSections
        case .band:
            bandSections
        case .emblem:
            emblemSections
        case .border:
            borderSections
        case .finish:
            finishSections
        case .sidebar:
            sidebarSections
        }
    }

    // MARK: - Step sections

    private var startSections: some View {
        gallery(SpaceHouse.all, id: \.self) { house in
            BrowserBadgeStudioChoice(title: house.title, selected: house.isWorn(by: branding)) {
                branding = house.applying(to: branding)
            } artwork: {
                badge(house.applying(to: editingStart ?? branding))
            }
        } trailing: {
            ForEach(SpaceScheme.all, id: \.self) { scheme in
                BrowserSpaceSchemeChoice(scheme: scheme, branding: $branding, symbol: symbol)
            }
        }
    }

    @ViewBuilder
    private var shapeSections: some View {
        badgeGallery(\.backplate, BadgeBackplate.all)
        Section {
            context.slider("Edge", \.edgeWidth, range: BadgeMeasure.edgeWidth.range)
            context.slider("Size", \.plateScale, range: BadgeMeasure.plateScale.range)
            if branding.badge.backplate.hasTeeth {
                context.count("Teeth", \.sealTeeth, range: BadgeMeasure.sealTeeth.countRange)
            }
        }
    }

    @ViewBuilder
    private var fieldSections: some View {
        badgeGallery(\.fieldDivision, BadgeFieldDivision.all)
        Section {
            context.count("Repeats", \.divisionCount, range: BadgeMeasure.divisionCount.countRange)
                .disabled(!branding.badge.fieldDivision.isCounted)
        }
    }

    @ViewBuilder
    private var bandSections: some View {
        badgeGallery(\.ordinary, BadgeOrdinary.all)
        Section {
            context.slider("Width", \.ordinaryWidth, range: BadgeMeasure.ordinaryWidth.range)
                .disabled(branding.badge.ordinary == .none)
        }
    }

    @ViewBuilder
    private var emblemSections: some View {
        Section {
            identityRow
        } header: {
            stageHeader
        }
        if isIcon {
            iconSections
        } else {
            Section {
                BrowserBadgeStudioEmblem(context: context, symbol: symbol, isEmbedded: true)
            }
        }
    }

    @ViewBuilder
    private var borderSections: some View {
        badgeGallery(\.trim, BadgeTrim.all)
        Section {
            context.slider("Weight", \.trimWeight, range: BadgeMeasure.trimWeight.range)
                .disabled(branding.badge.trim == .none)
            context.count("Details", \.trimDetail, range: BadgeMeasure.trimDetail.countRange)
                .disabled(!branding.badge.trim.isCounted)
        }
    }

    @ViewBuilder
    private var finishSections: some View {
        badgeGallery(\.finish, BadgeFinish.all)
        Section {
            segmented("Shadow", context.badge(\.depth), options: BadgeDepth.all)
            let outline = context.badge(\.showsOutline)
            ZeeSettingRow("Outline", setting: outline.resettable("Outline")) {
                Toggle("Outline", isOn: outline.binding).labelsHidden()
            }
            if branding.badge.finish.hasAngle {
                context.slider(
                    "Sheen angle", \.sheenAngle, range: BadgeMeasure.sheenAngle.range,
                    readout: .init { "\(Int($0))°" })
            }
        }
    }

    @ViewBuilder
    private var sidebarSections: some View {
        sidebarGallery
        sidebarSection
    }

    private var identityRow: some View {
        let style = context.setting(\.iconStyle)
        return ZeeSettingRow("Identity", setting: style.resettable("Identity")) {
            Picker("Identity", selection: style.binding) {
                Text("Badge").tag(SpaceIconStyle.layeredBadge)
                Text("Icon").tag(SpaceIconStyle.simpleSymbol)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            #if os(macOS)
                .fixedSize()
            #endif
            .accessibilityIdentifier("space-forge-identity")
        }
    }

    @ViewBuilder
    private var iconSections: some View {
        Section {
            BrowserSystemSymbolPicker(
                selection: Binding(
                    get: { BrowserIconSymbol.emoji(from: symbol) == nil ? symbol : "" },
                    set: { symbol = $0 }))
            BrowserArtworkPickerButton(
                title: "Emoji",
                detail: BrowserIconSymbol.emoji(from: symbol) == nil ? Text("Choose an emoji") : Text("Change emoji")
            ) {
                choosesEmoji = true
            } artwork: {
                if let emoji = BrowserIconSymbol.emoji(from: symbol) {
                    Text(emoji)
                } else {
                    Image(systemName: "face.smiling")
                }
            }
            .accessibilityLabel("Choose Emoji")
            .browserIconCustomizationPopover(
                .init(
                    isPresented: $choosesEmoji, title: "Space Icon",
                    currentEmoji: BrowserIconSymbol.emoji(from: symbol),
                    setEmoji: { symbol = BrowserIconSymbol.symbol(forEmoji: $0) }))
        }
    }

    private var sidebarGallery: some View {
        gallery(SpaceBannerPattern.all.map(Optional.some) + [nil], id: \.self) { pattern in
            let selected =
                pattern.map { branding.themeMode == .banner && branding.bannerPattern == $0 }
                ?? (branding.themeMode == .gradient)
            BrowserBadgeStudioChoice(title: pattern?.title ?? "Gradient", selected: selected) {
                context.branding.editorUpdate {
                    if let pattern {
                        $0.themeMode = .banner
                        $0.bannerPattern = pattern
                    } else {
                        $0.themeMode = .gradient
                    }
                    $0.hasCustomAppearance = true
                }
            } artwork: {
                BrowserSpaceBannerBackground(
                    branding: context.preview {
                        if let pattern {
                            $0.themeMode = .banner
                            $0.bannerPattern = pattern
                        } else {
                            $0.themeMode = .gradient
                        }
                    }
                )
                .frame(width: 56, height: 48)
                .clipShape(.rect(cornerRadius: 8))
            }
        }
    }

    private var sidebarSection: some View {
        Section {
            BrowserBadgeStudioSlider(title: "Intensity", value: context.setting(\.bannerStrength))
            if branding.themeMode == .gradient {
                BrowserSpaceGradientAngleRow(
                    angle: context.setting(\.gradientAngle), color: branding.secondaryColor.color)
            }
            BrowserBadgeStudioSlider(title: "Readability fade", value: context.setting(\.readabilityFade))
            BrowserBadgeStudioSlider(title: "Folder colors", value: context.setting(\.folderColorIntensity))
            BrowserBadgeStudioSlider(
                title: "Texture", value: context.setting(\.textureStrength),
                readout: .percent(zero: "None", full: "Full"))
            segmentedText
        }
    }

    private var segmentedText: some View {
        let text = context.setting(\.textColorMode)
        return ZeeSettingRow("Text", setting: text.resettable("Text")) {
            Picker("Text", selection: text.binding) {
                ForEach(SpaceTextColorMode.all, id: \.self) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            #if os(macOS)
                .fixedSize()
            #endif
        }
    }

    // MARK: - Galleries

    private func badgeGallery<Option: Hashable & BrowserSpaceHeraldicTerm>(
        _ path: WritableKeyPath<SpaceBadge, Option>, _ options: [Option]
    ) -> some View {
        let value = context.badge(path)
        return gallery(options, id: \.self) { option in
            BrowserBadgeStudioChoice(title: option.title, selected: option == value.wrappedValue) {
                value.binding.wrappedValue = option
            } artwork: {
                badge(context.preview { $0.badge[keyPath: path] = option })
            }
        }
    }

    private func gallery<Item, ID: Hashable, Tile: View>(
        _ items: [Item], id: KeyPath<Item, ID>, @ViewBuilder tile: @escaping (Item) -> Tile
    ) -> some View {
        gallery(items, id: id, tile: tile) { EmptyView() }
    }

    /// A gallery of `items`' tiles followed by `trailing` tiles of another kind.
    private func gallery<Item, ID: Hashable, Tile: View, Trailing: View>(
        _ items: [Item], id: KeyPath<Item, ID>, @ViewBuilder tile: @escaping (Item) -> Tile,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        Section {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 80), spacing: 8)], spacing: 8
            ) {
                ForEach(items, id: id) { item in tile(item) }
                trailing()
            }
            .padding(.vertical, 4)
            .accessibilityIdentifier("space-forge-gallery")
        } header: {
            stageHeader
        }
    }

    /// The stage and the steps head the page's first section, outside the
    /// grouped boxes, so the badge sits on the Space's field alone.
    private var stageHeader: some View {
        VStack(spacing: 16) {
            BrowserBadgeForgeStage(
                branding: $branding, symbol: symbol, name: name, canUndo: !history.isEmpty, shuffle: shuffle,
                undo: undo, openStep: { step = $0 })
            if showsStepBar && !listsSteps {
                BrowserPlatformBadgeForgeStepBar(
                    step: Binding(get: { shownStep }, set: { step = $0 }),
                    disabledSteps: isIcon ? Set(BrowserBadgeStudioStep.all.filter(\.isBadgeOnly)) : [])
            }
        }
        .textCase(nil)
        .padding(.bottom, 4)
    }

    private func badge(_ look: SpaceBranding) -> some View {
        BrowserSpaceBadgeIcon(branding: look, size: BrowserBadgeForgeMetrics.tileBadgeSize, rasterizesLayers: false)
            .equatable()
    }

    private func segmented<Option: Hashable & BrowserSpaceHeraldicTerm>(
        _ title: LocalizedStringKey, _ value: ZeeSettingValue<Option>, options: [Option]
    ) -> some View {
        ZeeSettingRow(title, setting: value.resettable(title)) {
            Picker(title, selection: value.binding) {
                ForEach(options, id: \.self) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            #if os(macOS)
                .fixedSize()
            #endif
        }
    }

    // MARK: - History

    private func remember(_ previous: SpaceBranding) {
        history.append(previous)
        if history.count > BrowserBadgeForgeHistory.limit { history.removeFirst() }
    }

    private func undo() {
        guard let previous = history.popLast() else { return }
        restoredBranding = previous
        branding = previous
    }

    private func shuffle() {
        branding = Self.shuffled(branding)
    }

    // MARK: - Looks

    /// A new badge and sidebar, every part chosen afresh, in the templates'
    /// tinctures: a dark color for the field, a second for its division, and
    /// light ones for the charges on it, so a light color always sits on a
    /// dark one; the sidebar in dark ones.
    static func shuffled(_ branding: SpaceBranding) -> SpaceBranding {
        let tinctures = Tincture.all.map(\.color)
        let darks = tinctures.filter { $0.luminance < 0.3 }.shuffled()
        let lights = tinctures.filter { $0.luminance > 0.42 }.shuffled()
        guard darks.count > 2, lights.count > 1 else { return branding }
        let chance = { (odds: Double) in Double.random(in: 0..<1) < odds }

        var look = branding
        look.iconStyle = .layeredBadge
        var badge = look.badge
        badge.backplate = BadgeBackplate.all.filter { $0 != .none }.randomElement() ?? .shield
        badge.plateScale = 1
        badge.sealTeeth = Int.random(in: 10...18)
        badge.fieldDivision = chance(0.4) ? .plain : BadgeFieldDivision.all.filter { $0 != .plain }.randomElement()!
        badge.divisionCount = Int.random(in: BadgeMeasure.divisionCount.countRange.lowerBound...6)
        badge.ordinary = chance(0.5) ? .none : BadgeOrdinary.all.filter { $0 != .none }.randomElement()!
        badge.ordinaryWidth = Double.random(in: 0.8...1.2)
        badge.symbol = BadgeSymbol.selectable.randomElement() ?? .dragon
        badge.charge = nil
        badge.chargeLayout = chance(0.75) ? .single : [.paired, .trio].randomElement()!
        badge.chargeScale = badge.chargeLayout == .single ? Double.random(in: 1.05...1.3) : Double.random(in: 0.9...1.1)
        badge.chargeOffset = 0
        badge.trim = BadgeTrim.all.randomElement() ?? .none
        badge.trimWeight = Double.random(in: 0.6...1.1)
        badge.trimDetail = Int.random(in: 10...18)
        badge.edgeWidth = chance(0.5) ? 0 : Double.random(in: 0.2...0.45)
        badge.showsOutline = chance(0.2)
        badge.finish = [.flat, .flat, .sheen, .embossed].randomElement()!
        badge.depth = BadgeDepth.all.randomElement() ?? .soft
        let field = darks[0]
        let second = darks[1]
        let metal = lights[0]
        let border = chance(0.6) ? metal : lights[1]
        badge.palette = [field, second, metal, metal, border, darks[2]]
        for layer in BrowserBadgeForgeLayer.all { badge[keyPath: layer.index] = layer.slot }
        look.badge = badge

        look.themeMode = chance(0.15) ? .gradient : .banner
        look.bannerPattern = SpaceBannerPattern.all.randomElement() ?? .diagonal
        look.gradientAngle = Double(Int.random(in: 0..<8) * 45)
        // The sidebar keeps to dark tinctures, as the templates do, so its
        // text stays light over every band of the pattern.
        look.colors = [darks[2], field, second]
        look.hasCustomAppearance = true
        return look.normalized()
    }
}

private enum BrowserBadgeForgeHistory {
    static let limit = 40
}

#if os(iOS)
    /// Opens a listed step on a page of its own, where the Forge lists its steps.
    private struct BrowserBadgeForgeStepPages<Page: View>: ViewModifier {
        let isEnabled: Bool
        @ViewBuilder let page: (BrowserBadgeStudioStep) -> Page

        func body(content: Content) -> some View {
            if isEnabled {
                content.navigationDestination(for: BrowserBadgeStudioStep.self, destination: page)
            } else {
                content
            }
        }
    }
#endif
