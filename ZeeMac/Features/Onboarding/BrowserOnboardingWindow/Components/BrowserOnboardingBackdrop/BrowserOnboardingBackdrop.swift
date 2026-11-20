import SwiftUI

/// The stage's backdrop, Zee's own landscape: a breathing blue sky, and
/// waves rolling across it in Zee's order, coral, red, a ribbon of sun gold,
/// then cyan and ocean in front.
///
/// On arrival the waves rise into place one after another. They lean with
/// the pointer, the near ones more than the far ones; they climb a little
/// with each step of setup; a light glides along their crests; and a fine
/// grain lies over all of it. With motion
/// reduced, the waves arrive in place and hold still.
struct BrowserOnboardingBackdrop: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// How far setup has come, from 0 to 1.
    var progress: Double = 0
    /// Whether a page with controls sits on the stage: the waves settle low,
    /// and a midnight veil darkens the sky, so every control and line of
    /// text reads at full contrast. Only the welcome shows the whole landscape.
    var isCalm = false
    /// Where the pointer is over the stage, from -1 to 1 on each axis, or nil
    /// while it is elsewhere.
    var pointer: CGPoint?

    @State private var hasRisen = false

    var body: some View {
        GeometryReader { proxy in
            TimelineView(
                .animation(minimumInterval: BrowserOnboardingBackdropMetrics.frameInterval, paused: reduceMotion)
            ) {
                context in
                let time = reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate
                ZStack {
                    BrowserOnboardingBackdropSky(time: time)
                        .offset(parallax(depth: -0.25, in: proxy.size))
                    ZStack {
                        ForEach(BrowserOnboardingWave.all.indices, id: \.self) { index in
                            let wave = BrowserOnboardingWave.all[index]
                            BrowserOnboardingWaveLayer(wave: wave, time: time, index: index)
                                .offset(parallax(depth: wave.depth, in: proxy.size))
                                .offset(y: hasRisen ? 0 : proxy.size.height * 0.8)
                                .animation(
                                    BrowserOnboardingBackdropMetrics.rise.delay(Double(index) * 0.09)
                                        .unlessReducingMotion(reduceMotion),
                                    value: hasRisen)
                        }
                    }
                    .offset(y: settledOffset(in: proxy.size))
                    .animation(
                        BrowserOnboardingBackdropMetrics.follow.unlessReducingMotion(reduceMotion), value: progress
                    )
                    .animation(
                        BrowserOnboardingBackdropMetrics.follow.unlessReducingMotion(reduceMotion), value: isCalm)
                    BrowserOnboardingBackdropVeil()
                        .opacity(isCalm ? 1 : 0)
                        .animation(
                            BrowserOnboardingBackdropMetrics.follow.unlessReducingMotion(reduceMotion), value: isCalm)
                }
                .animation(BrowserOnboardingBackdropMetrics.lean.unlessReducingMotion(reduceMotion), value: pointer)
                .drawingGroup()
                .overlay { BrowserOnboardingBackdropGrain() }
            }
        }
        .background(ZeeBrandPalette.deep)
        .onAppear { hasRisen = true }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    /// How far the waves sit from where the welcome shows them: low on a calm
    /// stage, then a little higher with each step of setup.
    private func settledOffset(in size: CGSize) -> CGFloat {
        let climb = -progress * size.height * BrowserOnboardingBackdropMetrics.climb
        return isCalm ? size.height * BrowserOnboardingBackdropMetrics.settle + climb : 0
    }

    /// How far a layer at `depth` leans with the pointer.
    private func parallax(depth: Double, in size: CGSize) -> CGSize {
        guard let pointer, !reduceMotion else { return .zero }
        return CGSize(
            width: pointer.x * depth * BrowserOnboardingBackdropMetrics.leanReach,
            height: pointer.y * depth * BrowserOnboardingBackdropMetrics.leanReach * 0.6)
    }
}

/// The veil over a calm stage: midnight at the top, where the page's title
/// and controls sit, thinning toward the waves at the foot.
private struct BrowserOnboardingBackdropVeil: View {
    var body: some View {
        LinearGradient(
            stops: [
                .init(color: ZeeBrandPalette.midnight.opacity(0.88), location: 0),
                .init(color: ZeeBrandPalette.midnight.opacity(0.78), location: 0.55),
                .init(color: ZeeBrandPalette.midnight.opacity(0.2), location: 1),
            ],
            startPoint: .top, endPoint: .bottom)
    }
}

