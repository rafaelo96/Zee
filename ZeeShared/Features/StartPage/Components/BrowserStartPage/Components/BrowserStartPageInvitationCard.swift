import SwiftUI

/// The start page's invitation to bring another browser's Spaces, such as
/// Arc's, with the day it stops working while that day is still ahead.
struct BrowserStartPageInvitationCard: View {
    let invitation: BrowserStartPageInvitation

    private var message: Text {
        let title = invitation.source.title
        if let stopsWorkingAt = invitation.stopsWorkingAt, stopsWorkingAt > .now {
            // The core names the day itself, so it reads the same day in every
            // time zone.
            var dayStyle = Date.FormatStyle.dateTime.month(.wide).day()
            dayStyle.timeZone = .gmt
            let day = stopsWorkingAt.formatted(dayStyle)
            return Text(
                "Bring your Spaces, folders, and passwords before \(title) stops working on \(day).",
                comment: "Start page invitation. The first value is a browser's name, the second the day it shuts down."
            )
        }
        return Text(
            "Bring your Spaces, folders, and passwords from \(title).",
            comment: "Start page invitation. The value is a browser's name.")
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: invitation.source.symbol)
                .font(.title2)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 10) {
                Text(
                    "Coming from \(invitation.source.title)?",
                    comment: "Start page invitation heading. The value is a browser's name."
                )
                .font(.headline)
                message
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 10) {
                    Button("Bring from \(invitation.source.title)…") { invitation.bring() }
                        .buttonStyle(.zeePrimary)
                        .accessibilityIdentifier("start-page-invitation-bring")
                    Button("Not Now") { invitation.dismiss() }
                        .buttonStyle(.zeeTertiary)
                        .accessibilityIdentifier("start-page-invitation-dismiss")
                }
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .zeeFloatingFlyoutStyle(in: .rect(cornerRadius: ZeeRadius.card))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("start-page-invitation")
    }
}
