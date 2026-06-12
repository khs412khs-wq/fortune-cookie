import SwiftUI

enum EmptyBagFeedback {
    private static var lastPlayTimestamp: TimeInterval = 0

    static func play() {
        let now = CACurrentMediaTime()
        guard now - lastPlayTimestamp > 0.12 else { return }
        lastPlayTimestamp = now
        HapticManager.emptyBag()
        SoundManager.shared.playRustle()
    }
}

enum CookiePhase {
    case intact
    case breaking
    case revealed
}

struct CookieSelection: Equatable {
    let mode: CookieMode
    let slotIndex: Int
}

struct CookiePackRow: View {
    let remainingPersonal: Int
    let personalSlotsUsed: [Bool]
    let remainingGift: Int
    let giftSlotsUsed: [Bool]
    let isInteractive: Bool
    let isPersonalExhausted: Bool
    let onSelect: (CookieMode, Int) -> Void
    let onRevealSoldOut: () -> Void

    private let spacing: CGFloat = 0
    private let cookieCount: CGFloat = CGFloat(CookieState.personalLimit + CookieState.giftLimit)

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let cellSide = (width - spacing * (cookieCount - 1)) / cookieCount

            HStack(spacing: spacing) {
                ForEach(0..<CookieState.personalLimit, id: \.self) { index in
                    let used = isPersonalSlotUsed(at: index)
                    packImage(
                        name: used ? "cookie_empty" : "cookie_personal",
                        side: cellSide,
                        isAvailable: !used,
                        mode: .personal,
                        slotIndex: index
                    )
                }

                ForEach(0..<CookieState.giftLimit, id: \.self) { index in
                    let used = isGiftSlotUsed(at: index)
                    packImage(
                        name: used ? "cookie_empty" : "cookie_gift",
                        side: cellSide,
                        isAvailable: !used,
                        mode: .gift,
                        slotIndex: index
                    )
                }
            }
            .frame(width: width, height: cellSide, alignment: .center)
        }
        .aspectRatio(cookieCount, contentMode: .fit)
    }

    private func isPersonalSlotUsed(at index: Int) -> Bool {
        if remainingPersonal == 0 { return true }
        return index < personalSlotsUsed.count && personalSlotsUsed[index]
    }

    private func isGiftSlotUsed(at index: Int) -> Bool {
        if remainingGift == 0 { return true }
        return index < giftSlotsUsed.count && giftSlotsUsed[index]
    }

    @ViewBuilder
    private func packImage(
        name: String,
        side: CGFloat,
        isAvailable: Bool,
        mode: CookieMode,
        slotIndex: Int
    ) -> some View {
        Image(name)
            .resizable()
            .scaledToFit()
            .frame(width: side, height: side)
            .opacity(isAvailable ? 1 : 0.35)
            .contentShape(Rectangle())
            .onTapGesture {
                handlePackTap(mode: mode, slotIndex: slotIndex, isAvailable: isAvailable)
            }
    }

    private func handlePackTap(mode: CookieMode, slotIndex: Int, isAvailable: Bool) {
        guard isInteractive else { return }

        if isAvailable {
            onSelect(mode, slotIndex)
        } else {
            EmptyBagFeedback.play()
            if mode == .personal && isPersonalExhausted {
                onRevealSoldOut()
            }
        }
    }
}

struct CookieBreakView: View {
    let remainingPersonal: Int
    let remainingGift: Int
    let personalSlotsUsed: [Bool]
    let giftSlotsUsed: [Bool]
    let onBreak: (CookieMode, Int) -> CookieBreakResult
    let onGiftShareCompleted: (CookieBreakResult) -> Void
    let onPersonalShareCompleted: (CookieBreakResult) -> Void

    @State private var phase: CookiePhase = .intact
    @State private var selectedCookie: CookieSelection?
    @State private var currentBreakMode: CookieMode = .personal
    @State private var breakToken = 0
    @State private var pendingFortune: String?
    @State private var fortuneVisible = false
    @State private var isPreparingShare = false
    @State private var hasRestoredFromPersonalShare = false
    @State private var isPreparingGiftShare = false
    @State private var showShareError = false
    @State private var videoContainer: CookieVideoContainer?
    @State private var videoCanvasSize: CGSize = .zero
    @State private var showDailyLimitAlert = false
    @State private var dailyLimitMessage = ""
    @State private var pendingGiftSlotIndex: Int?
    @State private var pendingGiftFortune: String?
    @State private var videoSessionID = 0
    @State private var showSoldOutReveal = false

