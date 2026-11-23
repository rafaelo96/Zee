import SwiftUI

/// The Space's name over its tabs, so the sidebar says which Space it shows.
///
/// A click opens the list of Spaces to move to; renaming takes a double
/// click or Rename in the row's menu. Keeping the two apart is deliberate:
/// a single click that renamed would catch everyone who meant to switch.
struct SpaceSidebarNameRow: View {
    let space: SpaceModel
    let browser: BrowserStore
    let isLocked: Bool
    let selectSpace: (UUID) -> Void
    let editSpace: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovering = false
    @State private var isPickingSpace = false
    @State private var isRenaming = false
    @State private var draftName = ""
    @FocusState private var isNameFocused: Bool

    var body: some View {
        HStack(spacing: ZeeSpacing.small) {
            BrowserSpaceIdentityIcon(space: space, size: SpaceSidebarNameRowMetrics.iconSize)
                .frame(width: SpaceSidebarNameRowMetrics.iconSize, height: SpaceSidebarNameRowMetrics.iconSize)

            if isRenaming {
                TextField("Space name", text: $draftName)
                    .textFieldStyle(.plain)
                    .focused($isNameFocused)
                    .onSubmit(commitRename)
                    .onExitCommand(perform: cancelRename)
                    .accessibilityIdentifier("sidebar-space-name-field")
            } else {
                Text(space.settings.name)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            actionsMenu
                .opacity(isHovering || isPickingSpace ? 1 : 0)
                .animation(ZeeMotion.surface.unlessReducingMotion(reduceMotion), value: isHovering)
        }
        .font(.callout.weight(.semibold))
        .padding(.horizontal, ZeeSpacing.small)
        .frame(height: SpaceSidebarNameRowMetrics.height)
        .contentShape(.rect)
        .zeeHoverSurface(cornerRadius: ZeeLayout.sidebarControlCornerRadius)
        .onHover { isHovering = $0 }
        // The double click is looked for first, so a single click waits the
        // moment a double click takes before it opens the list.
        .onTapGesture(count: 2) { beginRename() }
        .onTapGesture { if !isRenaming { isPickingSpace = true } }
        .zeePopover(isPresented: $isPickingSpace, arrowEdge: .bottom) { spacePicker }
        .onChange(of: isNameFocused) { _, focused in if !focused, isRenaming { commitRename() } }
        .disabled(isLocked)
        .padding(.horizontal, BrowserSidebarMetrics.layerInset)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("\(space.settings.name) Space"))
        .accessibilityHint(Text("Click to switch Spaces, double-click to rename"))
        .accessibilityAction(named: Text("Switch Space")) { isPickingSpace = true }
        .accessibilityAction(named: Text("Rename Space")) { beginRename() }
    }

    // MARK: - Menu

    private var actionsMenu: some View {
        Menu {
            Group {
                Button("Rename Space", systemImage: "pencil") { beginRename() }
                Button("Switch Space…", systemImage: "square.stack") { isPickingSpace = true }
                Divider()
                Button("Edit Space…", systemImage: "slider.horizontal.3", action: editSpace)
            }
            .zeeMenuActionLabelStyle()
        } label: {
            Image(systemName: "ellipsis")
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .tint(.primary)
        .help("Space Actions")
        .accessibilityLabel("Space actions")
    }

    // MARK: - Space picker

    private var spacePicker: some View {
        VStack(spacing: ZeeSpacing.extraExtraSmall) {
            ForEach(browser.availableSpaces) { candidate in
                BrowserQuickWindowSpacePickerRow(
                    space: candidate.identity,
                    isSelected: candidate.id == space.id
                ) {
                    isPickingSpace = false
                    selectSpace(candidate.id)
                }
            }
        }
        .padding(ZeeSpacing.small)
        .frame(width: SpaceSidebarNameRowMetrics.pickerWidth)
    }

    // MARK: - Renaming

    private func beginRename() {
        guard !isLocked else { return }
        isPickingSpace = false
        draftName = space.settings.name
        isRenaming = true
        isNameFocused = true
    }

    private func commitRename() {
        let name = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        isRenaming = false
        guard !name.isEmpty, name != space.settings.name else { return }
        browser.spaceNameBinding(in: space).wrappedValue = name
    }

    private func cancelRename() {
        isRenaming = false
        draftName = space.settings.name
    }
}

enum SpaceSidebarNameRowMetrics {
    static let height: CGFloat = 30
    static let iconSize: CGFloat = 18
    static let pickerWidth: CGFloat = 240
}
