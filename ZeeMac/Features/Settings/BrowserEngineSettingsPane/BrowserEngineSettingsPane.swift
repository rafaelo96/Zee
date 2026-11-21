import SwiftUI

/// Device-wide routing choices, including choices made through a page's menu.
/// Changing a choice affects future pages and navigations, leaving open pages
/// on their current engine until the person chooses to move them.
struct BrowserEngineSettingsPane: View {
    // MARK: - Variables

    let core: ZeeCore
    @State private var editing: BrowserEngineRuleDraft?
    @State private var failure: String?

    private var preferences: EnginePreferences { core.state.enginePreferences }
    /// The website rules by site name.
    private var rules: [SiteEngineRule] {
        preferences.rules.sorted { $0.origin.displayName < $1.origin.displayName }
    }
    private var availableEngines: [EngineKind] { core.state.engines?.engines.map(\.kind) ?? [] }
    private var defaultEngine: EngineKind {
        core.state.engines?.engines.first(where: \.isDefault)?.kind ?? BrowserEngineRegistration.current.kind
    }

    // MARK: - Actions - Presentation

    var body: some View {
        BrowserSettingsPane(.engines) {
            Section {
                ForEach(BrowserEngineOption.all) { option in
                    BrowserEngineOptionCard(
                        option: option, isSelected: defaultEngine == option.engine,
                        isRecommended: BrowserEngineRegistration.current.kind == option.engine,
                        isAvailable: availableEngines.contains(option.engine)
                    ) { selectDefault(option.engine) }
                }
                if preferences.defaultEngine != nil {
                    HStack {
                        Spacer()
                        Button("Use Recommended") { selectDefault(nil) }
                    }
                }
            } header: {
                Text("Default engine")
            } footer: {
                ZeeFormFootnote("Open pages keep their engine.")
            }
            if availableEngines.contains(.webKit), availableEngines.count > 1 {
                Section {
                    Toggle(
                        "Save Battery",
                        isOn: Binding(get: { preferences.savesBattery }, set: { saveBattery($0) })
                    )
                    .accessibilityIdentifier("engines-save-battery")
                } footer: {
                    ZeeFormFootnote(
                        "While your Mac is in Low Power Mode or its battery runs low, new pages open in WebKit, which uses less power, except sites and Spaces you chose an engine for."
                    )
                }
            }
            Section {
                if preferences.rules.isEmpty {
                    Text("No website rules")
                        .foregroundStyle(.secondary)
                }
                ZeeFormRows(rules, id: \.origin) { rule in
                    HStack {
                        Button {
                            editing = BrowserEngineRuleDraft(rule: rule)
                        } label: {
                            HStack {
                                Text(rule.origin.displayName)
                                Spacer()
                                Text(rule.engine.title).foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Edit \(rule.origin.displayName), \(String(localized: rule.engine.title))")
                        Button("Remove Rule", systemImage: "minus.circle") { remove(rule) }
                            .labelStyle(.iconOnly)
                            .buttonStyle(.borderless)
                            .help("Return this website to the default engine")
                    }
                }
                HStack {
                    Spacer()
                    Button("Add Website Rule…") {
                        editing = BrowserEngineRuleDraft(engine: defaultEngine)
                    }
                    .accessibilityIdentifier("add-engine-rule")
                }
            } header: {
                Text("Website rules")
            } footer: {
                ZeeFormFootnote("A rule for a site doesn’t include its subdomains.")
            }
            if let failure { Text(failure).foregroundStyle(ZeeColor.danger) }
        }
        .sheet(item: $editing) { draft in
            BrowserEngineRuleEditor(core: core, draft: draft, availableEngines: availableEngines)
        }
    }

    // MARK: - Actions - Preferences

    private func selectDefault(_ engine: EngineKind?) {
        do {
            try core.send(SelectDefaultEngine(engine: engine))
            failure = nil
        } catch { failure = error.explanation }
    }

    private func saveBattery(_ saves: Bool) {
        do {
            try core.send(SetSavesBattery(saves: saves))
            failure = nil
        } catch { failure = error.explanation }
    }

    private func remove(_ rule: SiteEngineRule) {
        do {
            try core.send(ForgetEngineRule(origin: rule.origin))
            failure = nil
        } catch { failure = error.explanation }
    }
}
