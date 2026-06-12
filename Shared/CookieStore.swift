import Foundation

enum CookieMode: String, Codable {
    case personal
    case gift
}

enum CookieBreakFailure: Equatable {
    case dailyLimitReached(CookieMode)
    case cooldownActive
}

struct CookieBreakResult {
    let success: Bool
    let fortune: String?
    let remainingPersonal: Int
    let remainingGift: Int
    let personalSlotsUsed: [Bool]
    let giftSlotsUsed: [Bool]
    let mode: CookieMode
    let failure: CookieBreakFailure?

    init(
        success: Bool,
        fortune: String?,
        remainingPersonal: Int,
        remainingGift: Int,
        personalSlotsUsed: [Bool],
        giftSlotsUsed: [Bool],
        mode: CookieMode,
        failure: CookieBreakFailure? = nil
    ) {
        self.success = success
        self.fortune = fortune
        self.remainingPersonal = remainingPersonal
        self.remainingGift = remainingGift
        self.personalSlotsUsed = personalSlotsUsed
        self.giftSlotsUsed = giftSlotsUsed
        self.mode = mode
        self.failure = failure
    }
}

struct CookieState: Codable, Equatable {
    var remainingPersonal: Int
    var remainingGift: Int
    var personalSlotsUsed: [Bool]
    var giftSlotsUsed: [Bool]
    var lastFortune: String?
    var lastBreakMode: CookieMode?
    var usedFortunes: [String]
    var lastBrokenDate: Date?

    /// 하루에 열 수 있는 내 쿠키 개수
    static let personalLimit = 3
    /// 하루에 열 수 있는 선물 쿠키 개수
    static let giftLimit = 2

    static var totalDailyLimit: Int {
        personalLimit + giftLimit
    }

    var remainingTotal: Int {
        remainingPersonal + remainingGift
    }

    var isDailyLimitReached: Bool {
        remainingTotal == 0
    }

    static let empty = CookieState(
        remainingPersonal: personalLimit,
        remainingGift: giftLimit,
        personalSlotsUsed: Array(repeating: false, count: personalLimit),
        giftSlotsUsed: Array(repeating: false, count: giftLimit),
        lastFortune: nil,
        lastBreakMode: nil,
        usedFortunes: [],
        lastBrokenDate: nil
    )

    enum CodingKeys: String, CodingKey {
        case remainingPersonal
        case remainingGift
        case personalSlotsUsed
        case giftSlotsUsed
        case remainingToday
        case lastFortune
        case lastBreakMode
        case usedFortunes
        case lastBrokenDate
    }

    init(
        remainingPersonal: Int,
        remainingGift: Int,
        personalSlotsUsed: [Bool],
        giftSlotsUsed: [Bool],
        lastFortune: String?,
        lastBreakMode: CookieMode?,
        usedFortunes: [String],
        lastBrokenDate: Date?
    ) {
        self.remainingPersonal = remainingPersonal
        self.remainingGift = remainingGift
        self.personalSlotsUsed = personalSlotsUsed
        self.giftSlotsUsed = giftSlotsUsed
        self.lastFortune = lastFortune
        self.lastBreakMode = lastBreakMode
        self.usedFortunes = usedFortunes
        self.lastBrokenDate = lastBrokenDate
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let personal = try container.decodeIfPresent(Int.self, forKey: .remainingPersonal),
           let gift = try container.decodeIfPresent(Int.self, forKey: .remainingGift) {
            remainingPersonal = personal
            remainingGift = gift
        } else {
            let legacyRemaining = try container.decode(Int.self, forKey: .remainingToday)
            remainingPersonal = min(legacyRemaining, Self.personalLimit)
            remainingGift = Self.giftLimit
        }

        if let slots = try container.decodeIfPresent([Bool].self, forKey: .personalSlotsUsed),
           slots.count == Self.personalLimit {
            personalSlotsUsed = slots
        } else {
            personalSlotsUsed = Self.makePersonalSlotsUsed(remaining: remainingPersonal)
        }

        if let slots = try container.decodeIfPresent([Bool].self, forKey: .giftSlotsUsed),
           slots.count == Self.giftLimit {
            giftSlotsUsed = slots
        } else {
            giftSlotsUsed = Self.makeGiftSlotsUsed(remaining: remainingGift)
        }

        lastFortune = try container.decodeIfPresent(String.self, forKey: .lastFortune)
        lastBreakMode = try container.decodeIfPresent(CookieMode.self, forKey: .lastBreakMode)
        usedFortunes = try container.decodeIfPresent([String].self, forKey: .usedFortunes) ?? []
        lastBrokenDate = try container.decodeIfPresent(Date.self, forKey: .lastBrokenDate)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(remainingPersonal, forKey: .remainingPersonal)
        try container.encode(remainingGift, forKey: .remainingGift)
        try container.encode(personalSlotsUsed, forKey: .personalSlotsUsed)
        try container.encode(giftSlotsUsed, forKey: .giftSlotsUsed)
        try container.encodeIfPresent(lastFortune, forKey: .lastFortune)
        try container.encodeIfPresent(lastBreakMode, forKey: .lastBreakMode)
        try container.encode(usedFortunes, forKey: .usedFortunes)
        try container.encodeIfPresent(lastBrokenDate, forKey: .lastBrokenDate)
    }

