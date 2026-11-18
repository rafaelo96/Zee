import SwiftUI

/// Bindings normalize at the editing boundary, shared by setup drafts and live Spaces.
@MainActor
struct BrowserBadgeStudioContext {
    let branding: Binding<SpaceBranding>
    let defaults: SpaceBranding
    var compact: Bool
    var previewBranding: SpaceBranding?
    var value: SpaceBranding { branding.wrappedValue }

    func preview(_ mutation: (inout SpaceBranding) -> Void) -> SpaceBranding {
        var candidate = previewBranding ?? value
        candidate.iconStyle = .layeredBadge
        mutation(&candidate)
        return candidate.normalized()
    }

    func badge<Value: Equatable>(_ path: WritableKeyPath<SpaceBadge, Value>) -> ZeeSettingValue<Value> {
        ZeeSettingValue(
            Binding(
                get: { value.badge[keyPath: path] },
                set: { next in
                    branding.editorUpdate {
                        $0.badge[keyPath: path] = next
                        $0.hasCustomAppearance = true
                    }
                }), default: defaults.badge[keyPath: path])
    }

    func setting<Value: Equatable>(_ path: WritableKeyPath<SpaceBranding, Value>) -> ZeeSettingValue<Value> {
        ZeeSettingValue(
            Binding(
                get: { value[keyPath: path] },
                set: { next in
                    branding.editorUpdate {
                        $0[keyPath: path] = next
                        $0.hasCustomAppearance = true
                    }
                }), default: defaults[keyPath: path])
    }

    func slider(
        _ title: LocalizedStringKey, _ path: WritableKeyPath<SpaceBadge, Double>,
        range: ClosedRange<Double> = 0...1, readout: ZeeSettingSliderReadout = .percent
    ) -> some View {
        BrowserBadgeStudioSlider(title: title, value: badge(path), range: range, readout: readout)
    }

    func count(_ title: LocalizedStringKey, _ path: WritableKeyPath<SpaceBadge, Int>, range: ClosedRange<Int>)
        -> some View
    {
        let value = badge(path)
        return ZeeSettingRow(title, setting: value.resettable(title)) {
            Stepper(value: value.binding, in: range) { Text(value.wrappedValue.formatted()).monospacedDigit() }
                .fixedSize()
        }
    }

    func picker<Option: Hashable & BrowserSpaceHeraldicTerm>(
        _ title: LocalizedStringKey, _ path: WritableKeyPath<SpaceBadge, Option>, options: [Option]
    ) -> some View {
        let value = badge(path)
        return ZeeSettingRow(title, setting: value.resettable(title)) {
            Picker(title, selection: value.binding) {
                ForEach(options, id: \.self) { Text($0.title).tag($0) }
            }
            .labelsHidden()
            #if os(macOS)
                .fixedSize()
            #endif
        }
    }
}

struct BrowserBadgeStudioSlider: View {
    @Environment(\.badgeStudioEditingChanged) private var editingChanged
    let title: LocalizedStringKey
    let value: ZeeSettingValue<Double>
    var range: ClosedRange<Double> = 0...1
    var readout: ZeeSettingSliderReadout = .percent

    var body: some View {
        ZeeSettingSlider(
            title, value: value, range: range, readout: readout,
            onEditingChanged: editingChanged.callAsFunction
        )
    }
}

/// Small cards keep one scroll owner in Settings and in onboarding.
struct BrowserBadgeStudioGroup<Content: View>: View {
    let title: LocalizedStringResource
    let systemImage: String
    var preview: SpaceBranding? = nil
    var symbol: String = "sparkles"
    @ViewBuilder var content: Content

    init(
        title: LocalizedStringResource, systemImage: String, preview: SpaceBranding? = nil, symbol: String = "sparkles",
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.preview = preview
        self.symbol = symbol
        self.content = content()
    }

    /// The group for one step of making a badge, named and marked as the step is.
    init(
        step: BrowserBadgeStudioStep, preview: SpaceBranding? = nil, symbol: String = "sparkles",
        @ViewBuilder content: () -> Content
    ) {
        self.init(title: step.title, systemImage: step.symbol, preview: preview, symbol: symbol, content: content)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(title)
                    .font(.headline)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                if let preview {
                    BrowserBadgeStudioMark(branding: preview, symbol: symbol, size: 56)
                        .frame(width: 72, height: 64)
                        .background { BrowserSpaceBannerBackground(branding: preview) }
                        .clipShape(.rect(cornerRadius: 12))
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            VStack(alignment: .leading, spacing: 16) { content }
                .padding(20)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.primary.opacity(0.035), in: .rect(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(.primary.opacity(0.055))
                .allowsHitTesting(false)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(title))
    }
}

/// Each choice renders the current composition with just this property changed.
struct BrowserBadgeStudioGallery<Option: Hashable & BrowserSpaceHeraldicTerm>: View {
    let context: BrowserBadgeStudioContext
    let title: LocalizedStringKey
    let path: WritableKeyPath<SpaceBadge, Option>
    let options: [Option]

    var body: some View {
        let value = context.badge(path)
        VStack(alignment: .leading, spacing: 10) {
            ZeeSettingRow(title, setting: value.resettable(title)) {
                Text(value.wrappedValue.title).foregroundStyle(.secondary)
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 84), spacing: 10)], spacing: 10) {
                ForEach(options, id: \.self) { option in
                    BrowserBadgeStudioChoice(title: option.title, selected: option == value.wrappedValue) {
                        value.binding.wrappedValue = option
                    } artwork: {
                        BrowserSpaceBadgeIcon(
                            branding: context.preview {
                                $0.badge[keyPath: path] = option
                            }, size: 52, rasterizesLayers: false
                        )
                        .equatable()
                    }
                }
            }
        }
    }
}

extension EnvironmentValues {
    @Entry var badgeStudioEditingChanged = BrowserBadgeStudioEditingAction()
}

struct BrowserBadgeStudioEditingAction {
    var update: (Bool) -> Void = { _ in }

    func callAsFunction(_ editing: Bool) { update(editing) }
}

struct BrowserBadgeStudioChoice<Artwork: View>: View {
    let title: LocalizedStringResource
    let selected: Bool
    let select: () -> Void
    @ViewBuilder var artwork: Artwork

    var body: some View {
        ZeeSelectableCard(isSelected: selected, accessibilityLabel: Text(title), density: .compact, action: select) {
            VStack(spacing: 4) {
                artwork.frame(width: 64, height: 58)
                // Every tile keeps room for two lines, so a long name wraps
                // where the tile is narrow and the tiles in a row stay even.
                Text(title).font(.caption).lineLimit(2, reservesSpace: true).multilineTextAlignment(.center)
                    .frame(minHeight: 30, alignment: .top)
            }
        }
    }
}
