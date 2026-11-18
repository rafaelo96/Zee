import SwiftUI

/// The row that opens and closes the settings a customization style leaves
/// out of its page, which follow it as their own groups.
struct BrowserAppearanceAdvancedHeader: View {
    @Binding var isExpanded: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Section {
            Button {
                withAnimation(ZeeMotion.surface.unlessReducingMotion(reduceMotion)) { isExpanded.toggle() }
            } label: {
                HStack(spacing: ZeeSpacing.small) {
                    Text("Advanced")
                    Spacer(minLength: ZeeSpacing.small)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityValue(isExpanded ? Text("Expanded") : Text("Collapsed"))
            .accessibilityIdentifier("appearance-advanced")
        }
    }
}
