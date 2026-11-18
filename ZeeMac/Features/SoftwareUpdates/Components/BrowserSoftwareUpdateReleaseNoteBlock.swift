import SwiftUI

struct BrowserSoftwareUpdateReleaseNoteBlock: View {
    let block: BrowserSoftwareUpdateReleaseNotesDocument.Block

    @ViewBuilder
    var body: some View {
        switch block.kind {
        case .heading(let level):
            Text(block.text)
                .font(headingFont(level: level))
                .padding(.top, level <= 2 ? ZeeSpacing.small : ZeeSpacing.extraSmall)
        case .paragraph:
            Text(block.text)
                .font(.body)
                .lineSpacing(ZeeSpacing.extraExtraSmall)
        case .bullet:
            HStack(alignment: .firstTextBaseline, spacing: ZeeSpacing.small) {
                Image(systemName: "circle.fill")
                    .font(.system(size: 5, weight: .semibold))
                    .foregroundStyle(ZeeBrandTheme.accent)
                    .accessibilityHidden(true)

                Text(block.text)
                    .font(.body)
                    .lineSpacing(ZeeSpacing.extraExtraSmall)
            }
        case .divider:
            Divider()
                .padding(.vertical, ZeeSpacing.extraSmall)
        }
    }

    private func headingFont(level: Int) -> Font {
        switch level {
        case 1, 2: .title3.weight(.semibold)
        case 3: .headline
        default: .subheadline.weight(.semibold)
        }
    }
}
