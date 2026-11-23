import SwiftUI

/// Zee's mark, matching the app icon: Zee's cyan glyph on a white tile.
struct ZeeStartPageMark: View {
    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let tile = RoundedRectangle(
                cornerRadius: side * ZeeStartPageMarkMetrics.cornerRadiusRatio,
                style: .continuous
            )

            ZStack {
                ZeeStartPageMarkMetrics.tileColor
                ZeeGlyphShape()
                    .fill(ZeeStartPageMarkMetrics.glyphColor)
                    .frame(width: side * ZeeStartPageMarkMetrics.glyphWidthRatio)
            }
            .frame(width: side, height: side)
            .clipShape(tile)
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
            .overlay {
                tile.strokeBorder(
                    .primary.opacity(ZeeStartPageMarkMetrics.borderOpacity),
                    lineWidth: ZeeStartPageMarkMetrics.borderWidth
                )
            }
        }
    }
}

#if DEBUG
    #Preview("Component") {
        ZeeStartPageMark().frame(width: 80, height: 80).padding()
    }
#endif
