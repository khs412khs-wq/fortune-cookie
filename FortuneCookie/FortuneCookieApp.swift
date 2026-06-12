import SwiftUI

@main
struct FortuneCookieApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)
                .onOpenURL { url in
                    DeepLinkHandler.handle(url)
                }
        }
    }
}
