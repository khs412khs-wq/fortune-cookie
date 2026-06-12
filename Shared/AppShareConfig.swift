import Foundation

enum AppShareConfig {
    /// 커스텀 URL Scheme (Info.plist와 동일)
    static let urlScheme = "fortunecookie"

    /// App Store 숫자 ID. 출시 후 입력 (예: "1234567890")
    static let appStoreID = ""

    /// 스마트 링크용 리다이렉트 페이지 URL.
    /// `docs/share-redirect.html`을 호스팅한 주소를 넣으면
    /// 앱 설치 시 앱 열기, 미설치 시 App Store로 이동합니다.
    static let shareRedirectURL = ""

    static var deepLinkURL: URL {
        URL(string: "\(urlScheme)://open")!
    }

    static var appStoreURL: URL? {
        guard !appStoreID.isEmpty else { return nil }
        return URL(string: "https://apps.apple.com/app/id\(appStoreID)")
    }

    /// 공유 메시지에 붙일 스마트 링크 (앱 있으면 열기, 없으면 설치)
    static var shareURL: URL {
        if !shareRedirectURL.isEmpty, var components = URLComponents(string: shareRedirectURL) {
            var queryItems = components.queryItems ?? []
            queryItems.append(URLQueryItem(name: "scheme", value: urlScheme))
            queryItems.append(URLQueryItem(name: "path", value: "open"))
            if !appStoreID.isEmpty {
                queryItems.append(URLQueryItem(name: "store", value: appStoreID))
            }
            components.queryItems = queryItems
            if let url = components.url {
                return url
            }
        }

        if let storeURL = appStoreURL {
            return storeURL
        }

        return deepLinkURL
    }
}
