import ActivityKit
import Foundation

enum LiveActivityManager {
    static func showFortune(_ fortune: String, remaining: Int) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        Task {
            for activity in Activity<FortuneCookieAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }

            let state = FortuneCookieAttributes.ContentState(fortune: fortune, remaining: remaining)
            let staleDate = Date().addingTimeInterval(4 * 60 * 60)
            let content = ActivityContent(state: state, staleDate: staleDate)

            do {
                _ = try Activity.request(
                    attributes: FortuneCookieAttributes(),
                    content: content,
                    pushType: nil
                )
            } catch {
                // Live Activity unavailable in this context
            }
        }
    }
}
