import SwiftUI

/// The shared explanatory-copy treatment used beneath form controls.
struct ZeeFormFootnote: View {
    let text: LocalizedStringKey

    init(_ text: LocalizedStringKey) {
        self.text = text
    }

    var body: some View {
        Text(text).zeeFormFootnote()
    }
}

#if DEBUG
    #Preview("Component") {
        ZeeFormFootnote("Startup choices take effect the next time Zee opens a window.").padding().frame(width: 340)
    }
#endif
