import Foundation

enum FortunePresenter {
    static func presentFortune(
        _ fortune: String,
        remainingPersonal: Int,
        remainingGift: Int
    ) {
        LiveActivityManager.showFortune(
            fortune,
            remaining: remainingPersonal
        )
    }
}