/// The sky: a mesh of Zee's blues whose middle drifts slowly, so the light in
/// it seems to breathe. Only blues meet in it; red never mixes with blue.
private struct BrowserOnboardingBackdropSky: View {
    let time: TimeInterval

    var body: some View {
        let drift = Float(sin(time * 0.23)) * 0.16
        let sway = Float(cos(time * 0.19)) * 0.12
        let lift = Float(sin(time * 0.31 + 1.7)) * 0.08
        MeshGradient(
            width: 3, height: 3,
            points: [
                [0, 0], [0.5 + sway, 0], [1, 0],
                [0, 0.5 + lift], [0.5 + drift, 0.45 + sway], [1, 0.5 - lift],
                [0, 1], [0.5 - drift, 1], [1, 1],
            ],
            colors: [
                ZeeBrandPalette.deep, ZeeBrandPalette.ocean, ZeeBrandPalette.sky,
                ZeeBrandPalette.deep, ZeeBrandPalette.sky, ZeeBrandPalette.cyan,
                ZeeBrandPalette.ocean, ZeeBrandPalette.cyan, ZeeBrandPalette.sky,
            ])
    }
}

/// A fine, still grain over the backdrop, like a print's, so its large fields
/// of color never read as flat. One tile of noise, made once and repeated.
private struct BrowserOnboardingBackdropGrain: View {
    // MARK: - Static Variables

    private static let tile: Image? = {
        let side = 128
        var bytes = [UInt8](repeating: 0, count: side * side)
        var seed: UInt64 = 0x5EED_2EE
        for index in bytes.indices {
            seed = seed &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            bytes[index] = UInt8(truncatingIfNeeded: seed >> 56)
        }
        guard let provider = CGDataProvider(data: Data(bytes) as CFData),
            let image = CGImage(
                width: side, height: side, bitsPerComponent: 8, bitsPerPixel: 8, bytesPerRow: side,
                space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGBitmapInfo(rawValue: 0), provider: provider,
                decode: nil, shouldInterpolate: false, intent: .defaultIntent)
        else { return nil }
        return Image(decorative: image, scale: 2)
    }()

    // MARK: - Body

    var body: some View {
        if let tile = Self.tile {
            Rectangle()
                .fill(.image(tile))
                .blendMode(.overlay)
                .opacity(BrowserOnboardingBackdropMetrics.grain)
                .allowsHitTesting(false)
        }
    }
}

/// One wave of the landscape: where its crest lies, how it rolls, how far it
/// leans with the pointer, and the colors it is filled with from crest to foot.
struct BrowserOnboardingWave {
    // MARK: - Static Variables

    /// Back to front, in Zee's order: cool in front, warm behind.
    static let all: [BrowserOnboardingWave] = [
        .init(
            baseline: 0.34, amplitude: 0.1, frequency: 0.7, tilt: -0.42, phase: 0.4, speed: 0.22, depth: 0.25,
            colors: [ZeeBrandPalette.coral, ZeeBrandPalette.red]),
        .init(
            baseline: 0.47, amplitude: 0.11, frequency: 0.8, tilt: -0.38, phase: 2.2, speed: 0.18, depth: 0.4,
            colors: [ZeeBrandPalette.red, ZeeBrandPalette.redDeep]),
        .init(
            baseline: 0.57, amplitude: 0.09, frequency: 0.65, tilt: -0.32, phase: 4.1, speed: 0.26, depth: 0.55,
            colors: [ZeeBrandPalette.sun, ZeeBrandPalette.orange]),
        .init(
            baseline: 0.64, amplitude: 0.1, frequency: 0.9, tilt: -0.27, phase: 5.6, speed: 0.16, depth: 0.75,
            colors: [ZeeBrandPalette.cyan, ZeeBrandPalette.sky, ZeeBrandPalette.ocean]),
        .init(
            baseline: 0.82, amplitude: 0.07, frequency: 0.75, tilt: -0.2, phase: 1.3, speed: 0.2, depth: 1,
            colors: [ZeeBrandPalette.ocean, ZeeBrandPalette.deep]),
    ]

    // MARK: - Variables

    /// The crest's mean height, as a share of the stage from the top.
    let baseline: Double
    /// How far the crest rises and falls, as a share of the stage's height.
    let amplitude: Double
    /// How many swells cross the stage.
    let frequency: Double
    /// How much the crest falls from left to right, as a share of the height.
    let tilt: Double
    let phase: Double
    /// How fast the wave rolls, in radians a second.
    let speed: Double
    /// How near the wave is, from 0 far to 1 near: how far it leans with the
    /// pointer.
    let depth: Double
    let colors: [Color]
}

