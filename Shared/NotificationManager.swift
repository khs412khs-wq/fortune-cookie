import UserNotifications

enum NotificationManager {
    static func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    static func showFortune(
        _ fortune: String,
        remainingPersonal: Int,
        remainingGift: Int
    ) {
        let content = UNMutableNotificationContent()
        content.title = "🥠 오늘의 포츈쿠키"
        content.body = fortune
        content.sound = .default

        if remainingPersonal == 0 && remainingGift == 0 {
            content.subtitle = "오늘의 포츈쿠키를 모두 열었어요"
        } else {
            content.subtitle = "내 쿠키 \(remainingPersonal)개 · 선물 \(remainingGift)개 남음"
        }

        let request = UNNotificationRequest(
            identifier: "fortune-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }
}
