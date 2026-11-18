import SwiftUI

/// Picks one Space out of many in a form context.
///
/// A native `Picker` retains the platform menu, keyboard behavior, accessibility
/// role, and selected-value announcement. Zee standardizes the identity row.
struct ZeeSpaceMenuPicker<Tag: Hashable>: View {
    let label: LocalizedStringKey
    let spaces: [ZeeSpaceIdentity]
    @Binding var selection: Tag
    let tag: (ZeeSpaceIdentity) -> Tag
    var labelsHidden = false
    var iconSize: CGFloat = ZeeSpaceChipMetrics.menuIconSize
    var accessibilityIdentifier: String?

    var body: some View {
        Picker(label, selection: $selection) {
            ForEach(spaces) { identity in
                BrowserSpaceIdentityLabel(
                    identity: identity.space,
                    title: identity.name,
                    iconSize: iconSize
                )
                .tag(tag(identity))
            }
        }
        .modifier(ZeeSpaceMenuLabelVisibility(labelsHidden: labelsHidden))
        .accessibilityLabel(Text(label))
        .zeeAccessibilityIdentifier(accessibilityIdentifier)
    }
}

#if DEBUG
    #Preview("Select a Space") {
        @Previewable @State var selection: UUID? = SessionState.Seed.preview.spaces[0].id
        ZeeSpaceMenuPicker(
            "Default Space", selection: $selection, spaces: ZeeSpaceIdentity.list(SpaceModel.previewSpaces)
        )
        .padding().frame(width: 320)
    }
#endif
