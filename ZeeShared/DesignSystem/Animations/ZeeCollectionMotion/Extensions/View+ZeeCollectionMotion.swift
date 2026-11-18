import SwiftUI

extension View {
    func zeeCollectionMotion<ID: Hashable>(ids: [ID]) -> some View {
        modifier(ZeeCollectionMotionModifier(ids: ids))
    }

    func zeeCollectionItemTransition() -> some View {
        transition(.opacity)
    }
}
