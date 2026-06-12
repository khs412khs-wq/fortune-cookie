import ActivityKit
import SwiftUI
import WidgetKit

struct FortuneCookieLiveActivity: Widget {
    private let accent = Color(red: 219 / 255, green: 132 / 255, blue: 78 / 255)

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FortuneCookieAttributes.self) { context in
            lockScreenView(context: context)
                .activityBackgroundTint(.white)
                .activitySystemActionForegroundColor(accent)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image("fortune_cookie_remind")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text("FORTUNE COOKIE TO REMIND")
                        .font(.caption2.weight(.heavy))
                        .foregroundStyle(accent)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.fortune)
                        .font(.subheadline)
                        .foregroundStyle(.black)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                }
            } compactLeading: {
                Image("fortune_cookie_remind")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
            } compactTrailing: {
                Text("\(context.state.remaining)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(accent)
            } minimal: {
                Image("fortune_cookie_remind")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 14, height: 14)
            }
        }
    }

    private func lockScreenView(context: ActivityViewContext<FortuneCookieAttributes>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 10) {
                Image("fortune_cookie_remind")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)

                Text("FORTUNE COOKIE TO REMIND")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(accent)
                    .tracking(0.4)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }

            Text(context.state.fortune)
                .font(.body)
                .foregroundStyle(.black)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}
