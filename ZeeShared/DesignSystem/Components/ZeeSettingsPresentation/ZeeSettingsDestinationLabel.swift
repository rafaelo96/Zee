import SwiftUI

/// Shared settings-navigation label used by the native macOS and mobile shells.
struct ZeeSettingsDestinationLabel: View {
    let title: LocalizedStringResource
    let subtitle: LocalizedStringResource
    let systemImage: String
    let color: Color
    var compact = false
    var castsShadow = false

    var body: some View {
        HStack(spacing: labelSpacing) {
            ZeeIconTile(
                systemImage: systemImage,
                color: color,
                size: iconSize,
                symbolSize: symbolSize,
                cornerRadius: iconCornerRadius,
                castsShadow: castsShadow
            )

            VStack(
                alignment: .leading,
                spacing: ZeeSettingsPresentationMetrics.titleSpacing
            ) {
                Text(title)
                    .font(ZeeTypography.controlTitle)
                    .foregroundStyle(ZeeColor.textPrimary)
                if !compact || BrowserSettingsLayout.showsSidebarSubtitles {
                    Text(subtitle)
                        .font(
                            compact
                                ? ZeeTypography.compactMetadata
                                : ZeeTypography.metadata
                        )
                        .foregroundStyle(ZeeColor.textSecondary)
                        .lineLimit(1)
                }
            }

            if compact {
                Spacer(minLength: 0)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(title))
        .accessibilityHint(Text(subtitle))
    }

    private var labelSpacing: CGFloat {
        compact
            ? ZeeSettingsPresentationMetrics.compactLabelSpacing
            : ZeeSpacing.medium
    }

    private var iconSize: CGFloat {
        compact
            ? BrowserSettingsLayout.sidebarIconSize
            : ZeeSettingsPresentationMetrics.regularIconSize
    }

    private var symbolSize: CGFloat {
        compact
            ? ZeeSettingsPresentationMetrics.compactSymbolSize
            : ZeeSettingsPresentationMetrics.regularSymbolSize
    }

    private var iconCornerRadius: CGFloat {
        compact
            ? ZeeSettingsPresentationMetrics.compactIconCornerRadius
            : ZeeSettingsPresentationMetrics.regularIconCornerRadius
    }
}

#if DEBUG
    #Preview("Regular and compact") {
        VStack(alignment: .leading, spacing: 20) {
            ZeeSettingsDestinationLabel(
                title: "Appearance", subtitle: "Make Zee your own", systemImage: "paintpalette.fill", color: .indigo)
            ZeeSettingsDestinationLabel(
                title: "Privacy", subtitle: "Control your browsing data", systemImage: "hand.raised.fill",
                color: .green, compact: true)
        }.padding().frame(width: 380)
    }
#endif
