import Foundation

extension StorageFailed {
    @MainActor func apply(to state: CoreState) {
        state.storageFailure = reason
    }

    @MainActor func apply(to core: ZeeCore, in batch: inout CoreChangeBatch) {
        apply(to: core.state)
        core.storageFailed(reason)
    }
}
