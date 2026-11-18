import SwiftUI

/// Direction-aware disclosure indicator for a row that navigates or presents.
struct ZeeFormDisclosureChevron: View {
    var body: some View {
        Image(systemName: "chevron.forward")
            .font(ZeeTypography.metadata.weight(.semibold))
            .foregroundStyle(.tertiary)
            .accessibilityHidden(true)
    }
}

#if DEBUG
    #Preview("Component") {
        ZeeFormDisclosureChevron().padding()
    }
#endif
