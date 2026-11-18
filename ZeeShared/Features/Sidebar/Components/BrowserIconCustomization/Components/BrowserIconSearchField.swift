import SwiftUI

struct BrowserIconSearchField: View {
    let mode: BrowserIconPickerMode
    @Binding var query: String
    let commitEmoji: () -> Void

    var body: some View {
        HStack(spacing: ZeeSpacing.small) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            if mode == .emoji {
                BrowserPlatformEmojiEntryField(text: $query, commit: commitEmoji)
            } else {
                TextField("Search Icons", text: $query)
                    .textFieldStyle(.plain)
                    .accessibilityIdentifier("browser-icon-search-field")
            }
        }
        .padding(.leading, ZeeSpacing.small)
        .padding(.trailing, ZeeSpacing.extraSmall)
        .frame(minHeight: ZeeLayout.minimumHitTarget)
        .background(.quaternary, in: .rect(cornerRadius: ZeeRadius.control))
        .onChange(of: mode) { _, _ in query = "" }
    }
}

struct BrowserNativeEmojiPickerButton: View {
    let action: () -> Void

    var body: some View {
        Button(
            BrowserNativeEmojiPickerPresentation.current.actionTitle,
            systemImage: "face.smiling", action: action
        )
        .labelStyle(.iconOnly)
        .buttonStyle(.plain)
        .frame(width: ZeeLayout.minimumHitTarget, height: ZeeLayout.minimumHitTarget)
        .contentShape(.rect)
        .accessibilityHint("Inserts any emoji through the system text input experience.")
    }
}

#if DEBUG
    #Preview("Search icons") {
        @Previewable @State var query = ""
        BrowserIconSearchField(mode: .emoji, query: $query, commitEmoji: {}).padding().frame(width: 340)
    }
#endif
