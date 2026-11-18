import SwiftUI

struct BrowserDeveloperToolbarSettingsSection: View {
    @Bindable private var preferences = BrowserAppPreferenceStore.shared

    var body: some View {
        Section {
            Toggle("Developer toolbar on local pages", isOn: $preferences.automaticallyShowsDeveloperToolbar)
                .accessibilityIdentifier("automatic-developer-toolbar-toggle")
        } header: {
            Text("Developer")
        } footer: {
            ZeeFormFootnote("Local pages are localhost, private network addresses, .local, .test and files.")
        }
    }
}
