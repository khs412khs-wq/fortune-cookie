import WidgetKit

enum WidgetHelper {
    static let widgetKind = "FortuneCookieWidget"

    static func checkIsWidgetAdded() async -> Bool {
        await withCheckedContinuation { continuation in
            WidgetCenter.shared.getCurrentConfigurations { result in
                switch result {
                case .success(let widgets):
                    let isAdded = widgets.contains { $0.kind == widgetKind }
                    continuation.resume(returning: isAdded)
                case .failure:
                    continuation.resume(returning: false)
                }
            }
        }
    }
}