    static func makePersonalSlotsUsed(remaining: Int) -> [Bool] {
        let usedCount = max(0, min(personalLimit, personalLimit - remaining))
        return (0..<personalLimit).map { $0 < usedCount }
    }

    static func makeGiftSlotsUsed(remaining: Int) -> [Bool] {
        let usedCount = max(0, min(giftLimit, giftLimit - remaining))
        return (0..<giftLimit).map { $0 < usedCount }
    }

    mutating func normalizePersonalSlots() {
        if personalSlotsUsed.count != Self.personalLimit {
            personalSlotsUsed = Self.makePersonalSlotsUsed(remaining: remainingPersonal)
        }
    }

    mutating func syncRemainingPersonalFromSlots() {
        normalizePersonalSlots()
        remainingPersonal = personalSlotsUsed.filter { !$0 }.count
    }

    mutating func consumePersonalSlot(at index: Int) -> Bool {
        normalizePersonalSlots()
        guard index >= 0, index < personalSlotsUsed.count, !personalSlotsUsed[index] else {
            return false
        }
        personalSlotsUsed[index] = true
        syncRemainingPersonalFromSlots()
        return true
    }

    mutating func restoreLeftmostPersonalSlot() -> Bool {
        normalizePersonalSlots()
        guard let index = personalSlotsUsed.firstIndex(where: { $0 }) else {
            return false
        }
        personalSlotsUsed[index] = false
        syncRemainingPersonalFromSlots()
        return true
    }

    mutating func normalizeGiftSlots() {
        if giftSlotsUsed.count != Self.giftLimit {
            giftSlotsUsed = Self.makeGiftSlotsUsed(remaining: remainingGift)
        }
    }

    mutating func syncRemainingGiftFromSlots() {
        normalizeGiftSlots()
        remainingGift = giftSlotsUsed.filter { !$0 }.count
    }

    mutating func consumeGiftSlot(at index: Int) -> Bool {
        normalizeGiftSlots()
        guard index >= 0, index < giftSlotsUsed.count, !giftSlotsUsed[index] else {
            return false
        }
        giftSlotsUsed[index] = true
        syncRemainingGiftFromSlots()
        return true
    }
}

enum CookieStore {
    static let appGroupID = "group.com.fortunecookie.shared"
    static let stateKey = "cookieState"
    static let calendar = Calendar.current
    private static let breakCooldown: TimeInterval = 1.5
    private static var lastBreakAttemptAt: Date?

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    static func load() -> CookieState {
        resetIfNeeded()
        guard
            let data = defaults.data(forKey: stateKey),
            let state = try? JSONDecoder().decode(CookieState.self, from: data)
        else {
            return .empty
        }
        return state
    }

