import SwiftUI

/// A Space's look in the Simple style: the one color its sidebar and icon
/// wear, how strongly the sidebar wears it, how much grain lies over it, and
/// its icon.
struct BrowserSpaceSimpleEditor: View {
    // MARK: - Variables

    @Binding var branding: SpaceBranding
    @Binding var symbol: String

    // MARK: - Actions - Drawing

    var body: some View {
        Section {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 40), spacing: ZeeSpacing.small)], spacing: ZeeSpacing.small
            ) {
                ForEach(BrowserSimpleSpaceColor.all, id: \.self) { color in
                    BrowserSimpleSpaceColorSwatch(
                        color: color, isSelected: BrowserSimpleSpaceColor.worn(by: branding) == color
                    ) {
                        $branding.editorUpdate { $0 = color.applied(to: $0) }
                    }
                }
                BrowserSimpleSpaceCustomColor(branding: $branding)
            }
            .padding(.vertical, ZeeSpacing.extraSmall)
            .accessibilityIdentifier("space-simple-colors")
            BrowserSpaceIntensityRow(branding: $branding)
            BrowserSpaceTextureRow(branding: $branding)
        } header: {
            ZeeSettingsSectionHeading(title: "Color")
        }
        BrowserSpaceIconSection(branding: $branding, symbol: $symbol)
    }
}
