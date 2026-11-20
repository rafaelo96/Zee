import SwiftUI

struct BrowserBadgeStudioColors: View {
    let context: BrowserBadgeStudioContext
    let symbol: String
    @State private var rememberedPalette: ColorPalette?

    private var colors: ColorPalette { context.value.badge.layerColors(spaceColors: context.value.colors) }
    private var followsSpace: Binding<Bool> {
        Binding(
            get: { !context.value.badge.usesOwnPalette },
            set: { follows in
                if follows { rememberedPalette = context.value.badge.palette }
                context.badge(\.palette).binding.wrappedValue =
                    follows ? nil : (rememberedPalette ?? context.value.colors)
            })
    }

    var body: some View {
        BrowserBadgeStudioGroup(
            title: "Badge colors", systemImage: "paintpalette", preview: context.compact ? context.value : nil,
            symbol: symbol
        ) {
            let palette = context.badge(\.palette)
            ZeeSettingRow("Follow Space colors", setting: palette.resettable("Badge colors")) {
                Toggle("Follow Space colors", isOn: followsSpace).labelsHidden()
            }
            paletteWells
            if context.value.badge.usesOwnPalette {
                Text("Up to four colors, independent of the sidebar background.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private var paletteWells: some View {
        HStack(spacing: 16) {
            ForEach(colors.indices, id: \.self) { index in
                VStack(spacing: 8) {
                    ColorPicker(
                        "Color \(index + 1)",
                        selection: Binding(
                            get: { colors[index].color },
                            set: { color in
                                var updated = colors
                                updated[index] = BrandColor(color: color)
                                updatePalette(updated)
                            }), supportsOpacity: false
                    ).labelsHidden()
                    Text("\(index + 1)").font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
            if colors.count > 1 {
                Button("Remove last color", systemImage: "minus") {
                    updatePalette(ColorPalette(colors.dropLast()))
                }.labelStyle(.iconOnly).buttonStyle(.borderless)
            }
            if colors.count < maximumColorCount {
                Button("Add color", systemImage: "plus") {
                    updatePalette(colors + [.sand])
                }.labelStyle(.iconOnly).buttonStyle(.borderless)
            }
        }
    }

    private var maximumColorCount: Int {
        context.value.badge.usesOwnPalette
            ? SpaceBadge.maximumPaletteCount : SpaceBranding.maximumColorCount
    }

    private func updatePalette(_ colors: ColorPalette) {
        if context.value.badge.usesOwnPalette {
            context.badge(\.palette).binding.wrappedValue = colors
        } else {
            context.setting(\.colors).binding.wrappedValue = colors
        }
    }
}

struct BrowserBadgeStudioColorRow: View {
    let context: BrowserBadgeStudioContext
    let title: LocalizedStringKey
    let path: WritableKeyPath<SpaceBadge, Int>

    var body: some View {
        let colors = context.value.badge.layerColors(spaceColors: context.value.colors)
        let setting = context.badge(path)
        return ZeeSettingRow(title, setting: setting.resettable(title)) {
            HStack(spacing: 8) {
                ForEach(colors.indices, id: \.self) { index in
                    ZeeSelectableCard(
                        isSelected: setting.wrappedValue == index,
                        accessibilityLabel: Text("\(Text(title)), color \(index + 1)"), density: .swatch
                    ) {
                        setting.binding.wrappedValue = index
                    } content: {
                        Circle().fill(colors[index].color)
                            .frame(width: 22, height: 22)
                            .overlay { Circle().strokeBorder(ZeeColor.subtleBorder) }
                    }
                }
            }
        }
    }
}

struct BrowserBadgeStudioBackground: View {
    let context: BrowserBadgeStudioContext
    let symbol: String
    var body: some View {
        BrowserBadgeStudioGroup(title: "Space background", systemImage: "rectangle.inset.filled") {
            if context.compact {
                BrowserBadgeStudioPreview(branding: context.value, symbol: symbol, compact: true)
            }
            BrowserSpaceColorCanvas(context: context)
            DisclosureGroup("Exact colors") {
                HStack(spacing: 16) {
                    ForEach(BrowserSpaceBrandColorRole.all) { role in
                        BrowserSpacePaletteSlot(
                            role: role, color: context.branding.editorColor(for: role),
                            canAdd: role.slot == context.value.colors.count,
                            canRemove: role.slot == context.value.colors.count - 1 && context.value.colors.count > 1,
                            compact: true, addColor: { context.branding.editorAddColor(for: role) },
                            removeColor: { context.branding.editorRemoveColor(for: role) })
                    }
                }
                .padding(.top, 8)
            }
            backgroundChoices
            if context.value.themeMode == .gradient {
                let angle = context.setting(\.gradientAngle)
                ZeeSettingRow("Gradient angle", setting: angle.resettable("Gradient angle")) {
                    HStack(spacing: 16) {
                        Text("\(Int(angle.wrappedValue.rounded()))°")
                            .monospacedDigit().foregroundStyle(.secondary)
                        BrowserSpaceGradientAngleDial(angle: angle.binding, color: context.value.secondaryColor.color)
                            .frame(width: 72, height: 72)
                    }
                }
            }
            slider("Color intensity", \.bannerStrength)
            slider("Readability fade", \.readabilityFade)
            slider("Folder color intensity", \.folderColorIntensity)
            let text = context.setting(\.textColorMode)
            ZeeSettingRow("Text color", setting: text.resettable("Text color")) {
                Picker("Text color", selection: text.binding) {
                    ForEach(SpaceTextColorMode.all, id: \.self) { Text($0.title).tag($0) }
                }.labelsHidden()
            }
        }
    }

    private var backgroundChoices: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 84), spacing: 10)], spacing: 10) {
            ForEach(SpaceBannerPattern.all, id: \.self) { pattern in
                BrowserBadgeStudioChoice(
                    title: pattern.title,
                    selected: context.value.themeMode == .banner && context.value.bannerPattern == pattern
                ) {
                    context.branding.editorUpdate {
                        $0.themeMode = .banner
                        $0.bannerPattern = pattern
                        $0.hasCustomAppearance = true
                    }
                } artwork: {
                    BrowserSpaceBannerBackground(
                        branding: context.preview {
                            $0.themeMode = .banner
                            $0.bannerPattern = pattern
                        }
                    )
                    .frame(width: 56, height: 48).clipShape(.rect(cornerRadius: 8))
                }
            }
            BrowserBadgeStudioChoice(title: "Gradient", selected: context.value.themeMode == .gradient) {
                context.setting(\.themeMode).binding.wrappedValue = .gradient
            } artwork: {
                BrowserSpaceBannerBackground(branding: context.preview { $0.themeMode = .gradient })
                    .frame(width: 56, height: 48).clipShape(.rect(cornerRadius: 8))
            }
        }
    }

    private func slider(
        _ title: LocalizedStringKey, _ path: WritableKeyPath<SpaceBranding, Double>,
        range: ClosedRange<Double> = 0...1, readout: ZeeSettingSliderReadout = .percent
    ) -> some View {
        BrowserBadgeStudioSlider(title: title, value: context.setting(path), range: range, readout: readout)
    }
}

#if DEBUG
    #Preview("Interactive badge controls") {
        @Previewable @State var branding = BrowserSpaceBrandingPreviewFixture.badgeBranding
        Form {
            BrowserBadgeStudioColors(
                context: BrowserBadgeStudioContext(
                    branding: $branding, defaults: BrowserSpaceBrandingPreviewFixture.badgeBranding, compact: false),
                symbol: "crown.fill")
        }.zeeSettingsForm().frame(width: 480, height: 650)
    }
#endif
