import SwiftUI

/// Picks one color on a field, as Arc does: hue runs left to right and
/// vividness top to bottom, and the color is a dot you drag or click to. A
/// slider beneath sets its brightness.
struct ZeeColorField: View {
    // MARK: - Variables

    @Binding var color: Color
    @State private var hsb: BrowserSpaceColorCanvasHSB

    // MARK: - Initializers

    init(color: Binding<Color>) {
        _color = color
        _hsb = State(initialValue: BrowserSpaceColorCanvasHSB(color: BrandColor(color: color.wrappedValue)))
    }

    // MARK: - Actions - Drawing

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            field
            HStack(spacing: 10) {
                Image(systemName: "moon.fill").foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                Slider(
                    value: Binding(get: { hsb.brightness }, set: { update(brightness: $0) }),
                    in: ZeeColorFieldMetrics.minimumBrightness...1
                )
                .accessibilityLabel("Brightness")
                Image(systemName: "sun.max.fill").foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
        }
        .padding(ZeeColorFieldMetrics.padding)
        .frame(width: ZeeColorFieldMetrics.width)
    }

    private var field: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                LinearGradient(
                    colors: stride(from: 0.0, through: 1.0, by: 1.0 / 12).map {
                        Color(hue: $0, saturation: 1, brightness: max(hsb.brightness, 0.25))
                    },
                    startPoint: .leading, endPoint: .trailing)
                LinearGradient(
                    colors: [.clear, Color(white: max(hsb.brightness, 0.25))],
                    startPoint: .top, endPoint: .bottom)
                Circle()
                    .fill(Color(hue: hsb.hue, saturation: hsb.saturation, brightness: hsb.brightness))
                    .frame(width: ZeeColorFieldMetrics.dot, height: ZeeColorFieldMetrics.dot)
                    .overlay { Circle().strokeBorder(.white, lineWidth: 3) }
                    .shadow(color: .black.opacity(0.35), radius: 4, y: 1)
                    .position(position(in: size))
            }
            .clipShape(.rect(cornerRadius: ZeeColorFieldMetrics.cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: ZeeColorFieldMetrics.cornerRadius)
                    .strokeBorder(.primary.opacity(0.12), lineWidth: 1)
            }
            .contentShape(.rect)
            .gesture(
                DragGesture(minimumDistance: 0).onChanged { value in
                    pick(at: value.location, in: size)
                })
        }
        .frame(height: ZeeColorFieldMetrics.fieldHeight)
        .accessibilityElement()
        .accessibilityLabel("Color")
        .accessibilityValue("Hue \(Int(hsb.hue * 360)) degrees, vividness \(Int(hsb.saturation * 100)) percent")
        .accessibilityAdjustableAction { direction in
            var next = hsb
            next.hue = (next.hue + (direction == .increment ? 0.02 : -0.02) + 1).truncatingRemainder(dividingBy: 1)
            commit(next)
        }
    }

    // MARK: - Actions - Choosing

    private func position(in size: CGSize) -> CGPoint {
        let inset = ZeeColorFieldMetrics.dot / 2
        let vertical = (1 - hsb.saturation) / (1 - ZeeColorFieldMetrics.minimumSaturation)
        return CGPoint(
            x: min(max(hsb.hue * size.width, inset), size.width - inset),
            y: min(max(vertical * size.height, inset), size.height - inset))
    }

    private func pick(at location: CGPoint, in size: CGSize) {
        var next = hsb
        next.hue = min(max(location.x / size.width, 0), 0.999)
        let vertical = min(max(location.y / size.height, 0), 1)
        next.saturation = 1 - vertical * (1 - ZeeColorFieldMetrics.minimumSaturation)
        commit(next)
    }

    private func update(brightness: Double) {
        var next = hsb
        next.brightness = brightness
        commit(next)
    }

    private func commit(_ next: BrowserSpaceColorCanvasHSB) {
        hsb = next
        color = next.color.color
    }
}

enum ZeeColorFieldMetrics {
    static let width: CGFloat = 300
    static let padding: CGFloat = 16
    static let fieldHeight: CGFloat = 170
    static let cornerRadius: CGFloat = 12
    static let dot: CGFloat = 26
    static let minimumSaturation = 0.08
    static let minimumBrightness = 0.12
}

#if DEBUG
    #Preview("Color field") {
        @Previewable @State var color = Color.orange
        ZeeColorField(color: $color)
    }
#endif
