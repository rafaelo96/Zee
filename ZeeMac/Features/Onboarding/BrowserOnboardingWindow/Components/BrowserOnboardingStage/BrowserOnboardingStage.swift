import SwiftUI

/// The stage every step of setup plays on:
/// a Big Sur landscape, under the Zee mark, the progress rail and the step's page.
/// The stage is always dark, whatever the system appearance, so the page
/// reads over any field.
struct BrowserOnboardingStage<Content: View>: View {
    let step: SetupStep
    @ViewBuilder let content: Content

    /// Where the pointer is over the stage, from -1 to 1 on each axis.
    @State private var pointer: CGPoint?

    /// How far setup has come, from 0 to 1, as the progress rail counts it.
    private var progress: Double {
        Double(step.progressPosition) / Double(max(1, SetupStep.progressCount - 1))
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                BrowserOnboardingBackdrop(progress: progress, isCalm: step.kind != .welcome, pointer: pointer)
                VStack(spacing: 0) {
                    BrowserOnboardingStageHeader(step: step)
                    content
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .onContinuousHover(coordinateSpace: .local) { phase in
                switch phase {
                case .active(let location):
                    pointer = CGPoint(
                        x: location.x / max(proxy.size.width, 1) * 2 - 1,
                        y: location.y / max(proxy.size.height, 1) * 2 - 1)
                case .ended:
                    pointer = nil
                }
            }
        }
        .environment(\.colorScheme, .dark)
        .zeeFieldSurfaceRole(.brand)
    }
}

/// The Zee mark and the progress rail over the stage.
private struct BrowserOnboardingStageHeader: View {
    let step: SetupStep

    var body: some View {
        ZStack {
            HStack(spacing: 10) {
                ZeeStartPageMark()
                    .frame(width: 22, height: 22)
                    .accessibilityHidden(true)
                Text(ProductIdentity.name)
                    .font(ZeeTypography.sans(14, weight: .bold))
                    .foregroundStyle(ZeeBrandTheme.textDisplay)
                Spacer()
            }
            BrowserOnboardingProgressRail(step: step)
        }
        .padding(.horizontal, BrowserOnboardingStageMetrics.headerInset)
        .frame(height: BrowserOnboardingStageMetrics.headerHeight)
    }
}

/// The measurements the stage and its pages share.
enum BrowserOnboardingStageMetrics {
    static let headerHeight: CGFloat = 64
    static let headerInset: CGFloat = 28
    /// The inset the footer keeps from the stage's edges.
    static let inset: CGFloat = 40
    /// The inset a page's content keeps from the stage's edges on a wide
    /// stage; a narrower one keeps the footer's.
    static let pageInset: CGFloat = 120
    /// The stage width from which pages keep `pageInset`.
    static let wideStageWidth: CGFloat = 1440

    /// The inset a page's content keeps on a stage `width` wide.
    static func pageInset(for width: CGFloat) -> CGFloat {
        width >= wideStageWidth ? pageInset : inset
    }
    /// How far a page's headline sits under the header.
    static let headlineSize: CGFloat = 46
}
