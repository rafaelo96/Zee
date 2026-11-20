import SwiftUI

/// Zee's mark, matching the app icon: a white "Z" over Zee's landscape, a
/// blue sky with coral, red, sun, cyan and ocean waves.
struct ZeeStartPageMark: View {
    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let tile = RoundedRectangle(
                cornerRadius: side * ZeeStartPageMarkMetrics.cornerRadiusRatio,
                style: .continuous
            )

            ZStack {
                LinearGradient(
                    colors: ZeeStartPageMarkMetrics.skyColors,
                    startPoint: ZeeStartPageMarkMetrics.skyStart,
                    endPoint: ZeeStartPageMarkMetrics.skyEnd
                )
                ForEach(ZeeLandscapeWave.all.indices, id: \.self) { index in
                    let wave = ZeeLandscapeWave.all[index]
                    wave.fill(wave.fill)
                }
                ZeeGlyphShape()
                    .stroke(
                        .white,
                        style: StrokeStyle(
                            lineWidth: side * ZeeStartPageMarkMetrics.glyphWeightRatio,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                    .shadow(
                        color: .black.opacity(ZeeStartPageMarkMetrics.glyphShadowOpacity), radius: side * 0.03,
                        y: side * 0.015)
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
