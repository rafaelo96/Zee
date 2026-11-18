import SwiftUI

/// A horizontal rail of zee-badged Space chips, ending in a dashed add chip.
/// The chips stand in a row where they fit the width they are offered, and
/// scroll sideways where there are more than fit.
struct ZeeSpaceChipRail: View {
    let spaces: [ZeeSpaceIdentity]
    @Binding var selection: UUID?
    var add: ZeeSpaceChipAddAction?
    var commands: ((ZeeSpaceIdentity) -> [ZeeSpaceChipCommand])?
    var accessibilityIdentifier: String?

    init(
        spaces: [ZeeSpaceIdentity],
        selection: Binding<UUID?>,
        add: ZeeSpaceChipAddAction? = nil,
        commands: ((ZeeSpaceIdentity) -> [ZeeSpaceChipCommand])? = nil,
        accessibilityIdentifier: String? = nil
    ) {
        self.spaces = spaces
        _selection = selection
        self.add = add
        self.commands = commands
        self.accessibilityIdentifier = accessibilityIdentifier
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            chips
            ScrollView(.horizontal) { chips }
                .scrollIndicators(.hidden)
        }
        .accessibilityElement(children: .contain)
        .zeeAccessibilityIdentifier(accessibilityIdentifier)
    }

    private var chips: some View {
        HStack(spacing: ZeeSpaceChipMetrics.railSpacing) {
            ForEach(spaces) { identity in
                chip(identity)
            }

            if let add {
                addChip(add)
            }
        }
        .padding(.vertical, ZeeSpacing.extraExtraSmall)
        .zeeCollectionMotion(ids: spaces.map(\.id))
    }

    private func chip(_ identity: ZeeSpaceIdentity) -> some View {
        let isSelected = identity.id == selection
        return Button {
            selection = identity.id
        } label: {
            HStack(spacing: ZeeSpaceChipMetrics.contentSpacing) {
                BrowserSpaceSymbolArtwork(
                    identity: identity.space,
                    size: ZeeSpaceChipMetrics.iconSize,
                    lockSize: ZeeSpaceChipMetrics.lockSize
                )
                Text(verbatim: identity.name)
                    .lineLimit(1)
            }
        }
        .buttonStyle(
            ZeeSpaceChipStyle(tint: identity.tint, isSelected: isSelected)
        )
        .accessibilityLabel(Text(verbatim: identity.name))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .zeeCollectionItemTransition()
        .modifier(ZeeSpaceChipCommands(commands: commands?(identity) ?? []))
    }

    private func addChip(_ add: ZeeSpaceChipAddAction) -> some View {
        Button(action: add.perform) {
            HStack(spacing: ZeeSpaceChipMetrics.contentSpacing) {
                Image(systemName: "plus")
                    .font(.body.weight(.semibold))
                Text(add.title)
                    .lineLimit(1)
            }
        }
        .buttonStyle(ZeeSpaceAddChipStyle(tint: addTint))
        .accessibilityLabel(Text(add.title))
        .zeeAccessibilityIdentifier(add.accessibilityIdentifier)
    }

    private var addTint: Color {
        spaces.first { $0.id == selection }?.tint ?? ZeeBrandTheme.accent
    }
}

#if DEBUG
    #Preview("Select a Space") {
        @Previewable @State var selection: UUID? = SessionState.Seed.preview.spaces[0].id
        ZeeSpaceChipRail(spaces: ZeeSpaceIdentity.list(SpaceModel.previewSpaces), selection: $selection)
            .padding().frame(width: 360)
    }
#endif
