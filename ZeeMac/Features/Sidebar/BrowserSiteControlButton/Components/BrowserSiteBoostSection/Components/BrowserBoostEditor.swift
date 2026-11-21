import SwiftUI

/// The editor of one Boost: the colors it paints the site's background, text
/// and links in, its font and text size, the elements it hides, whether it
/// reaches every Space, and, under Advanced, the person's own stylesheet and
/// script. Each simple change applies at once; the stylesheet and script apply
/// when the person says so.
struct BrowserBoostEditor: View {
    // MARK: - Types

    /// A color the editor sets.
    private enum Paint: CaseIterable {
        case background
        case text
        case accent

        var title: LocalizedStringKey {
            switch self {
            case .background: "Background"
            case .text: "Text"
            case .accent: "Links"
            }
        }

        func color(of look: BoostLook) -> BrandColor? {
            switch self {
            case .background: look.background
            case .text: look.text
            case .accent: look.accent
            }
        }

        func painting(_ look: BoostLook, with color: BrandColor?) -> BoostLook {
            var look = look
            switch self {
            case .background: look.background = color
            case .text: look.text = color
            case .accent: look.accent = color
            }
            return look
        }
    }

    // MARK: - Variables

    let boost: Boost
    let save: (Boost) -> Void
    let hideElement: () -> Void
    let delete: () -> Void

    @State private var css: String
    @State private var script: String
    @State private var showsAdvanced: Bool

    // MARK: - Initializers

    init(boost: Boost, save: @escaping (Boost) -> Void, hideElement: @escaping () -> Void, delete: @escaping () -> Void)
    {
        self.boost = boost
        self.save = save
        self.hideElement = hideElement
        self.delete = delete
        _css = State(initialValue: boost.css)
        _script = State(initialValue: boost.script)
        _showsAdvanced = State(initialValue: !boost.css.isEmpty || !boost.script.isEmpty)
    }

    // MARK: - Actions - Presentation

    var body: some View {
        VStack(alignment: .leading, spacing: ZeeSpacing.medium) {
            ForEach(Paint.allCases, id: \.self) { paint in
                swatches(for: paint)
            }
            HStack {
                Text("Font")
                Spacer()
                Menu {
                    ForEach(BoostFont.all, id: \.self) { font in
                        Button {
                            edit { $0.look.font = font }
                        } label: {
                            Label {
                                Text(font.title)
                            } icon: {
                                Image(systemName: font == boost.look.font ? "checkmark" : "textformat")
                            }
                        }
                    }
                    .zeeMenuActionLabelStyle()
                } label: {
                    Text(boost.look.font.title)
                }
                .fixedSize()
            }
            VStack(alignment: .leading, spacing: ZeeSpacing.extraSmall) {
                HStack {
                    Text("Text Size")
                    Spacer()
                    Text(boost.look.textScale, format: .percent.precision(.fractionLength(0)))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                Slider(
                    value: Binding(get: { boost.look.textScale }, set: { scale in edit { $0.look.textScale = scale } }),
                    in: BoostLook.minimumTextScale...BoostLook.maximumTextScale, step: 0.05
                )
            }
            hidden
            Toggle(
                "Use in Every Space",
                isOn: Binding(get: { boost.appliesToAllSpaces }, set: { all in edit { $0.appliesToAllSpaces = all } })
            )
            DisclosureGroup("Advanced", isExpanded: $showsAdvanced) {
                advanced
            }
            Button("Delete Boost", systemImage: "trash", role: .destructive, action: delete)
                .buttonStyle(.zeeDestructive)
        }
        .font(.callout)
    }

    private func swatches(for paint: Paint) -> some View {
        VStack(alignment: .leading, spacing: ZeeSpacing.extraSmall) {
            Text(paint.title)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: BrowserBoostEditorMetrics.swatchSpacing) {
                Button("Site's Own", systemImage: "circle.slash") {
                    edit { $0.look = paint.painting($0.look, with: nil) }
                }
                .labelStyle(.iconOnly)
                .buttonStyle(ZeeChromeButtonStyle(controlSize: BrowserBoostEditorMetrics.swatchControl))
                .help("Site's Own")
                ForEach(Array(BrandColor.presets.enumerated()), id: \.offset) { _, color in
                    Button {
                        edit { $0.look = paint.painting($0.look, with: color) }
                    } label: {
                        Circle()
                            .fill(color.color)
                            .overlay {
                                Circle().strokeBorder(
                                    .primary.opacity(paint.color(of: boost.look) == color ? 0.9 : 0.15), lineWidth: 2)
                            }
                            .frame(
                                width: BrowserBoostEditorMetrics.swatchSize,
                                height: BrowserBoostEditorMetrics.swatchSize)
                    }
                    .buttonStyle(ZeeChromeButtonStyle(controlSize: BrowserBoostEditorMetrics.swatchControl))
                    .accessibilityLabel(Text(color.title))
                }
            }
        }
    }

    @ViewBuilder private var hidden: some View {
        VStack(alignment: .leading, spacing: ZeeSpacing.small) {
            Button("Hide an Element…", systemImage: "eye.slash", action: hideElement)
                .buttonStyle(.zeeSecondary)
            ForEach(boost.hiddenElements, id: \.self) { selector in
                HStack {
                    Text(selector)
                        .font(.caption.monospaced())
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                    Button("Show Again", systemImage: "xmark") {
                        edit { $0.hiddenElements.removeAll { $0 == selector } }
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(ZeeChromeButtonStyle())
                    .help("Show Again")
                }
            }
        }
    }

    @ViewBuilder private var advanced: some View {
        VStack(alignment: .leading, spacing: ZeeSpacing.small) {
            Text("CSS").font(.caption).foregroundStyle(.secondary)
            TextEditor(text: $css)
                .font(.caption.monospaced())
                .frame(minHeight: 80)
                .zeeFieldSurface(isFocused: false)
            Text("JavaScript").font(.caption).foregroundStyle(.secondary)
            TextEditor(text: $script)
                .font(.caption.monospaced())
                .frame(minHeight: 80)
                .zeeFieldSurface(isFocused: false)
            ZeeFormFootnote(
                "The script runs on this site each time a page opens, in a world of its own the site can’t see. Reload to run a changed script."
            )
            Button("Apply") {
                edit {
                    $0.css = css
                    $0.script = script
                }
            }
            .buttonStyle(.zeePrimary)
            .disabled(css == boost.css && script == boost.script)
        }
        .padding(.top, ZeeSpacing.small)
    }

    // MARK: - Actions - Editing

    private func edit(_ change: (inout Boost) -> Void) {
        var edited = boost
        change(&edited)
        save(edited)
    }
}

enum BrowserBoostEditorMetrics {
    /// The color swatches: eleven fit across Site Controls.
    static let swatchSize: CGFloat = 14
    static let swatchControl = CGSize(width: 20, height: 20)
    static let swatchSpacing: CGFloat = 3
}
