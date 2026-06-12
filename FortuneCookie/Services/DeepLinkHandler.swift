import Foundation

enum DeepLinkHandler {
    @discardableResult
    static func handle(_ url: URL) -> Bool {
        if url.scheme?.lowercased() == AppShareConfig.urlScheme {
            return true
        }

        if url.path == "/open" || url.path.hasSuffix("/open") {
            return true
        }

        return false
    }
}
