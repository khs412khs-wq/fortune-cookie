import WidgetKit
import SwiftUI

@main
struct FortuneCookieWidgetBundle: WidgetBundle {
    var body: some Widget {
        FortuneCookieWidget()
        FortuneCookieLiveActivity()
    }
}
