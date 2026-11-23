import SwiftUI

enum BrowserFolderColorPalette {
    static let choices: [BrowserFolderColorChoice] = [
        .init(title: "Slate", value: .folderDefault),
        .init(title: "Ink", value: .ink),
        .init(title: "Deep Blue", value: Tincture.zeeDeep.color),
        .init(title: "Ocean", value: .ocean),
        .init(title: "Sky", value: .sky),
        .init(title: "Teal", value: .teal),
        .init(title: "Sage", value: .sage),
        .init(title: "Gold", value: .gold),
        .init(title: "Ember", value: .ember),
        .init(title: "Coral", value: Tincture.zeeCoral.color),
        .init(title: "Sand", value: .sand),
    ]
}
