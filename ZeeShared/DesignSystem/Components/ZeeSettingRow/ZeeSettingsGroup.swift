import SwiftUI

/// A titled group of settings that can put everything it holds back at once.
///
/// The group stays a native `Section` so the platform's own grouped form draws
/// the box and its insets. One quiet Reset sits on the header's trailing edge.
/// The Reset keeps its place whether or not it is showing, so a header never
/// changes height and the boxes below it never move.
struct ZeeSettingsGroup<Preview: View, Content: View>: View {
    private let title: LocalizedStringKey
    private let settings: [ZeeResettableSetting]
    private let footnote: LocalizedStringKey?
    private let preview: Preview
    private let content: Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(
        _ title: LocalizedStringKey,
        settings: [ZeeResettableSetting] = [],
        footnote: LocalizedStringKey? = nil,
        @ViewBuilder preview: () -> Preview,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.settings = settings
        self.footnote = footnote
        self.preview = preview()
        self.content = content()
    }

    var body: some View {
        Section {
            preview
            content
        } header: {
            HStack(spacing: ZeeSpacing.small) {
                ZeeSettingsSectionHeading(title: title)
                Spacer(minLength: ZeeSpacing.small)
                Button("Reset", action: settings.resetAll)
                    .buttonStyle(.borderless)
                    .controlSize(.small)
                    .opacity(isModified ? 1 : 0)
                    .animation(
                        ZeeMotion.surface.unlessReducingMotion(reduceMotion),
                        value: isModified
                    )
                    .disabled(!isModified)
                    .accessibilityHidden(!isModified)
                    .accessibilityLabel(Text("Reset \(Text(title)) to defaults"))
            }
        } footer: {
            if let footnote {
                ZeeFormFootnote(footnote)
            }
        }
    }

    private var isModified: Bool { settings.isModified }
}

extension ZeeSettingsGroup where Preview == EmptyView {
    init(
        _ title: LocalizedStringKey,
        settings: [ZeeResettableSetting] = [],
        footnote: LocalizedStringKey? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            title, settings: settings, footnote: footnote,
            preview: { EmptyView() }, content: content
        )
    }
}

#if DEBUG
    #Preview("Group reset") {
        @Previewable @State var opacity = 0.65
        Form {
            ZeeSettingsGroup(
                "Appearance",
                settings: [ZeeSettingValue($opacity, default: 1).resettable("Opacity")]
            ) {
                ZeeSettingSlider("Opacity", value: ZeeSettingValue($opacity, default: 1))
            }
        }.zeeSettingsForm().frame(width: 420, height: 320)
    }
#endif