/// A wave drawn as a filled band with a soft shadow above it, a soft light
/// inside its crest that gives it volume, a fine light along the crest, and
/// a brighter glint that glides along it.
private struct BrowserOnboardingWaveLayer: View {
    let wave: BrowserOnboardingWave
    let time: TimeInterval
    let index: Int

    /// Where along the crest the glint is, from a little before its start to
    /// a little past its end, each wave on its own beat.
    private var glint: Double {
        let cycle = (time / BrowserOnboardingBackdropMetrics.glintPeriod + Double(index) * 0.23)
            .truncatingRemainder(dividingBy: 1)
        return cycle * 1.6 - 0.3
    }

    var body: some View {
        let shape = BrowserOnboardingWaveShape(wave: wave, time: time)
        let crest = BrowserOnboardingWaveShape(wave: wave, time: time, crestOnly: true)
        shape
            .fill(LinearGradient(colors: wave.colors, startPoint: .top, endPoint: .bottom))
            .overlay {
                crest
                    .stroke(.white.opacity(0.24), lineWidth: 46)
                    .blur(radius: 26)
                    .clipShape(shape)
            }
            .shadow(color: .black.opacity(0.28), radius: 30, y: -8)
            .overlay {
                crest
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.1), .white.opacity(0.55), .white.opacity(0.2)],
                            startPoint: .leading, endPoint: .trailing),
                        lineWidth: 1.2
                    )
                    .blur(radius: 0.6)
            }
            .overlay {
                crest
                    .stroke(glintGradient, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .blur(radius: 2)
            }
    }

    private var glintGradient: LinearGradient {
        let width = 0.12
        func clamped(_ value: Double) -> Double { min(max(value, 0), 1) }
        return LinearGradient(
            stops: [
                .init(color: .white.opacity(0), location: clamped(glint - width)),
                .init(color: .white.opacity(0.9), location: clamped(glint)),
                .init(color: .white.opacity(0), location: clamped(glint + width)),
            ],
            startPoint: .leading, endPoint: .trailing)
    }
}

/// The band under a wave's crest, or the crest line alone. It runs past the
/// stage's edges, so a wave that leans or climbs never shows a gap.
private struct BrowserOnboardingWaveShape: Shape {
    let wave: BrowserOnboardingWave
    let time: TimeInterval
    var crestOnly = false

    func path(in rect: CGRect) -> Path {
        let steps = 140
        let overhang = 0.1
        let roll = wave.phase + time * wave.speed
        var path = Path()
        for step in 0...steps {
            let progress = -overhang + (1 + overhang * 2) * Double(step) / Double(steps)
            let swell =
                sin(progress * .pi * 2 * wave.frequency + roll)
                + 0.35 * sin(progress * .pi * 2 * wave.frequency * 2.3 - roll * 1.4)
            let y = wave.baseline + wave.tilt * (progress - 0.5) + wave.amplitude * swell / 1.35
            let point = CGPoint(x: rect.minX + rect.width * progress, y: rect.minY + rect.height * y)
            if step == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        guard !crestOnly else { return path }
        path.addLine(to: CGPoint(x: rect.maxX + rect.width * overhang, y: rect.maxY + rect.height))
        path.addLine(to: CGPoint(x: rect.minX - rect.width * overhang, y: rect.maxY + rect.height))
        path.closeSubpath()
        return path
    }
}

enum BrowserOnboardingBackdropMetrics {
    /// About thirty frames a second, smooth for waves this slow.
    static let frameInterval: TimeInterval = 1.0 / 30
    /// How the waves rise into place on arrival.
    static let rise = Animation.spring(response: 1.3, dampingFraction: 0.78)
    /// How the backdrop follows the pointer.
    static let lean = Animation.smooth(duration: 0.9)
    /// How the waves follow setup's progress.
    static let follow = Animation.smooth(duration: 1.4)
    /// How far the nearest wave leans at the stage's edge, in points.
    static let leanReach: Double = 36
    /// How far the waves sink on a calm stage, as a share of the height.
    static let settle: Double = 0.36
    /// How far the waves climb over the whole of setup, as a share of the height.
    static let climb: Double = 0.08
    /// Seconds a glint takes to cross a crest and come round again.
    static let glintPeriod: TimeInterval = 9
    /// How strongly the grain shows.
    static let grain: Double = 0.12
}

#if DEBUG
    #Preview("Backdrop") {
        BrowserOnboardingBackdrop(progress: 0.3, pointer: CGPoint(x: 0.4, y: -0.2))
            .frame(width: 1000, height: 660)
    }
#endif
