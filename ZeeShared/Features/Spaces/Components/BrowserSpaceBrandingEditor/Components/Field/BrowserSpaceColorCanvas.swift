import SwiftUI

/// Picks a Space's background colors on one field: hue runs left to right,
/// vividness top to bottom, and each color is a dot you drag. One to three
/// dots make a solid color or a gradient; brightness and grain apply to all.
struct BrowserSpaceColorCanvas: View {
    let context: BrowserBadgeStudioContext
    @Environment(\.badgeStudioEditingChanged) private var editingChanged
    @State private var selectedIndex = 0
    @State private var draggedIndex: Int?

    private var colors: [BrandColor] { Array(context.value.colors) }
    private var maximumCount: Int { SpaceBranding.maximumColorCount }

    /// The shared brightness of the dots, which the field also previews.
    private var brightness: Double {
        let values = colors.map { BrowserSpaceColorCanvasHSB(color: $0).brightness }
        guard !values.isEmpty else { return 0.85 }
        return values.reduce(0, +) / Double(values.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            field
            HStack(spacing: 10) {
                Button("Remove color", systemImage: "minus") { removeColor() }
                    .labelStyle(.iconOnly)
                    .disabled(colors.count <= 1)
                Button("Add color", systemImage: "plus") { addColor() }
                    .labelStyle(.iconOnly)
                    .disabled(colors.count >= maximumCount)
                Text(countCaption)
                    .font(.caption).foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }
            .buttonStyle(.bordered)
            brightnessRow
            BrowserBadgeStudioSlider(
                title: "Grain", value: context.setting(\.textureStrength),
                readout: .percent(zero: "None", full: "Full"))
        }
        .onChange(of: colors.count) { _, count in
            selectedIndex = min(selectedIndex, max(0, count - 1))
        }
    }

    private var countCaption: LocalizedStringKey {
        colors.count == 1 ? "1 color" : "\(colors.count) colors, blended as a gradient"
    }

    // MARK: - Field

    private var field: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                fieldBackground
                BrowserSpaceColorCanvasDots()
                    .allowsHitTesting(false)
                ForEach(Array(colors.enumerated()), id: \.offset) { index, color in
                    dot(for: color, index: index)
                        .position(position(of: color, in: size))
                }
            }
            .clipShape(.rect(cornerRadius: BrowserSpaceColorCanvasMetrics.cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: BrowserSpaceColorCanvasMetrics.cornerRadius)
                    .strokeBorder(.primary.opacity(0.12), lineWidth: 1)
            }
            .contentShape(.rect)
            .gesture(drag(in: size))
        }
        .frame(height: BrowserSpaceColorCanvasMetrics.fieldHeight)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Color field")
    }

    private var fieldBackground: some View {
        ZStack {
            LinearGradient(
                colors: stride(from: 0.0, through: 1.0, by: 1.0 / 12).map {
                    Color(hue: $0, saturation: 1, brightness: max(brightness, 0.25))
                },
                startPoint: .leading, endPoint: .trailing)
            LinearGradient(
                colors: [.clear, Color(white: max(brightness, 0.25))],
                startPoint: .top, endPoint: .bottom)
        }
    }

    private func dot(for color: BrandColor, index: Int) -> some View {
        let selected = index == selectedIndex
        let diameter = selected ? BrowserSpaceColorCanvasMetrics.selectedDot : BrowserSpaceColorCanvasMetrics.dot
        let hsb = BrowserSpaceColorCanvasHSB(color: color)
        return Circle()
            .fill(color.color)
            .frame(width: diameter, height: diameter)
            .overlay { Circle().strokeBorder(.white, lineWidth: selected ? 4 : 3) }
            .shadow(color: .black.opacity(0.35), radius: 4, y: 1)
            .animation(.snappy(duration: 0.18), value: selected)
            .accessibilityElement()
            .accessibilityLabel("Color \(index + 1)")
            .accessibilityValue("Hue \(Int(hsb.hue * 360)) degrees, vividness \(Int(hsb.saturation * 100)) percent")
            .accessibilityAddTraits(selected ? .isSelected : [])
            .accessibilityAdjustableAction { direction in
                var next = hsb
                next.hue = (next.hue + (direction == .increment ? 0.02 : -0.02) + 1).truncatingRemainder(dividingBy: 1)
                setColor(next.color, at: index)
            }
    }

    private func drag(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if draggedIndex == nil {
                    draggedIndex = nearestDot(to: value.startLocation, in: size) ?? selectedIndex
                    selectedIndex = draggedIndex ?? 0
                    editingChanged(true)
                }
                guard let index = draggedIndex, colors.indices.contains(index) else { return }
                var hsb = BrowserSpaceColorCanvasHSB(color: colors[index])
                hsb.hue = min(max(value.location.x / size.width, 0), 0.999)
                let vertical = min(max(value.location.y / size.height, 0), 1)
                hsb.saturation =
                    BrowserSpaceColorCanvasMetrics.maximumSaturation
                    - vertical
                    * (BrowserSpaceColorCanvasMetrics.maximumSaturation
                        - BrowserSpaceColorCanvasMetrics.minimumSaturation)
                setColor(hsb.color, at: index)
            }
            .onEnded { _ in
                draggedIndex = nil
                editingChanged(false)
            }
    }

    // MARK: - Brightness

    private var brightnessRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "moon.fill").foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Slider(
                value: Binding(get: { brightness }, set: setBrightness),
                in: BrowserSpaceColorCanvasMetrics.minimumBrightness...1
            ) { editing in
                editingChanged(editing)
            }
            .accessibilityLabel("Brightness")
            Image(systemName: "sun.max.fill").foregroundStyle(.secondary)
                .accessibilityHidden(true)
        }
    }

    // MARK: - Actions

    private func position(of color: BrandColor, in size: CGSize) -> CGPoint {
        let hsb = BrowserSpaceColorCanvasHSB(color: color)
        let span = BrowserSpaceColorCanvasMetrics.maximumSaturation - BrowserSpaceColorCanvasMetrics.minimumSaturation
        let vertical = (BrowserSpaceColorCanvasMetrics.maximumSaturation - hsb.saturation) / span
        let inset = BrowserSpaceColorCanvasMetrics.selectedDot / 2
        return CGPoint(
            x: min(max(hsb.hue * size.width, inset), size.width - inset),
            y: min(max(min(max(vertical, 0), 1) * size.height, inset), size.height - inset))
    }

    private func nearestDot(to point: CGPoint, in size: CGSize) -> Int? {
        let reach = BrowserSpaceColorCanvasMetrics.selectedDot
        return colors.indices
            .map {
                (
                    $0,
                    hypot(
                        position(of: colors[$0], in: size).x - point.x, position(of: colors[$0], in: size).y - point.y)
                )
            }
            .filter { $0.1 <= reach }
            .min { $0.1 < $1.1 }?.0
    }

    private func setColor(_ color: BrandColor, at index: Int) {
        context.branding.editorUpdate { branding in
            guard branding.colors.indices.contains(index) else { return }
            branding.colors[index] = color
            branding.hasCustomAppearance = true
        }
    }

    private func setBrightness(_ value: Double) {
        context.branding.editorUpdate { branding in
            for index in branding.colors.indices {
                var hsb = BrowserSpaceColorCanvasHSB(color: branding.colors[index])
                hsb.brightness = value
                branding.colors[index] = hsb.color
            }
            branding.hasCustomAppearance = true
        }
    }

    private func addColor() {
        guard colors.count < maximumCount, let last = colors.last else { return }
        var hsb = BrowserSpaceColorCanvasHSB(color: last)
        hsb.hue = (hsb.hue + 0.18).truncatingRemainder(dividingBy: 1)
        context.branding.editorUpdate { branding in
            branding.colors.append(hsb.color)
            // A second color reads as a blend, as in Arc.
            if branding.themeMode == .banner && branding.bannerPattern == .solid {
                branding.themeMode = .gradient
            }
            branding.hasCustomAppearance = true
        }
        selectedIndex = colors.count
    }

    private func removeColor() {
        guard colors.count > 1 else { return }
        let index = min(selectedIndex, colors.count - 1)
        context.branding.editorUpdate { branding in
            guard branding.colors.count > 1, branding.colors.indices.contains(index) else { return }
            branding.colors.remove(at: index)
            branding.hasCustomAppearance = true
        }
        selectedIndex = max(0, index - 1)
    }
}

