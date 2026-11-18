import Foundation

enum BrowserContentBlockingError: LocalizedError {
    case compilationFailed
    case ruleListUnavailable

    var errorDescription: String? {
        switch self {
        case .compilationFailed:
            "Zee couldn’t compile its native content-blocking rules."
        case .ruleListUnavailable:
            "Zee’s native content-blocking rules are unavailable."
        }
    }
}
