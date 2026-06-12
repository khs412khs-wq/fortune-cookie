import ActivityKit

struct FortuneCookieAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var fortune: String
        var remaining: Int
    }
}