/// The faint dot grid that gives the field its texture.
private struct BrowserSpaceColorCanvasDots: View {
    var body: some View {
        Canvas { context, size in
            let spacing = BrowserSpaceColorCanvasMetrics.gridSpacing
            var y = spacing / 2
            while y < size.height {
                var x = spacing / 2
                while x < size.width {
                    context.fill(
                        Path(ellipseIn: CGRect(x: x - 0.9, y: y - 0.9, width: 1.8, height: 1.8)),
                        with: .color(.black.opacity(0.12)))
                    x += spacing
                }
                y += spacing
            }
        }
    }
}

/// A color as hue, saturation and brightness, each from 0 to 1.
struct BrowserSpaceColorCanvasHSB: Equatable {
    var hue: Double
    var saturation: Double
    var brightness: Double

    init(color: BrandColor) {
        let r = color.red
        let g = color.green
        let b = color.blue
        let maximum = max(r, g, b)
        let minimum = min(r, g, b)
        let delta = maximum - minimum
        brightness = maximum
        saturation = maximum == 0 ? 0 : delta / maximum
        if delta == 0 {
            hue = 0
        } else if maximum == r {
            hue = ((g - b) / delta).truncatingRemainder(dividingBy: 6) / 6
        } else if maximum == g {
            hue = ((b - r) / delta + 2) / 6
        } else {
            hue = ((r - g) / delta + 4) / 6
        }
        if hue < 0 { hue += 1 }
    }

    var color: BrandColor {
        let h = (hue.truncatingRemainder(dividingBy: 1) + 1).truncatingRemainder(dividingBy: 1) * 6
        let c = brightness * saturation
        let x = c * (1 - abs(h.truncatingRemainder(dividingBy: 2) - 1))
        let m = brightness - c
        let (r, g, b): (Double, Double, Double) =
            switch Int(h) {
            case 0: (c, x, 0)
            case 1: (x, c, 0)
            case 2: (0, c, x)
            case 3: (0, x, c)
            case 4: (x, 0, c)
            default: (c, 0, x)
            }
        return BrandColor(red: r + m, green: g + m, blue: b + m, alpha: 1)
    }
}

enum BrowserSpaceColorCanvasMetrics {
    static let fieldHeight: CGFloat = 184
    static let cornerRadius: CGFloat = 14
    static let dot: CGFloat = 22
    static let selectedDot: CGFloat = 28
    static let gridSpacing: CGFloat = 14
    static let maximumSaturation = 0.95
    static let minimumSaturation = 0.08
    static let minimumBrightness = 0.12
}

#if DEBUG
    #Preview("Color canvas") {
        @Previewable @State var branding = BrowserSpaceBrandingPreviewFixture.badgeBranding
        Form {
            BrowserSpaceColorCanvas(
                context: BrowserBadgeStudioContext(
                    branding: $branding, defaults: BrowserSpaceBrandingPreviewFixture.badgeBranding, compact: false))
        }
        .zeeSettingsForm().frame(width: 460, height: 420)
    }
#endif
