import SwiftUI

struct BrowserCredentialImportSummaryView: View {
    let review: BrowserCredentialImportReview

    var body: some View {
        VStack(alignment: .leading, spacing: ZeeSpacing.medium) {
            BrowserCredentialImportReviewSectionHeader(
                title: "Review",
                detail: "Confirm what Zee will change before anything is saved."
            )

            ViewThatFits(in: .horizontal) {
                HStack(spacing: ZeeSpacing.medium) {
                    metrics
                }
                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: ZeeSpacing.medium
                ) {
                    metrics
                }
            }
        }
    }

    @ViewBuilder
    private var metrics: some View {
        BrowserCredentialImportMetric(
            title: "Ready to import",
            value: review.proposedImportCount,
            systemImage: "checkmark.circle.fill",
            color: ZeeColor.success
        )
        BrowserCredentialImportMetric(
            title: "Need review",
            value: review.conflictCount,
            systemImage: "arrow.triangle.branch",
            color: ZeeColor.warning
        )
        BrowserCredentialImportMetric(
            title: "Warnings",
            value: review.plan.warnings.count,
            systemImage: "exclamationmark.shield.fill",
            color: ZeeColor.warning
        )
        BrowserCredentialImportMetric(
            title: "Rejected rows",
            value: review.plan.rejections.count,
            systemImage: "xmark.octagon.fill",
            color: ZeeColor.danger
        )
    }
}