    @Environment(\.scenePhase) private var scenePhase

    private var canOpenMoreCookies: Bool {
        remainingPersonal > 0 || remainingGift > 0
    }

    private var isPersonalExhausted: Bool {
        remainingPersonal == 0
    }

    private var showExhaustedCenter: Bool {
        remainingPersonal == 0 && showSoldOutReveal
    }

    private var videoDisplayMode: VideoCookieDisplayMode {
        switch phase {
        case .intact:
            return .firstFrame
        case .breaking:
            return .playing
        case .revealed:
            return .lastFrame
        }
    }

    var body: some View {
        VStack(spacing: 10) {
            CookiePackRow(
                remainingPersonal: remainingPersonal,
                personalSlotsUsed: personalSlotsUsed,
                remainingGift: remainingGift,
                giftSlotsUsed: giftSlotsUsed,
                isInteractive: phase != .breaking && !isPreparingGiftShare,
                isPersonalExhausted: isPersonalExhausted,
                onSelect: selectCookieFromPack,
                onRevealSoldOut: revealSoldOut
            )
            .padding(.horizontal, 4)

            GeometryReader { geo in
                Group {
                    if showExhaustedCenter {
                        exhaustedCenterView(in: geo.size)
                    } else {
                        cookieVideoView(in: geo.size)
                    }
                }
                .offset(y: CookieVideoLayout.centerYOffset)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .overlay(alignment: .bottom) {
            if phase == .revealed, let fortune = pendingFortune, !showExhaustedCenter {
                resultActions(for: fortune)
                    .offset(y: -20)
            }
        }
        .alert("공유 이미지를 만들지 못했어요", isPresented: $showShareError) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("잠시 후 다시 시도해 주세요.")
        }
        .onAppear {
            restoreLaunchStateIfNeeded()
        }
        .onChange(of: remainingPersonal) { _, newValue in
            if newValue > 0 {
                showSoldOutReveal = false
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                restoreRevealedVideoIfNeeded()
            }
        }
        .alert("오늘은 여기까지예요", isPresented: $showDailyLimitAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(dailyLimitMessage)
        }
    }

    @ViewBuilder
    private func cookieVideoView(in size: CGSize) -> some View {
        let videoSize = CookieVideoLayout.videoSize(for: size.width)
        let tapSize = CookieVideoLayout.tapTargetSize(for: size)

        ZStack {
            VideoCookieView(
                displayMode: videoDisplayMode,
                playToken: breakToken,
                fortune: pendingFortune,
                fortuneVisible: fortuneVisible,
                onContainerReady: { videoContainer = $0 },
                onCrackHaptic: HapticManager.crack,
                onPaperReveal: revealPaper,
                onComplete: handleVideoComplete
            )
            .id(videoSessionID)
            .frame(width: videoSize.width, height: videoSize.height)
            .scaleEffect(CookieVideoLayout.contentScale, anchor: .center)
            // 시즌 배경색이 적용될 때 비디오의 흰 배경을 배경색에 녹아들게 함
            .allowsHitTesting(false)

            Color.clear
                .frame(width: tapSize.width, height: tapSize.height)
                .contentShape(Rectangle())
                .onTapGesture {
                    guard phase == .intact else { return }
                    openSelectedCookie()
                }
        }
        .frame(width: size.width, height: size.height)
        .clipped()
        .onAppear {
            videoCanvasSize = videoSize
        }
        .onChange(of: size.width) { _, width in
            videoCanvasSize = CookieVideoLayout.videoSize(for: width)
        }
    }

    @ViewBuilder
    private func exhaustedCenterView(in size: CGSize) -> some View {
        let side = min(size.width, size.height) * 0.72 * CookieVideoLayout.centerContentScale * CookieVideoLayout.exhaustedBagScale

        Image("cookie_exhausted")
            .resizable()
            .scaledToFit()
            .frame(width: side, height: side)
            .contentShape(Rectangle())
            .onTapGesture {
                EmptyBagFeedback.play()
            }
            .frame(width: size.width, height: size.height)
    }

    private func revealSoldOut() {
        guard remainingPersonal == 0 else { return }

        fortuneVisible = false
        pendingFortune = nil
        pendingGiftSlotIndex = nil
        pendingGiftFortune = nil
        selectedCookie = nil
        phase = .intact
        videoContainer = nil
        videoSessionID += 1

        withAnimation(.easeInOut(duration: 0.25)) {
            showSoldOutReveal = true
        }
    }

    private func resultActions(for fortune: String) -> some View {
        personalResultActions(for: fortune)
            .padding(.horizontal, 4)
    }

    private func personalResultActions(for fortune: String) -> some View {
        Button {
            startPersonalShare(fortune: fortune)
        } label: {
            if isPreparingShare {
                Text("...")
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(Color.orange)
            } else {
                AnimatedSharePersonalCTA()
                    .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(.plain)
        .padding(.vertical, 8)
        .disabled(isPreparingShare)
    }

    private func selectCookieFromPack(_ mode: CookieMode, slotIndex: Int) {
        guard phase != .breaking else { return }
        guard isSlotAvailable(mode: mode, slotIndex: slotIndex) else {
            HapticManager.denied()
            return
        }

        if mode == .gift {
            guard phase == .intact || phase == .revealed else { return }
            if phase == .revealed {
                resetForNextCookie()
            }
            pendingGiftSlotIndex = slotIndex
            selectedCookie = nil
            startGiftShare()
            return
        }

        if phase == .revealed {
            resetForNextCookie()
        }

        selectedCookie = CookieSelection(mode: .personal, slotIndex: slotIndex)
        HapticManager.tap()
    }

    private func openSelectedCookie() {
        guard phase != .breaking else { return }

        if remainingPersonal == 0 {
            EmptyBagFeedback.play()
            revealSoldOut()
            return
        }

        guard phase == .intact else { return }

        let slotIndex: Int
        if let selectedCookie,
           selectedCookie.mode == .personal,
           isSlotAvailable(mode: .personal, slotIndex: selectedCookie.slotIndex) {
            slotIndex = selectedCookie.slotIndex
        } else if let autoIndex = leftmostAvailablePersonalSlot() {
            slotIndex = autoIndex
            selectedCookie = CookieSelection(mode: .personal, slotIndex: autoIndex)
            HapticManager.tap()
        } else {
            HapticManager.denied()
            return
        }

        breakCookie(mode: .personal, slotIndex: slotIndex)
    }

    private func leftmostAvailablePersonalSlot() -> Int? {
        for index in 0..<CookieState.personalLimit where isSlotAvailable(mode: .personal, slotIndex: index) {
            return index
        }
        return nil
    }

    private func isSlotAvailable(mode: CookieMode, slotIndex: Int) -> Bool {
        switch mode {
        case .personal:
            guard slotIndex >= 0, slotIndex < CookieState.personalLimit else { return false }
            if slotIndex < personalSlotsUsed.count {
                return !personalSlotsUsed[slotIndex]
            }
            let usedCount = CookieState.personalLimit - remainingPersonal
            return slotIndex >= usedCount
        case .gift:
            guard slotIndex >= 0, slotIndex < giftSlotsUsed.count else { return false }
            return !giftSlotsUsed[slotIndex]
        }
    }

    private func breakCookie(mode: CookieMode, slotIndex: Int) {
        guard mode == .personal else { return }
        guard phase == .intact else { return }
        guard remainingPersonal > 0 else {
            HapticManager.denied()
            presentBreakFailure(.dailyLimitReached(.personal))
            return
        }

        HapticManager.tap()
        HapticManager.prepareCrack()

        currentBreakMode = .personal
        let result = onBreak(.personal, slotIndex)
        guard result.success, let fortune = result.fortune else {
            HapticManager.denied()
            presentBreakFailure(result.failure)
            return
        }

        pendingFortune = fortune
        fortuneVisible = false
        phase = .breaking
        breakToken += 1
        selectedCookie = nil
        hasRestoredFromPersonalShare = false
    }

    private func revealPaper() {
        guard pendingFortune != nil else { return }
        guard phase == .breaking || phase == .revealed else { return }
        guard !fortuneVisible else { return }

        fortuneVisible = true
    }

    private func handleVideoComplete() {
        guard phase == .breaking else { return }

        revealPaper()
        phase = .revealed
        HapticManager.reveal()
    }

    private func startGiftShare() {
        guard let slotIndex = pendingGiftSlotIndex else { return }
        guard isSlotAvailable(mode: .gift, slotIndex: slotIndex), remainingGift > 0 else {
            pendingGiftSlotIndex = nil
            HapticManager.denied()
            return
        }

        guard let fortune = CookieStore.fortuneForPendingGift() else {
            pendingGiftSlotIndex = nil
            HapticManager.denied()
            presentBreakFailure(.dailyLimitReached(.gift))
            return
        }

        pendingGiftFortune = fortune
        isPreparingGiftShare = true
        HapticManager.tap()

        Task { @MainActor in
            guard let image = FortuneShareComposer.randomGiftShareImage() else {
                isPreparingGiftShare = false
                pendingGiftSlotIndex = nil
                pendingGiftFortune = nil
                showShareError = true
                return
            }

            isPreparingGiftShare = false

            SystemShareManager.shareGift(image: image, fortune: fortune) { completed in
                Task { @MainActor in
                    let fortuneToConsume = pendingGiftFortune
                    let slotToConsume = pendingGiftSlotIndex
                    pendingGiftSlotIndex = nil
                    pendingGiftFortune = nil
                    selectedCookie = nil

                    guard completed,
                          let fortuneToConsume,
                          let slotToConsume else { return }

                    let result = CookieStore.consumeGiftCookie(
                        fortune: fortuneToConsume,
                        slotIndex: slotToConsume
                    )
                    if result.success {
                        onGiftShareCompleted(result)
                        handlePersonalCookieRestored(from: result)
                        HapticManager.tap()
                    } else {
                        HapticManager.denied()
                        presentBreakFailure(result.failure)
                    }
                }
            }
        }
    }

    private func startPersonalShare(fortune: String) {
        guard !isPreparingShare else { return }

        HapticManager.tap()
        isPreparingShare = true

        Task { @MainActor in
            let canvasSize = videoCanvasSize.width > 0
                ? videoCanvasSize
                : CookieVideoLayout.videoSize(for: UIScreen.main.bounds.width - 24)

            var container = videoContainer
            if container == nil {
                try? await Task.sleep(nanoseconds: 100_000_000)
                container = videoContainer
            }

            let shareImage = await FortuneShareComposer.buildResultShareImage(
                from: container,
                canvasSize: canvasSize,
                fortune: pendingFortune
            )

            isPreparingShare = false

            guard let shareImage else {
                showShareError = true
                return
            }

            SystemShareManager.shareFortune(image: shareImage, fortune: fortune) { completed in
                Task { @MainActor in
                    guard completed, !hasRestoredFromPersonalShare else { return }

                    let result = CookieStore.restorePersonalCookieAfterShare()
                    guard result.success else { return }

                    hasRestoredFromPersonalShare = true
                    onPersonalShareCompleted(result)
                    handlePersonalCookieRestored(from: result)
                    HapticManager.tap()
                }
            }
        }
    }

    private func resetForNextCookie() {
        fortuneVisible = false
        phase = .intact
        pendingFortune = nil
        pendingGiftSlotIndex = nil
        pendingGiftFortune = nil
        selectedCookie = nil
        hasRestoredFromPersonalShare = false
    }

    private func handlePersonalCookieRestored(from result: CookieBreakResult) {
        resetForNextCookie()
        showSoldOutReveal = false
        videoContainer = nil
        videoSessionID += 1

        if let index = result.personalSlotsUsed.firstIndex(where: { !$0 }) {
            selectedCookie = CookieSelection(mode: .personal, slotIndex: index)
        }
    }

    private func restoreRevealedVideoIfNeeded() {
        guard phase == .revealed, let fortune = pendingFortune else { return }
        videoContainer?.restoreRevealedDisplay(fortune: fortune)
    }

    private func restoreLaunchStateIfNeeded() {
        guard remainingPersonal == 0 else { return }

        phase = .intact
        fortuneVisible = false
        pendingFortune = nil
        selectedCookie = nil
        showSoldOutReveal = true
    }

    private func presentBreakFailure(_ failure: CookieBreakFailure?) {
        guard let failure else { return }

        switch failure {
        case .dailyLimitReached(let mode):
            dailyLimitMessage = mode == .personal
                ? "오늘의 내 쿠키를 모두 열었어요."
                : "오늘의 선물 쿠키를 모두 보냈어요."
            showDailyLimitAlert = true
        case .cooldownActive:
            break
        }
    }
}

private struct AnimatedSharePersonalCTA: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0)) { timeline in
            let isVisible = Int(timeline.date.timeIntervalSinceReferenceDate / 1.0) % 2 == 0

            ZStack {
                Image("share_personal_cta_base")
                    .resizable()
                    .scaledToFit()

                Image("share_personal_cta_share")
                    .resizable()
                    .scaledToFit()
                    .opacity(isVisible ? 1 : 0.15)
                    .animation(.easeInOut(duration: 0.45), value: isVisible)
            }
            .frame(height: 56)
        }
    }
}

