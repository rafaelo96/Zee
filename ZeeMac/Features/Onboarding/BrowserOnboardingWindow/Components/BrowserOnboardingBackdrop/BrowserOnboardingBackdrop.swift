import SwiftUI

/// The stage's backdrop, in the identity the app itself wears: a cloud-white
/// field with a breath of mist in it, lit by two soft glows of Zee's blues —
/// ocean low and to the left, the dial's cyan high and to the right — and the
/// arc of the Zee dial drawn faintly across the stage.
///
/// The glows drift slowly, so the light seems to breathe, and lean with the
/// pointer. They grow quieter once a page with controls sits on the stage
/// and lift a little with each step of setup. With motion reduced, the glows
/// hold still.
struct BrowserOnboardingBackdrop: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// How far setup has come, from 0 to 1.
    var progress: Double = 0
    /// Whether a page with controls sits on the stage: the glows soften so
    /// every control and line of text reads at full contrast. Only the
    /// welcome shows them at full strength.
    var isCalm = false
    /// Where the pointer is over the stage, from -1 to 1 on each axis, or nil
    /// while it is elsewhere.
    var pointer: CGPoint?

    @State private var hasArrived = false

    var body: some View {
        GeometryReader { proxy in
            TimelineView(
                .animation(minimumInterval: BrowserOnboardingBackdropMetrics.frameInterval, paused: reduceMotion)
            ) { context in
                let time = reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate
                let size = proxy.size
                ZStack {
                    BrowserOnboardingBackdropField(time: time)
                    BrowserOnboardingBackdropDial()
                        .frame(width: size.height * 1.5, height: size.height * 1.5)
                        .position(x: size.width * 0.82, y: size.height * 0.62)
                        .offset(parallax(depth: 0.35, in: size))
                        .opacity(hasArrived ? 1 : 0)
                    glow(
                        color: ZeeBrandPalette.ocean, diameter: size.width * 0.75,
                        at: CGPoint(x: 0.12, y: 0.95), drift: drift(time, rate: 0.17), depth: 0.6, in: size)
                    glow(
                        color: ZeeBrandPalette.dial, diameter: size.width * 0.6,
                        at: CGPoint(x: 0.92, y: 0.08), drift: drift(time, rate: 0.13, phase: 2.1), depth: 1,
                        in: size)
                }
                .offset(y: -progress * size.height * BrowserOnboardingBackdropMetrics.climb)
                .animation(BrowserOnboardingBackdropMetrics.follow.unlessReducingMotion(reduceMotion), value: progress)
                .animation(BrowserOnboardingBackdropMetrics.lean.unlessReducingMotion(reduceMotion), value: pointer)
                .drawingGroup()
            }
        }
        .background(ZeeBrandPalette.cloud)
        .onAppear {
            withAnimation(BrowserOnboardingBackdropMetrics.arrival.unlessReducingMotion(reduceMotion)) {
                hasArrived = true
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    /// A soft round glow of `color`, centered at `at` (as a share of the
    /// stage), drifting by `drift` and leaning with the pointer by `depth`.
    private func glow(
        color: Color, diameter: CGFloat, at center: CGPoint, drift: CGSize, depth: Double, in size: CGSize
    ) -> some View {
        let strength = isCalm ? BrowserOnboardingBackdropMetrics.calmGlow : BrowserOnboardingBackdropMetrics.glow
        let lean = parallax(depth: depth, in: size)
        return RadialGradient(
            colors: [color.opacity(strength), color.opacity(strength * 0.4), color.opacity(0)],
            center: .center, startRadius: 0, endRadius: diameter / 2
        )
        .frame(width: diameter, height: diameter)
        .scaleEffect(hasArrived ? 1 : 0.7)
        .position(x: size.width * center.x, y: size.height * center.y)
        .offset(x: drift.width + lean.width, y: drift.height + lean.height)
        .animation(BrowserOnboardingBackdropMetrics.follow.unlessReducingMotion(reduceMotion), value: isCalm)
    }

    /// How far a glow has drifted at `time`, a slow loop a few dozen points
    /// across.
    private func drift(_ time: TimeInterval, rate: Double, phase: Double = 0) -> CGSize {
        let reach = BrowserOnboardingBackdropMetrics.driftReach
        return CGSize(width: sin(time * rate + phase) * reach, height: cos(time * rate * 0.8 + phase) * reach * 0.6)
    }

    /// How far a layer at `depth` leans with the pointer.
    private func parallax(depth: Double, in size: CGSize) -> CGSize {
        guard let pointer, !reduceMotion else { return .zero }
        return CGSize(
            width: pointer.x * depth * BrowserOnboardingBackdropMetrics.leanReach,
            height: pointer.y * depth * BrowserOnboardingBackdropMetrics.leanReach * 0.6)
    }
}

/// The field: cloud white with a breath of mist drifting through it.
private struct BrowserOnboardingBackdropField: View {
    let time: TimeInterval

    var body: some View {
        let drift = Float(sin(time * 0.11)) * 0.12
        MeshGradient(
            width: 3, height: 3,
            points: [
                [0, 0], [0.5, 0], [1, 0],
                [0, 0.5], [0.5 + drift, 0.5 - drift], [1, 0.5],
                [0, 1], [0.5, 1], [1, 1],
            ],
            colors: [
                ZeeBrandPalette.cloud, ZeeBrandPalette.cloud, ZeeBrandPalette.mist,
                ZeeBrandPalette.cloud, ZeeBrandPalette.mist, ZeeBrandPalette.cloud,
                ZeeBrandPalette.mist, ZeeBrandPalette.cloud, ZeeBrandPalette.cloud,
            ])
    }
}

/// The arc of the Zee dial, drawn as a faint wide ring open at the lower
/// right, as the mark is.
private struct BrowserOnboardingBackdropDial: View {
    var body: some View {
        Circle()
            .trim(from: 0, to: 0.8)
            .rotation(.degrees(70))
            .stroke(
                LinearGradient(
                    colors: [
                        ZeeBrandPalette.dial.opacity(BrowserOnboardingBackdropMetrics.dial),
                        ZeeBrandPalette.ocean.opacity(BrowserOnboardingBackdropMetrics.dial * 0.5),
                    ],
                    startPoint: .topTrailing, endPoint: .bottomLeading),
                style: StrokeStyle(lineWidth: 90, lineCap: .round))
    }
}

enum BrowserOnboardingBackdropMetrics {
    /// About thirty frames a second, smooth for light this slow.
    static let frameInterval: TimeInterval = 1.0 / 30
    /// How the glows and the dial come in on arrival.
    static let arrival = Animation.smooth(duration: 1.4)
    /// How the backdrop follows the pointer.
    static let lean = Animation.smooth(duration: 0.9)
    /// How the backdrop follows setup's progress and the stage calming.
    static let follow = Animation.smooth(duration: 1.4)
    /// How far the nearest glow leans at the stage's edge, in points.
    static let leanReach: Double = 36
    /// How far a glow drifts on its own, in points.
    static let driftReach: Double = 40
    /// How far the backdrop climbs over the whole of setup, as a share of the height.
    static let climb: Double = 0.06
    /// How strong a glow's middle is on the welcome.
    static let glow: Double = 0.42
    /// How strong a glow's middle is under a page with controls.
    static let calmGlow: Double = 0.2
    /// How strong the dial's arc is.
    static let dial: Double = 0.1
}

#if DEBUG
    #Preview("Backdrop") {
        BrowserOnboardingBackdrop(progress: 0.3, pointer: CGPoint(x: 0.4, y: -0.2))
            .frame(width: 1000, height: 660)
    }
#endif