    static func save(_ state: CookieState) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        defaults.set(data, forKey: stateKey)
    }

    // MARK: - Debug
    #if DEBUG
    static func debugReset() {
        save(.empty)
        lastBreakAttemptAt = nil
    }
    #endif

    static func resetIfNeeded() {
        guard
            let data = defaults.data(forKey: stateKey),
            let state = try? JSONDecoder().decode(CookieState.self, from: data),
            let lastDate = state.lastBrokenDate
        else { return }

        if !calendar.isDate(lastDate, inSameDayAs: Date()) {
            save(.empty)
            lastBreakAttemptAt = nil
        }
    }

    static func isOnBreakCooldown() -> Bool {
        guard let lastBreakAttemptAt else { return false }
        return Date().timeIntervalSince(lastBreakAttemptAt) < breakCooldown
    }

    static var personalSlotsUsed: [Bool] {
        var state = load()
        state.normalizePersonalSlots()
        return state.personalSlotsUsed
    }

    static var giftSlotsUsed: [Bool] {
        var state = load()
        state.normalizeGiftSlots()
        return state.giftSlotsUsed
    }

    private static func makeResult(
        from state: CookieState,
        success: Bool,
        fortune: String?,
        mode: CookieMode,
        failure: CookieBreakFailure? = nil
    ) -> CookieBreakResult {
        var normalized = state
        normalized.normalizePersonalSlots()
        normalized.normalizeGiftSlots()
        return CookieBreakResult(
            success: success,
            fortune: fortune,
            remainingPersonal: normalized.remainingPersonal,
            remainingGift: normalized.remainingGift,
            personalSlotsUsed: normalized.personalSlotsUsed,
            giftSlotsUsed: normalized.giftSlotsUsed,
            mode: mode,
            failure: failure
        )
    }

    @discardableResult
    static func breakCookie(mode: CookieMode = .personal, slotIndex: Int? = nil) -> CookieBreakResult {
        resetIfNeeded()
        var state = load()
        state.normalizePersonalSlots()
        state.normalizeGiftSlots()

        if isOnBreakCooldown() {
            return makeResult(
                from: state,
                success: false,
                fortune: nil,
                mode: mode,
                failure: .cooldownActive
            )
        }

        switch mode {
        case .personal:
            guard state.remainingPersonal > 0 else {
                return makeResult(
                    from: state,
                    success: false,
                    fortune: nil,
                    mode: mode,
                    failure: .dailyLimitReached(.personal)
                )
            }
        case .gift:
            guard state.remainingGift > 0 else {
                return makeResult(
                    from: state,
                    success: false,
                    fortune: nil,
                    mode: mode,
                    failure: .dailyLimitReached(.gift)
                )
            }
        }

        lastBreakAttemptAt = Date()

        let usedSet = Set(state.usedFortunes)
        let fortune = FortuneData.randomFortune(excluding: usedSet)

        switch mode {
        case .personal:
            let index = slotIndex ?? state.personalSlotsUsed.firstIndex(where: { !$0 })
            guard let index, state.consumePersonalSlot(at: index) else {
                return makeResult(
                    from: state,
                    success: false,
                    fortune: nil,
                    mode: mode,
                    failure: .dailyLimitReached(.personal)
                )
            }
        case .gift:
            break
        }

        state.lastFortune = fortune
        state.lastBreakMode = mode
        state.usedFortunes.append(fortune)
        state.lastBrokenDate = Date()
        save(state)

        return makeResult(
            from: state,
            success: true,
            fortune: fortune,
            mode: mode
        )
    }

    static var canBreakPersonal: Bool {
        load().remainingPersonal > 0
    }

    static var canBreakGift: Bool {
        load().remainingGift > 0
    }

    static func fortuneForPendingGift() -> String? {
        resetIfNeeded()
        let state = load()
        guard state.remainingGift > 0 else { return nil }
        return FortuneData.randomFortune(excluding: Set(state.usedFortunes))
    }

    @discardableResult
    static func restorePersonalCookieAfterShare() -> CookieBreakResult {
        resetIfNeeded()
        var state = load()
        state.normalizePersonalSlots()

        guard state.personalSlotsUsed.contains(true) else {
            return makeResult(
                from: state,
                success: false,
                fortune: state.lastFortune,
                mode: .personal
            )
        }

        _ = state.restoreLeftmostPersonalSlot()
        save(state)
        lastBreakAttemptAt = nil

        return makeResult(
            from: state,
            success: true,
            fortune: state.lastFortune,
            mode: .personal
        )
    }

    @discardableResult
    static func consumeGiftCookie(fortune: String, slotIndex: Int) -> CookieBreakResult {
        resetIfNeeded()
        var state = load()

        state.normalizePersonalSlots()
        state.normalizeGiftSlots()

        if isOnBreakCooldown() {
            return makeResult(
                from: state,
                success: false,
                fortune: nil,
                mode: .gift,
                failure: .cooldownActive
            )
        }

        guard state.remainingGift > 0 else {
            return makeResult(
                from: state,
                success: false,
                fortune: nil,
                mode: .gift,
                failure: .dailyLimitReached(.gift)
            )
        }

        lastBreakAttemptAt = Date()
        guard state.consumeGiftSlot(at: slotIndex) else {
            return makeResult(
                from: state,
                success: false,
                fortune: nil,
                mode: .gift,
                failure: .dailyLimitReached(.gift)
            )
        }
        _ = state.restoreLeftmostPersonalSlot()
        state.lastFortune = fortune
        state.lastBreakMode = .gift
        state.usedFortunes.append(fortune)
        state.lastBrokenDate = Date()
        save(state)
        lastBreakAttemptAt = nil

        return makeResult(
            from: state,
            success: true,
            fortune: fortune,
            mode: .gift
        )
    }

    static var remainingPersonalCount: Int {
        load().remainingPersonal
    }

    static var remainingGiftCount: Int {
        load().remainingGift
    }

    static var remainingTotalCount: Int {
        load().remainingTotal
    }

    static var isDailyLimitReached: Bool {
        load().isDailyLimitReached
    }

    static var lastFortune: String? {
        load().lastFortune
    }

    static var lastBreakMode: CookieMode? {
        load().lastBreakMode
    }

}

