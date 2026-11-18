import Foundation

extension WebsiteDataRead {
    /// A website data reading's end changes no model: `ZeeCore.readWebsiteData`
    /// hears it.
    @MainActor func apply(to state: CoreState) {}

    @MainActor func apply(to core: ZeeCore, in batch: inout CoreChangeBatch) {
        batch.websiteDataRead.append(self)
    }
}
