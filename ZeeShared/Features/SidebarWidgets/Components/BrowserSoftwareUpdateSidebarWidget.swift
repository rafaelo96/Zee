import SwiftUI

struct BrowserSoftwareUpdateSidebarWidget: View {
    // MARK: - Variables

    let instance: BrowserSidebarWidgetInstance
    let update: BrowserSoftwareUpdateWidgetSnapshot
    let perform: (BrowserSidebarWidgetAction, BrowserSidebarWidgetID) -> Void

    @Environment(\.browserSoftwareUpdateDetails) private var showDetails

    var body: some View {
        VStack(alignment: .leading, spacing: BrowserSidebarWidgetDeckStyle.contentSpacing) {
            headerRow
            progressZone
            actions
        }
        .overlay(alignment: .topTrailing) {
            hideButton
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Zee software update")
    }

    private var canHide: Bool {
        instance.availableActions.contains(.hideSoftwareUpdate)
    }

    /// The card's own buttons, in the order their actions stand, without the
    /// corner control that hides it.
    private var buttonActions: [BrowserSidebarWidgetAction] {
        instance.availableActions.filter { $0.cardButton != nil }
            .sorted { ($0.cardButton?.priority ?? 0) < ($1.cardButton?.priority ?? 0) }
    }

    // MARK: - Actions - Layout

    private var headerRow: some View {
        HStack(alignment: .top, spacing: ZeeSpacing.small) {
            BrowserSoftwareUpdateApplicationIcon()
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: ZeeSpacing.extraExtraSmall) {
                HStack(spacing: ZeeSpacing.extraSmall) {
                    headerTitle
                        .font(.subheadline.weight(.semibold))
                    if update.isFixture {
                        Text("TEST")
                            .font(ZeeTypography.badge)
                            .padding(.horizontal, ZeeSpacing.extraSmall)
                            .padding(
                                .vertical,
                                BrowserSidebarWidgetDeckStyle.badgeVerticalPadding
                            )
                            .background(
                                ZeeColor.warningFill,
                                in: .capsule
                            )
                            .accessibilityLabel("Test fixture")
                    }
                }
                .lineLimit(1)

                if let versionLine {
                    Text(verbatim: versionLine)
                        .font(ZeeTypography.metadata)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                if hasDetails, let showDetails {
                    Button("What's New") { showDetails() }
                        .buttonStyle(.plain)
                        .font(ZeeTypography.metadata.weight(.medium))
                        .foregroundStyle(ZeeBrandTheme.accent)
                        .accessibilityLabel("Review update details")
                        .help("Review update details")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(
                .trailing,
                canHide ? BrowserSidebarWidgetDeckStyle.quietControlDiameter + ZeeSpacing.extraSmall : 0
            )
            .layoutPriority(1)
        }
    }

    @ViewBuilder
    private var hideButton: some View {
        if canHide {
            Button {
                perform(.hideSoftwareUpdate, instance.id)
            } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(BrowserSidebarWidgetQuietControlStyle(alignment: .topTrailing))
            .accessibilityLabel("Hide Update")
            .help("Hide until you check for updates")
        }
    }

    @ViewBuilder
    private var progressZone: some View {
        if let progress = update.progress, update.phase.isTransferring {
            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .tint(ZeeBrandTheme.accent)
                .accessibilityLabel(Text(statusLabel))
        } else if update.phase.isWorking {
            HStack(spacing: ZeeSpacing.small) {
                ProgressView()
                    .controlSize(.small)
                Text(statusLabel)
                    .font(ZeeTypography.metadata)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(Text(statusLabel))
        }

        if let message = update.message, update.phase.showsMessage {
            Text(verbatim: message)
                .font(ZeeTypography.metadata)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
    }

    @ViewBuilder
    private var actions: some View {
        if !buttonActions.isEmpty {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: ZeeSpacing.small) {
                    actionButtons
                }
                VStack(spacing: ZeeSpacing.small) {
                    actionButtons
                }
            }
        }
    }

    /// Each button the card offers, in order, the first prominent one as the
    /// card's primary button.
    @ViewBuilder
    private var actionButtons: some View {
        let primary = buttonActions.first { $0.cardButton?.isProminent == true }
        ForEach(buttonActions, id: \.self) { action in
            if let button = action.cardButton {
                actionButton(action, button, emphasis: action == primary ? .prominent : .quiet)
            }
        }
    }

    /// The card's button for `action`, as `button` shows it: a link to the
    /// update's release page, or a button that performs it.
    @ViewBuilder
    private func actionButton(
        _ action: BrowserSidebarWidgetAction,
        _ button: BrowserSidebarWidgetAction.CardButton,
        emphasis: BrowserSidebarWidgetActionEmphasis
    ) -> some View {
        let label = Label {
            Text(button.title)
        } icon: {
            Image(systemName: button.symbol)
        }
        if button.opensReleasePage {
            if let informationURL = update.informationURL {
                Link(destination: informationURL) { label }
                    .buttonStyle(BrowserSidebarWidgetActionButtonStyle(emphasis: emphasis))
            }
        } else {
            Button {
                perform(action, instance.id)
            } label: {
                label
            }
            .buttonStyle(BrowserSidebarWidgetActionButtonStyle(emphasis: emphasis))
            .accessibilityLabel(Text(button.accessibilityLabel ?? button.title))
            .help(Text(button.accessibilityLabel ?? button.title))
        }
    }

    private var hasDetails: Bool {
        if let releaseNotes = update.releaseNotes, !releaseNotes.isEmpty {
            return true
        }
        return update.informationURL != nil
    }

    private var headerTitle: Text {
        update.phase.isTitledByUpdate ? Text(verbatim: update.title) : Text(update.phase.title)
    }

    private var versionLine: String? {
        switch (update.version, update.build) {
        case (let version?, let build?) where version != build:
            "Version \(version) · Build \(build)"
        case (let version?, _):
            "Version \(version)"
        case (_, let build?):
            "Build \(build)"
        default:
            nil
        }
    }

    private var statusLabel: LocalizedStringResource {
        (update.isInformationOnly ? update.phase.informationOnlyStatusLabel : nil) ?? update.phase.statusLabel
    }
}

private struct BrowserSoftwareUpdateApplicationIcon: View {
    @Environment(\.browserApplicationIcon) private var applicationIcon

    var body: some View {
        (applicationIcon ?? Image(systemName: "app.fill"))
            .resizable()
            .scaledToFit()
            .frame(
                width: BrowserSidebarWidgetDeckStyle.headerTileSize,
                height: BrowserSidebarWidgetDeckStyle.headerTileSize
            )
    }
}

extension EnvironmentValues {
    /// Opens the full release notes for the update a card presents. Nil where
    /// the shell has no window to show them in, which leaves out What's New.
    @Entry var browserSoftwareUpdateDetails: BrowserSoftwareUpdateDetailsAction? = nil
}