struct GiftRecipient: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var phoneNumber: String

    init(id: UUID = UUID(), name: String, phoneNumber: String) {
        self.id = id
        self.name = name
        self.phoneNumber = phoneNumber
    }
}

enum GiftRecipientStore {
    static let recipientsKey = "giftRecipients"
    static let maxRecipients = 10

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: CookieStore.appGroupID) ?? .standard
    }

    static func load() -> [GiftRecipient] {
        guard
            let data = defaults.data(forKey: recipientsKey),
            let recipients = try? JSONDecoder().decode([GiftRecipient].self, from: data)
        else {
            return []
        }
        return recipients
    }

    static func save(_ recipients: [GiftRecipient]) {
        guard let data = try? JSONEncoder().encode(recipients) else { return }
        defaults.set(data, forKey: recipientsKey)
    }

    @discardableResult
    static func add(name: String, phoneNumber: String) -> Bool {
        var recipients = load()
        guard recipients.count < maxRecipients else { return false }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPhone = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return false }

        recipients.append(GiftRecipient(name: trimmedName, phoneNumber: trimmedPhone))
        save(recipients)
        return true
    }

    static func delete(id: UUID) {
        var recipients = load()
        recipients.removeAll { $0.id == id }
        save(recipients)
    }
}

enum FortuneShareHelper {
    static func shareText(for fortune: String) -> String {
        "🥠 오늘의 포츈쿠키\n\n\(fortune)\n\n나도 열어보기 👉"
    }

    static let giftShareHeadline = "HERE IS FORTUNE COOKIE FOR YOU! CRACK IT AND FORTUNE IT !"
    static let personalShareHeadline = "HOW'S YOUR FORTUNE TODAY?"
    static let soldOutHeadline = "SOLD OUT"

    static func giftShareText() -> String {
        giftShareHeadline
    }

    static func personalShareText() -> String {
        personalShareHeadline
    }

    static func giftText(for fortune: String, recipientName: String) -> String {
        "\(recipientName)님께 전하는 포츈쿠키 🥠\n\n\(fortune)\n\n나도 열어보기 👉 \(AppShareConfig.shareURL.absoluteString)"
    }
}
