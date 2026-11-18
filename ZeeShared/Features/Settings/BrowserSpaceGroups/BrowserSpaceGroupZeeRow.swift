import SwiftUI
import UniformTypeIdentifiers

/// The Spaces of the group a Settings page edits, as a row of badges between
/// the page's header and its tabs. Choosing a badge edits that Space, + starts
/// another Sub-Space, and each badge's menu moves it within the group, moves
/// it to another group, separates it or deletes it. A Space on its own shows
/// its one badge and +, which is how its first Sub-Space starts, so the row
/// never comes or goes.
///
/// On the Mac a badge also drags: onto another badge of the row to move it
/// there, or onto Settings' list of Spaces to move it to another group or
/// bring it out on its own, which asks first.
struct BrowserSpaceGroupZeeRow: View {
    // MARK: - Variables

    let browser: BrowserStore
    /// The Space the page edits.
    let space: SpaceModel
    var style: ZeeSpaceIconPickerStyle = .compact
    var metrics: BrowserSpacePickerMetrics = .pointer
    /// The Space being dragged in Settings, which this row's badges take.
    @Binding var draggedSpaceID: UUID?
    let select: (UUID) -> Void
    let addSubSpace: (UUID) -> Void
    let requestGroupChange: (BrowserSpaceGroupChange) -> Void
    let requestDeletion: (BrowserSpaceDeletionRequest) -> Void

    @State private var dropTargetID: UUID?

    var body: some View {
        let members = browser.groupMembers(of: space)
        HStack(spacing: ZeeSpacing.small) {
            HStack(spacing: 0) {
                ForEach(members) { member in
                    badge(member)
                }
            }
            .padding(style.trackPadding)
            .background {
                ZeeSpaceIconPickerShape(style: style).fill(.primary.opacity(style.trackFillOpacity))
            }
            .overlay {
                ZeeSpaceIconPickerShape(style: style)
                    .strokeBorder(.primary.opacity(style.trackBorderOpacity), lineWidth: ZeeLayout.hairline / 2)
            }
            if !browser.isPrivateBrowsing, let last = members.last {
                Button("New Sub-Space", systemImage: "plus") { addSubSpace(last.id) }
                    .labelStyle(.iconOnly)
                    .buttonStyle(ZeeChromeButtonStyle(controlSize: CGSize(width: style.height, height: style.height)))
                    .help("New Sub-Space")
                    .accessibilityIdentifier("space-group-add-sub-space")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Sub-Spaces")
        .accessibilityIdentifier("space-group-badges")
    }

    // MARK: - Zees

    private func badge(_ member: SpaceModel) -> some View {
        let isSelected = member.id == space.id
        let tint = member.identity.branding.primaryColor.color
        let isDropTarget = dropTargetID == member.id
        return Button {
            select(member.id)
        } label: {
            BrowserSpacePickerIcon(space: member.identity, metrics: metrics)
                .frame(width: style.minimumSegmentWidth, height: style.segmentHeight)
                .contentShape(.rect)
                .background {
                    if isSelected || isDropTarget {
                        ZeeSpaceIconPickerShape(style: style)
                            .fill(
                                tint.opacity(isSelected ? style.selectionFillOpacity : style.selectionFillOpacity / 2)
                            )
                            .overlay {
                                ZeeSpaceIconPickerShape(style: style).strokeBorder(
                                    tint, lineWidth: ZeeLayout.hairline)
                            }
                    }
                }
        }
        .buttonStyle(.plain)
        .help(member.settings.name)
        .accessibilityLabel(Text(verbatim: member.settings.name))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("space-group-zee-\(member.id)")
        .contextMenu { menu(member).zeeMenuActionLabelStyle() }
        #if os(macOS)
            .onDrag {
                draggedSpaceID = member.id
                return NSItemProvider(object: member.id.uuidString as NSString)
            }
            .onDrop(
                of: [.plainText],
                delegate: ZeeDrop(
                    target: member, browser: browser, draggedSpaceID: $draggedSpaceID, dropTargetID: $dropTargetID,
                    requestGroupChange: requestGroupChange))
        #endif
    }

    @ViewBuilder
    private func menu(_ member: SpaceModel) -> some View {
        // The primary leads its group; a Sub-Space moves among the others.
        if browser.isSubSpace(member) {
            let order = BrowserSpaceOrderActions(browser: browser, spaceID: member.id)
            Button("Move Left", systemImage: "arrow.left", action: order.moveUp).disabled(!order.canMoveUp)
            Button("Move Right", systemImage: "arrow.right", action: order.moveDown).disabled(!order.canMoveDown)
            Divider()
        }
        BrowserSpaceGroupMenuItems(
            browser: browser, space: member, requestGroupChange: requestGroupChange, addSubSpace: addSubSpace)
        Divider()
        BrowserSpaceDeletionMenuItems(browser: browser, space: member, requestDeletion: requestDeletion)
    }
}

#if os(macOS)
    /// A badge taking a dragged Space: one of its own group moves to where the
    /// badge stands, and one from elsewhere asks to join the group.
    private struct ZeeDrop: DropDelegate {
        let target: SpaceModel
        let browser: BrowserStore
        @Binding var draggedSpaceID: UUID?
        @Binding var dropTargetID: UUID?
        let requestGroupChange: (BrowserSpaceGroupChange) -> Void

        private var dragged: SpaceModel? {
            draggedSpaceID.flatMap { browser.spaceModel($0) }.flatMap { $0.id == target.id ? nil : $0 }
        }

        /// Whether the drop moves the dragged Space within the target's group.
        private var movesWithinGroup: Bool {
            guard let dragged else { return false }
            return browser.primary(of: dragged) === browser.primary(of: target) && browser.isSubSpace(dragged)
                && browser.isSubSpace(target)
        }

        func validateDrop(info: DropInfo) -> Bool {
            guard let dragged else { return false }
            return movesWithinGroup || BrowserSpaceGroupChange.joining(dragged, into: target, in: browser) != nil
        }

        func dropEntered(info: DropInfo) {
            dropTargetID = target.id
        }

        func dropExited(info: DropInfo) {
            if dropTargetID == target.id { dropTargetID = nil }
        }

        func dropUpdated(info: DropInfo) -> DropProposal? {
            DropProposal(operation: .move)
        }

        func performDrop(info: DropInfo) -> Bool {
            defer {
                dropTargetID = nil
                draggedSpaceID = nil
            }
            guard let dragged else { return false }
            if movesWithinGroup {
                browser.move(dragged.id, to: target.id)
                return true
            }
            guard let join = BrowserSpaceGroupChange.joining(dragged, into: target, in: browser) else { return false }
            requestGroupChange(join)
            return true
        }
    }
#endif
