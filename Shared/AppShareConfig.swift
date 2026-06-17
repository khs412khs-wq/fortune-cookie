import Foundation

enum AppShareConfig {
    /// 커스텀 URL Scheme (Info.plist와 동일)
    static let urlScheme = "fortunecookie"

    /// App Store 숫자 ID. 출시 후 입력 (예: "1234567890")
    static let appStoreID = "6780488176"

    /// 스마트 링크용 리다이렉트 페이지 URL.
    /// 앱 설치 시 앱 열기, 미설치 시 App Store로 이동합니다.
    static let shareRedirectURL = "https://khs412khs-wq.github.io/fortune-cookie/get"

    static var deepLinkURL: URL {
        URL(string: "\(urlScheme)://open")!
    }

    static var appStoreURL: URL? {
        guard !appStoreID.isEmpty else { return nil }
        return URL(string: "https://apps.apple.com/app/fortunecookie/id\(appStoreID)")
    }

    /// 공유 메시지에 붙일 스마트 링크 (앱 있으면 열기, 없으면 설치)
    static var shareURL: URL {
        if !shareRedirectURL.isEmpty, let url = URL(string: shareRedirectURL) {
            return url
        }
        if let storeURL = appStoreURL {
            return storeURL
        }
        return deepLinkURL
    }
}
