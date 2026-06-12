import WidgetKit
import SwiftUI

struct FortuneCookieEntry: TimelineEntry {
    let date: Date
    let remaining: Int
    let lastFortune: String?
}

struct FortuneCookieProvider: TimelineProvider {
    func placeholder(in context: Context) -> FortuneCookieEntry {
        FortuneCookieEntry(date: Date(), remaining: 3, lastFortune: "오늘은 행운이 가득한 날이에요.")
    }

    func getSnapshot(in context: Context, completion: @escaping (FortuneCookieEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FortuneCookieEntry>) -> Void) {
        let entry = currentEntry()
        let midnight = Calendar.current.startOfDay(for: Date().addingTimeInterval(86400))
        let timeline = Timeline(entries: [entry], policy: .after(midnight))
        completion(timeline)
    }

    private func currentEntry() -> FortuneCookieEntry {
        CookieStore.resetIfNeeded()
        let state = CookieStore.load()
        return FortuneCookieEntry(
            date: Date(),
            remaining: state.remainingPersonal,
            lastFortune: state.lastFortune
        )
    }
}

struct FortuneCookieWidgetView: View {
    var entry: FortuneCookieEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            circularView
        case .accessoryRectangular:
            rectangularView
        case .accessoryInline:
            inlineView
        default:
            homeScreenView
        }
    }

    private var circularView: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 2) {
                Text("🥠")
                    .font(.caption2)
                Text("\(entry.remaining)")
                    .font(.system(.body, design: .rounded, weight: .bold))
            }
        }
    }

    private var rectangularView: some View {
        HStack(spacing: 8) {
            Text("🥠")
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text("포츈쿠키 \(entry.remaining)개 남음")
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)

                if let fortune = entry.lastFortune {
                    Text(fortune)
                        .font(.caption2)
                        .lineLimit(2)
                        .foregroundStyle(.secondary)
                } else if entry.remaining > 0 {
                    Text("버튼으로 부수기")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else {
                    Text("내일 다시 만나요")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            if entry.remaining > 0 {
                Button(intent: BreakCookieIntent()) {
                    Image(systemName: "hand.tap.fill")
                        .font(.caption)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var inlineView: some View {
        Text("🥠 포츈쿠키 \(entry.remaining)개 남음")
    }

    private var homeScreenView: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.22, green: 0.12, blue: 0.28),
                            Color(red: 0.15, green: 0.08, blue: 0.18),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 12) {
                Text("🥠")
                    .font(.largeTitle)

                Text("오늘 \(entry.remaining)개 남음")
                    .font(.headline)
                    .foregroundStyle(.white)

                if let fortune = entry.lastFortune {
                    Text(fortune)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .padding(.horizontal, 8)
                }

                if entry.remaining > 0 {
                    Button(intent: BreakCookieIntent()) {
                        Label("부수기", systemImage: "hand.tap.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.orange)
                    }
                    .buttonStyle(.plain)
                } else {
                    Text("내일 다시 만나요")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .padding()
        }
    }
}

struct FortuneCookieWidget: Widget {
    let kind = "FortuneCookieWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FortuneCookieProvider()) { entry in
            FortuneCookieWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    Color(red: 0.15, green: 0.08, blue: 0.18)
                }
        }
        .configurationDisplayName("포츈쿠키")
        .description("잠금화면에서 포츈쿠키를 부수고 운세를 확인하세요.")
        .supportedFamilies([
            .systemSmall,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline,
        ])
    }
}

#Preview(as: .systemSmall) {
    FortuneCookieWidget()
} timeline: {
    FortuneCookieEntry(date: Date(), remaining: 2, lastFortune: "오늘은 작은 용기가 큰 기회를 부를 거예요.")
}
