import SwiftUI

extension View {
    /// Applies the explanatory-copy role to content assembled by the caller.
    func zeeFormFootnote() -> some View {
        font(.footnote)
            .foregroundStyle(ZeeColor.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}
