import SwiftUI

struct ZeeSpaceMenuLabelVisibility: ViewModifier {
    let labelsHidden: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if labelsHidden {
            content.labelsHidden()
        } else {
            content
        }
    }
}
