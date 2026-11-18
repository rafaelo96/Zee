import SwiftUI

/// The Space the Quick Window browses, shown by its badge, which opens the
/// Spaces it may switch to: choosing one reopens the page with that Space's
/// website data and passwords.
struct BrowserQuickWindowSourceSpaceIndicator: View {
    let space: BrowserSpaceIdentity?
    let spaces: [BrowserSpaceIdentity]
    let selectSpace: (BrowserSpaceRuntimeAssignment) -> Void

    @State private var isPickerPresented = false

    var body: some View {
        Button {
            isPickerPresented.toggle()
        } label: {
            Group {
                if let space {
                    BrowserSpaceSymbolArtwork(space: space, size: 20, lockSize: 5)
                } else {
                    Image(systemName: "square.grid.2x2")
                }
            }
            .font(.callout.weight(.semibold))
            .frame(width: ZeeLayout.minimumHitTarget, height: ZeeLayout.minimumHitTarget)
            .background(
                ZeeColor.hover,
                in: .rect(cornerRadius: ZeeRadius.compact, style: .continuous)
            )
        }
        .buttonStyle(
            ZeeChromeButtonStyle(controlSize: nil, cornerRadius: ZeeRadius.compact)
        )
        .disabled(space == nil)
        .fixedSize()
        .help(space?.name ?? String(localized: "Space"))
        .accessibilityLabel("Current Quick Window Space")
        .accessibilityValue(space?.name ?? "Space")
        .accessibilityIdentifier("quick-window-source-space")
        .zeePopover(isPresented: $isPickerPresented, arrowEdge: .bottom) {
            if let space {
                BrowserQuickWindowSpacePicker(
                    spaces: spaces,
                    selectedSpaceID: space.id
                ) { candidate in
                    isPickerPresented = false
                    selectSpace(candidate.assignment)
                }
            }
        }
    }
}

#if DEBUG
    #Preview("Component") {
        let spaces = SpaceModel.previewSpaces.map(\.identity)
        BrowserQuickWindowSourceSpaceIndicator(space: spaces[0], spaces: spaces, selectSpace: { _ in })
            .padding()
    }
#endif
