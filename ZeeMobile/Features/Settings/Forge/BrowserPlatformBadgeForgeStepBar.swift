import SwiftUI
import UIKit

/// The Forge's steps as one native segmented control across the width it's
/// given, whose steps an icon doesn't use are dimmed rather than removed, so
/// nothing moves. The control fits its segments to that width itself.
struct BrowserPlatformBadgeForgeStepBar: UIViewRepresentable {
    @Binding var step: BrowserBadgeStudioStep
    let disabledSteps: Set<BrowserBadgeStudioStep>

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> UISegmentedControl {
        let control = UISegmentedControl(items: BrowserBadgeStudioStep.all.map { String(localized: $0.title) })
        control.apportionsSegmentWidthsByContent = true
        control.addTarget(context.coordinator, action: #selector(Coordinator.changed(_:)), for: .valueChanged)
        control.accessibilityIdentifier = "space-forge-steps"
        control.accessibilityLabel = String(localized: "Badge Studio step")
        return control
    }

    func updateUIView(_ control: UISegmentedControl, context: Context) {
        context.coordinator.parent = self
        for (index, candidate) in BrowserBadgeStudioStep.all.enumerated() {
            control.setEnabled(!disabledSteps.contains(candidate), forSegmentAt: index)
        }
        control.selectedSegmentIndex = BrowserBadgeStudioStep.all.firstIndex(of: step) ?? 0
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UISegmentedControl, context: Context) -> CGSize? {
        let natural = uiView.intrinsicContentSize
        return CGSize(width: proposal.width ?? natural.width, height: natural.height)
    }

    final class Coordinator: NSObject {
        var parent: BrowserPlatformBadgeForgeStepBar

        init(_ parent: BrowserPlatformBadgeForgeStepBar) { self.parent = parent }

        @MainActor @objc func changed(_ sender: UISegmentedControl) {
            let steps = BrowserBadgeStudioStep.all
            guard steps.indices.contains(sender.selectedSegmentIndex) else { return }
            parent.step = steps[sender.selectedSegmentIndex]
        }
    }
}
