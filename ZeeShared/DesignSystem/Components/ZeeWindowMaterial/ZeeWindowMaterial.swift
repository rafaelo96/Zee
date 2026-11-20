import SwiftUI

/// The desktop behind the window, blurred through the Mac's sidebar glass.
///
/// It draws only where the window itself is clear, so a view lays it under
/// whatever should let the desktop show. Where there is no such glass, on
/// iOS, it draws nothing and the view above it decides the color.
struct ZeeWindowMaterial: View {
    // MARK: - Actions - Drawing

    var body: some View {
        #if os(macOS)
            ZeeWindowMaterialView()
        #else
            Color.clear
        #endif
    }

    #if os(macOS)
        private struct ZeeWindowMaterialView: NSViewRepresentable {
            func makeNSView(context: Context) -> NSVisualEffectView {
                let view = NSVisualEffectView()
                view.material = .sidebar
                view.blendingMode = .behindWindow
                view.state = .active
                return view
            }

            func updateNSView(_ view: NSVisualEffectView, context: Context) {}
        }
    #endif
}
