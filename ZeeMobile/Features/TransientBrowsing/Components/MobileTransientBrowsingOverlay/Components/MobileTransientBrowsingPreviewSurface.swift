import SwiftUI

struct MobileTransientBrowsingPreviewSurface: View {
    let request: any MobileBrowserTransientRequest

    var body: some View {
        ZStack {
            Color.black.opacity(0.28)
                .ignoresSafeArea()

            VStack(spacing: ZeeSpacing.medium) {
                Image(systemName: request.previewSystemImage)
                    .font(.largeTitle)
                Text(request.accessibilityLabel)
                    .font(.headline)
            }
            .padding(ZeeSpacing.extraLarge)
            .background { ZeeSurfaceLayer(shape: .rect(cornerRadius: ZeeRadius.panel)) }
        }
    }
}
