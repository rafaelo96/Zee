import SwiftUI

/// One layer above the sidebar's base UI: the device's surface material in
/// `shape`, in the scheme its material color gives it, with an accent tint
/// and a hover tint laid over it.
struct ZeeSurfaceLayer<LayerShape: Shape>: View {
    let shape: LayerShape
    var tint: Color? = nil
    var hoverTint: Color? = nil

    @Environment(\.zeeSurfaceMaterial) private var materialOverride
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.deviceColorScheme) private var deviceColorScheme

    var body: some View {
        shape
            .fill(ZeeSurfaceMaterial.shown(materialOverride).material)
            .overlay {
                if let tint { shape.fill(tint) }
            }
            .overlay {
                if let hoverTint { shape.fill(hoverTint) }
            }
            .environment(\.colorScheme, ZeeSurfaceTone.shownScheme(over: colorScheme, window: deviceColorScheme))
    }
}

#if DEBUG
    #Preview("Surface materials") {
        HStack(spacing: ZeeSpacing.small) {
            ForEach(ZeeSurfaceMaterial.all, id: \.self) { surface in
                Text(surface.title)
                    .font(.caption)
                    .padding(ZeeSpacing.small)
                    .background { ZeeSurfaceLayer(shape: .rect(cornerRadius: ZeeRadius.compact)) }
                    .environment(\.zeeSurfaceMaterial, surface)
            }
        }
        .padding()
        .background(.indigo.gradient)
    }
#endif
