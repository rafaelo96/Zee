import SwiftUI

struct ZeeSpaceChipCommands: ViewModifier {
    let commands: [ZeeSpaceChipCommand]

    @ViewBuilder
    func body(content: Content) -> some View {
        if commands.isEmpty {
            content
        } else {
            content.contextMenu {
                ForEach(commands) { command in
                    Button(
                        command.title,
                        systemImage: command.systemImage,
                        role: command.isDestructive ? .destructive : nil,
                        action: command.perform
                    )
                }
                .zeeMenuActionLabelStyle()
            }
        }
    }
}
