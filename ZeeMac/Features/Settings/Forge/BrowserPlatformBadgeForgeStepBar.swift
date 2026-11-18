import AppKit
import SwiftUI

/// The Forge's steps as one native segmented control, whose steps an icon
/// doesn't use are dimmed rather than removed, so nothing moves.
struct BrowserPlatformBadgeForgeStepBar: NSViewRepresentable {
    @Binding var step: BrowserBadgeStudioStep
    let disabledSteps: Set<BrowserBadgeStudioStep>

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSSegmentedControl {
        let control = NSSegmentedControl(
            labels: BrowserBadgeStudioStep.all.map { String(localized: $0.title) },
            trackingMode: .selectOne, target: context.coordinator,
            action: #selector(Coordinator.changed(_:)))
        control.segmentStyle = .automatic
        control.setAccessibilityIdentifier("space-forge-steps")
        control.setAccessibilityLabel(String(localized: "Badge Studio step"))
        return control
    }

    func updateNSView(_ control: NSSegmentedControl, context: Context) {
        context.coordinator.parent = self
        for (index, candidate) in BrowserBadgeStudioStep.all.enumerated() {
            control.setEnabled(!disabledSteps.contains(candidate), forSegment: index)
        }
        control.selectedSegment = BrowserBadgeStudioStep.all.firstIndex(of: step) ?? 0
    }

    final class Coordinator: NSObject {
        var parent: BrowserPlatformBadgeForgeStepBar

        init(_ parent: BrowserPlatformBadgeForgeStepBar) { self.parent = parent }

        @MainActor @objc func changed(_ sender: NSSegmentedControl) {
            let steps = BrowserBadgeStudioStep.all
            guard steps.indices.contains(sender.selectedSegment) else { return }
            parent.step = steps[sender.selectedSegment]
        }
    }
}
