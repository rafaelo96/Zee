#if DEBUG
    import SwiftUI

    /// Every ZeeControls component on one canvas.
    ///
    /// The gallery is the component library's own review surface: a change to a button
    /// role, a field's focus ring, or the selection border shows up here beside every
    /// other control instead of being discovered in whichever pane happened to adopt it.
    /// The previews below cover light, dark, right-to-left, and disabled; selected and
    /// unselected states sit side by side inside the gallery itself.
    ///
    /// Debug-only, and deliberately not wired into any shell.
    struct ZeeControlsGallery: View {
        var isEnabled = true

        @State private var placement: TabPlacement = .saved
        @State private var selectedCard = 0
        @State private var chipSelection: UUID? = SessionState.Seed.preview.spaces.first?.id
        @State private var menuSelection: UUID? = SessionState.Seed.preview.spaces.first?.id
        @State private var address = "example.com"
        @State private var name = ""

        private var spaces: [ZeeSpaceIdentity] {
            ZeeSpaceIdentity.list(SpaceModel.previewSpaces)
        }

        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: ZeeSpacing.section) {
                    buttons
                    fields
                    segmented
                    cards
                    spacePickers
                    formRows
                }
                .padding(ZeeSpacing.extraExtraLarge)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(ZeeBrandTheme.canvas)
            .zeeFieldSurfaceRole(.brand)
            .disabled(!isEnabled)
        }

        // MARK: - Sections

        private var buttons: some View {
            section("Buttons") {
                HStack(spacing: ZeeSpacing.medium) {
                    Button("Save Setup") {}
                        .buttonStyle(.zeePrimary)
                    Button("Back") {}
                        .buttonStyle(.zeeSecondary)
                    Button("Delete") {}
                        .buttonStyle(.zeeDestructive)
                }

                HStack(spacing: ZeeSpacing.medium) {
                    Button("Manage Filter Lists") {}
                        .buttonStyle(.zeeTertiary)
                    Button {
                    } label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.zeeIcon())
                    .accessibilityLabel("Add site")
                    Button {
                    } label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.zeeIcon(isProminent: true))
                    .accessibilityLabel("New Space")
                    Button {
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.zeeIcon(tint: ZeeBrandPalette.deep))
                    .accessibilityLabel("Remove")
                }

                HStack(spacing: ZeeSpacing.medium) {
                    Button("Disabled") {}
                        .buttonStyle(.zeePrimary)
                    Button("Disabled") {}
                        .buttonStyle(.zeeSecondary)
                    Button {
                    } label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.zeeIcon(isProminent: true))
                    .accessibilityLabel("Add site")
                }
                .disabled(true)
            }
        }

        private var fields: some View {
            section("Fields") {
                TextField("example.com", text: $address)
                    .zeeTextField()
                TextField("Space name", text: $name)
                    .zeeTextField()
                TextField("Disabled", text: .constant(""))
                    .zeeTextField()
                    .disabled(true)
            }
        }

        private var segmented: some View {
            section("Segmented") {
                Picker("Put new sites in", selection: $placement) {
                    ForEach(TabPlacement.all, id: \.self) { placement in
                        Label(placement.title, systemImage: placement.symbol)
                            .tag(placement)
                    }
                }
                .pickerStyle(.segmented)
                .tint(ZeeBrandTheme.accent)

                Picker("Appearance", selection: $placement) {
                    ForEach(TabPlacement.all, id: \.self) { placement in
                        Text(placement.title).tag(placement)
                    }
                }
                .pickerStyle(.segmented)
                .tint(ZeeBrandTheme.accent)

                Picker("Disabled", selection: .constant(TabPlacement.pinned)) {
                    ForEach(TabPlacement.all, id: \.self) { placement in
                        Text(placement.title).tag(placement)
                    }
                }
                .pickerStyle(.segmented)
                .tint(ZeeBrandTheme.accent)
                .disabled(true)
            }
        }

        private var cards: some View {
            section("Selectable cards") {
                ForEach(0..<2, id: \.self) { index in
                    ZeeSelectableCard(
                        isSelected: selectedCard == index,
                        accessibilityLabel: Text(index == 0 ? "Banner" : "Gradient")
                    ) {
                        selectedCard = index
                    } content: {
                        VStack(alignment: .leading, spacing: ZeeSpacing.extraSmall) {
                            Text(index == 0 ? "Banner" : "Gradient")
                                .font(ZeeTypography.displaySection)
                            Text("A patterned band behind the sidebar.")
                                .zeeFormFootnote()
                        }
                    }
                }

                ZeeSelectableCard(
                    isSelected: true,
                    accessibilityLabel: Text("Disabled"),
                    tint: ZeeBrandPalette.deep
                ) {
                } content: {
                    Text("Disabled and selected")
                }
                .disabled(true)

                HStack(spacing: ZeeSpacing.small) {
                    ForEach(0..<3, id: \.self) { index in
                        ZeeSelectableCard(
                            isSelected: selectedCard == index,
                            accessibilityLabel: Text(verbatim: "Tile \(index + 1)"),
                            density: .compact
                        ) {
                            selectedCard = index
                        } content: {
                            Image(systemName: "seal").font(.title2)
                        }
                    }
                }

                HStack(spacing: ZeeSpacing.small) {
                    let colors = [ZeeBrandPalette.ocean, ZeeBrandPalette.ocean, ZeeBrandPalette.deep]
                    ForEach(Array(colors.enumerated()), id: \.offset) { index, color in
                        ZeeSelectableCard(
                            isSelected: selectedCard == index,
                            accessibilityLabel: Text(verbatim: "Swatch \(index + 1)"),
                            density: .swatch
                        ) {
                            selectedCard = index
                        } content: {
                            Circle().fill(color).frame(width: 22, height: 22)
                        }
                    }
                }
            }
        }

        private var spacePickers: some View {
            section("Space selection") {
                ZeeSpaceChipRail(
                    spaces: spaces,
                    selection: $chipSelection,
                    add: ZeeSpaceChipAddAction(title: "New Space") {},
                    commands: { identity in
                        [.remove { _ = identity }]
                    }
                )

                ZeeSpaceMenuPicker(
                    "Default Space",
                    selection: $menuSelection,
                    spaces: spaces
                )

                ZeeSpaceMenuPicker(
                    "Space",
                    selection: $menuSelection,
                    spaces: spaces,
                    labelsHidden: true
                )
            }
        }

        private var formRows: some View {
            section("Form rows") {
                Form {
                    Section {
                        ZeeSettingRow("Default Space") {
                            ZeeSpaceMenuPicker(
                                "Default Space",
                                selection: $menuSelection,
                                spaces: spaces,
                                labelsHidden: true
                            )
                        }

                        ZeeSettingRow("Reset All") {
                            Button("Reset") {}
                                .buttonStyle(.zeeTertiary)
                        }
                    } footer: {
                        ZeeFormFootnote(
                            "Startup choices take effect the next time Zee opens a window."
                        )
                    }
                }
                .zeeSettingsForm()
                .frame(minHeight: 260)
            }
        }

        // MARK: - Scaffolding

        @ViewBuilder
        private func section<Content: View>(
            _ title: String,
            @ViewBuilder content: () -> Content
        ) -> some View {
            VStack(alignment: .leading, spacing: ZeeSpacing.large) {
                Text(verbatim: title)
                    .font(ZeeTypography.displayPage)
                    .foregroundStyle(ZeeBrandTheme.textDisplay)
                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
#endif
