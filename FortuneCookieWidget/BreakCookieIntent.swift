import AppIntents
import WidgetKit

struct BreakCookieIntent: AppIntent {
    static var title: LocalizedStringResource = "포츈쿠키 부수기"
    static var description = IntentDescription("오늘의 포츈쿠키를 부숩니다.")

    func perform() async throws -> some IntentResult {
        let result = CookieStore.breakCookie(mode: .personal)

        if result.success, let fortune = result.fortune {
            HapticManager.crack()
            FortunePresenter.presentFortune(
                fortune,
                remainingPersonal: result.remainingPersonal,
                remainingGift: result.remainingGift
            )
        } else {
            HapticManager.denied()
        }

        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

struct OpenAppIntent: AppIntent {
    static var title: LocalizedStringResource = "포츈쿠키 열기"
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        .result()
    }
}
