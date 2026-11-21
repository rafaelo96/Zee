import SwiftUI

/// Site Controls' Boost: whether the page's site wears a Boost in the page's
/// Space, a switch for it, and its editor, which opens beneath it.
struct BrowserSiteBoostSection: View {
    // MARK: - Variables

    let page: BrowserPage
    let space: SpaceModel
    let dismiss: () -> Void

    @State private var isEditing = false
    @State private var failure: LocalizedStringResource?

    private var boost: Boost? { page.boost(in: space) }

    // MARK: - Actions - Presentation

    var body: some View {
        if let site = page.boostSite {
            VStack(alignment: .leading, spacing: ZeeSpacing.small) {
                HStack(spacing: ZeeSpacing.small) {
                    Label("Boost", systemImage: "paintbrush.pointed")
                        .font(.headline)
                    Spacer(minLength: ZeeSpacing.small)
                    if let boost {
                        Toggle(
                            "Boost On",
                            isOn: Binding(get: { boost.isOn }, set: { save(with(boost) { $0.isOn = $1 }, $0) })
                        )
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .controlSize(.small)
                        Button(
                            isEditing ? "Hide Boost Editor" : "Edit Boost",
                            systemImage: isEditing ? "chevron.up" : "slider.horizontal.3"
                        ) {
                            isEditing.toggle()
                        }
                        .labelStyle(.iconOnly)
                        .buttonStyle(ZeeChromeButtonStyle())
                        .help(isEditing ? "Hide Boost Editor" : "Edit Boost")
                    } else {
                        Button("Boost This Site") { start(site) }
                            .buttonStyle(.zeeSecondary)
                            .accessibilityIdentifier("site-controls-boost-start")
                    }
                }
                if isEditing, let boost {
                    BrowserBoostEditor(
                        boost: boost,
                        save: { save($0) },
                        hideElement: {
                            dismiss()
                            Task { @MainActor in
                                await Task.yield()
                                await page.pickElementToHideWithBoost()
                            }
                        },
                        delete: {
                            page.delete(boost, in: space)
                            isEditing = false
                        }
                    )
                }
                if let failure {
                    Text(failure).font(.caption).foregroundStyle(ZeeColor.danger)
                }
            }
        }
    }

    // MARK: - Actions - Editing

    private func start(_ site: String) {
        let boost = Boost(
            id: UUID(), domain: site, isOn: true, appliesToAllSpaces: false, look: .unchanged, css: "", script: "",
            hiddenElements: [], modifiedAt: .now)
        save(boost)
        isEditing = true
    }

    private func save(_ boost: Boost) {
        do {
            try page.save(boost, in: space)
            failure = nil
        } catch {
            failure = error.message
        }
    }

    /// `boost` with `value` set by `change`.
    private func with<Value>(_ boost: Boost, _ change: @escaping (inout Boost, Value) -> Void) -> (Value) -> Boost {
        { value in
            var edited = boost
            change(&edited, value)
            return edited
        }
    }

    private func save<Value>(_ make: (Value) -> Boost, _ value: Value) {
        save(make(value))
    }
}
