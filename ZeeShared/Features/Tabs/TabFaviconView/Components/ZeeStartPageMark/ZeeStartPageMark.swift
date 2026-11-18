import SwiftUI

/// Zee's mark: a white "Z" on a violet gradient tile, matching the app icon.
struct ZeeStartPageMark: View {
    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let tile = RoundedRectangle(
                cornerRadius: side * ZeeStartPageMarkMetrics.cornerRadiusRatio,
                style: .continuous
            )

            ZStack {
                tile.fill(
                    LinearGradient(
                        colors: [ZeeStartPageMarkMetrics.gradientTop, ZeeStartPageMarkMetrics.gradientBottom],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                ZeeGlyphShape()
                    .stroke(
                        .white,
                        style: StrokeStyle(
                            lineWidth: side * ZeeStartPageMarkMetrics.glyphWeightRatio,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
            }
            .frame(width: side, height: side)
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
