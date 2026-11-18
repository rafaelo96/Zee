import SwiftUI

struct BrowserEmojiCategoryBar: View {
    @Binding var category: BrowserEmojiCategory
    let contentWidth: CGFloat

    var body: some View {
        VStack(spacing: ZeeSpacing.small) {
            Divider()
                .padding(.horizontal, ZeeSpacing.extraSmall)

            ScrollView(.horizontal) {
                HStack(spacing: ZeeSpacing.extraSmall) {
                    ForEach(BrowserEmojiCategory.all) { option in
                        Button {
                            category = option
                        } label: {
                            Image(systemName: option.symbol)
                                .frame(
                                    width: ZeeLayout.minimumHitTarget,
                                    height: ZeeLayout.minimumHitTarget
                                )
                                .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(
                            category == option
                                ? Color.accentColor : Color.secondary
                        )
                        .background(
                            category == option ? ZeeColor.hover : .clear,
                            in: .rect(cornerRadius: ZeeRadius.compact)
                        )
                        .help(Text(option.title))
                        .accessibilityLabel(Text(option.title))
                        .accessibilityValue(
                            category == option ? "Selected" : ""
                        )
                    }
                }
                .frame(
                    minWidth: contentWidth - ZeeSpacing.small * 2,
                    alignment: .center
                )
            }
            .contentMargins(
                .horizontal,
                ZeeSpacing.small,
                for: .scrollContent
            )
            .scrollIndicators(.hidden)
        }
        .frame(width: contentWidth)
        .accessibilityIdentifier("browser-emoji-category-bar")
    }

}

#if DEBUG
    #Preview("Choose a category") {
        @Previewable @State var category: BrowserEmojiCategory = .nature
        BrowserEmojiCategoryBar(category: $category, contentWidth: 320).padding()
    }
#endif
