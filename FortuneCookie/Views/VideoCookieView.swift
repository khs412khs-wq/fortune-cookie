import AVFoundation
import CoreText
import SwiftUI
import UIKit

enum VideoCookieDisplayMode {
    case firstFrame
    case playing
    case lastFrame
}

final class CookieVideoContainer: UIView {
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var crackBoundaryObserver: Any?
    private var paperBoundaryObserver: Any?
    private var playbackEndObserver: Any?
    private var didRevealPaper = false
    private var didFireCrackHaptic = false
    private var didFinishPlayback = false

    private let paperBackground = UIView()
    private let fortuneLabel = UILabel()
    private var fortuneRevealed = false
    private var currentFortuneText: String?

    var onComplete: (() -> Void)?
    var onCrackHaptic: (() -> Void)?
    var onPaperReveal: (() -> Void)?

    private let paperRevealSeconds: Double = CookieVideoLayout.paperRevealDelay
    private let crackHapticSeconds: Double = CookieVideoLayout.crackHapticDelay
    private let revealAnimationDuration: TimeInterval = 0.52
    private let textFadeInDuration: TimeInterval = 0.2

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        setupFortuneOverlay()
    }

    required init?(coder: NSCoder) {
        nil
    }

    private func setupFortuneOverlay() {
        paperBackground.backgroundColor = .clear
        paperBackground.isHidden = true
        paperBackground.alpha = 0
        addSubview(paperBackground)

        fortuneLabel.textColor = .black
        fortuneLabel.font = .systemFont(ofSize: 12, weight: .medium)
        fortuneLabel.numberOfLines = 2
        fortuneLabel.textAlignment = .center
        fortuneLabel.adjustsFontSizeToFitWidth = false
        fortuneLabel.lineBreakMode = .byWordWrapping
        fortuneLabel.backgroundColor = .clear
        paperBackground.clipsToBounds = true
        paperBackground.addSubview(fortuneLabel)
        fortuneLabel.alpha = 0
    }

    func configure(videoName: String) {
        guard player == nil,
              let url = Bundle.main.url(forResource: videoName, withExtension: "mp4")
        else { return }

        configureAudioSession()

        let item = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: item)
        player.isMuted = false
        player.volume = 1
        self.player = player

        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = .resizeAspect
        layer.backgroundColor = UIColor.clear.cgColor
        self.layer.insertSublayer(layer, at: 0)
        playerLayer = layer

        showFirstFrame()
    }

    func updateFortune(_ text: String?, visible: Bool) {
        currentFortuneText = text
        applyFortuneDisplay(text)

        guard visible, text != nil else {
            fortuneRevealed = false
            hideFortuneOverlay()
            return
        }

        guard !fortuneRevealed else { return }

        fortuneRevealed = true
        revealFortuneOverlayAnimated()
    }

    private func revealFortuneOverlayAnimated() {
        paperBackground.layer.removeAllAnimations()
        fortuneLabel.layer.removeAllAnimations()
        paperBackground.isHidden = false
        paperBackground.alpha = 1
        paperBackground.transform = collapsedPaperTransform()
        applyFortuneDisplay(currentFortuneText)
        fortuneLabel.alpha = 0

        UIView.animate(
            withDuration: revealAnimationDuration,
            delay: 0,
            usingSpringWithDamping: 0.82,
            initialSpringVelocity: 0.35,
            options: [.curveEaseOut, .allowUserInteraction],
            animations: {
                self.paperBackground.transform = self.expandedPaperTransform()
            },
            completion: { _ in
                self.fadeInFortuneText()
            }
        )
    }

    private func fadeInFortuneText() {
        applyFortuneDisplay(currentFortuneText)
        UIView.animate(
            withDuration: textFadeInDuration,
            delay: 0,
            options: [.curveEaseIn, .allowUserInteraction]
        ) {
            self.fortuneLabel.alpha = 1
        }
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // Video may still play without session configuration.
        }
    }

    @MainActor
    func makeShareCapture(canvasSize: CGSize, fortune: String? = nil, zoom: CGFloat = CookieVideoLayout.zoom) async -> UIImage? {
        if let fortune, !fortune.isEmpty {
            currentFortuneText = fortune
        }
        if bounds.width <= 0 || bounds.height <= 0, canvasSize.width > 0, canvasSize.height > 0 {
            frame = CGRect(origin: frame.origin, size: canvasSize)
        }

        layoutIfNeeded()

        let renderSize = bounds.size
        guard renderSize.width > 0, renderSize.height > 0 else { return nil }

        await withCheckedContinuation { continuation in
            seekToLastFrame {
                continuation.resume()
            }
        }

        guard let videoFrame = await loadVideoFrameForCapture() else { return nil }

        freezeFortuneForCapture()
        layoutIfNeeded()

        let canvas = renderShareCanvas(videoFrame: videoFrame, canvasSize: renderSize)
        return FortuneShareComposer.zoomCrop(
            canvas,
            zoom: zoom,
            outputSize: renderSize
        )
    }

    private func loadVideoFrameForCapture() async -> UIImage? {
        if let asset = player?.currentItem?.asset,
           let image = await Self.extractLastFrame(from: asset) {
            return image
        }
        return await Self.loadLastVideoFrameFromBundle()
    }

    private func freezeFortuneForCapture() {
        guard currentFortuneText != nil else { return }

        paperBackground.layer.removeAllAnimations()
        fortuneLabel.layer.removeAllAnimations()
        paperBackground.isHidden = false
        paperBackground.alpha = 1
        paperBackground.transform = expandedPaperTransform()
        applyFortuneDisplay(currentFortuneText)
        fortuneLabel.alpha = 1
    }

    private func renderShareCanvas(videoFrame: UIImage, canvasSize: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = UIScreen.main.scale
        let renderer = UIGraphicsImageRenderer(size: canvasSize, format: format)

        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: canvasSize))

            let videoRect = Self.aspectFitRect(for: videoFrame.size, in: CGRect(origin: .zero, size: canvasSize))
            videoFrame.draw(in: videoRect)

            if !paperBackground.isHidden, fortuneLabel.alpha > 0,
               let paperSnapshot = snapshotPaperOverlay() {
                let paperSize = paperBackground.bounds.size
                let drawRect = CGRect(
                    x: -paperSize.width / 2,
                    y: -paperSize.height / 2,
                    width: paperSize.width,
                    height: paperSize.height
                )

                context.cgContext.saveGState()
                context.cgContext.translateBy(x: paperBackground.center.x, y: paperBackground.center.y)
                context.cgContext.concatenate(paperBackground.transform)
                paperSnapshot.draw(in: drawRect)
                context.cgContext.restoreGState()
            }
        }
    }

    private func snapshotPaperOverlay() -> UIImage? {
        let size = paperBackground.bounds.size
        guard size.width > 0, size.height > 0 else { return nil }

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = UIScreen.main.scale
        let renderer = UIGraphicsImageRenderer(size: size, format: format)

        return renderer.image { _ in
            paperBackground.drawHierarchy(in: CGRect(origin: .zero, size: size), afterScreenUpdates: true)
        }
    }

    private static func loadLastVideoFrameFromBundle() async -> UIImage? {
        guard let url = Bundle.main.url(forResource: "todays_fortune", withExtension: "mp4") else {
            return nil
        }
        return await extractLastFrame(from: AVURLAsset(url: url))
    }

    private static func extractLastFrame(from asset: AVAsset) async -> UIImage? {
        guard let duration = try? await asset.load(.duration),
              duration.seconds.isFinite,
              duration.seconds > 0
        else { return nil }

        let endSeconds = min(duration.seconds, CookieVideoLayout.playbackEndSeconds)
        let time = CMTime(seconds: max(endSeconds - 0.05, 0), preferredTimescale: 600)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = CMTime(seconds: 0.1, preferredTimescale: 600)
        generator.requestedTimeToleranceAfter = CMTime(seconds: 0.1, preferredTimescale: 600)

        if let cgImage = try? generator.copyCGImage(at: time, actualTime: nil) {
            return UIImage(cgImage: cgImage)
        }

        return await withCheckedContinuation { continuation in
            generator.generateCGImageAsynchronously(for: time) { cgImage, _, _ in
                if let cgImage {
                    continuation.resume(returning: UIImage(cgImage: cgImage))
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    private static func aspectFitRect(for imageSize: CGSize, in bounds: CGRect) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0 else { return .zero }

        let widthScale = bounds.width / imageSize.width
        let heightScale = bounds.height / imageSize.height
        let scale = min(widthScale, heightScale)
        let size = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)

        return CGRect(
            x: bounds.midX - size.width / 2,
            y: bounds.midY - size.height / 2,
            width: size.width,
            height: size.height
        )
    }

    func seekToLastFrameForDisplay() {
        seekToLastFrame {}
    }

    func restoreRevealedDisplay(fortune text: String?) {
        cancelPaperReveal()
        currentFortuneText = text
        seekToLastFrame { [weak self] in
            guard let self else { return }
            guard let text, !text.isEmpty else { return }

            self.fortuneRevealed = true
            self.paperBackground.isHidden = false
            self.paperBackground.alpha = 1
            self.paperBackground.transform = self.expandedPaperTransform()
            self.applyFortuneDisplay(text)
            self.fortuneLabel.alpha = 1
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }
    }

    private func seekToLastFrame(completion: @escaping () -> Void) {
        guard let player, let item = player.currentItem else {
            completion()
            return
        }

        let seconds = CMTimeGetSeconds(item.duration)
        guard seconds.isFinite, seconds > 0 else {
            completion()
            return
        }

        player.pause()
        let endSeconds = min(seconds, CookieVideoLayout.playbackEndSeconds)
        let target = CMTime(seconds: max(endSeconds - 0.05, 0), preferredTimescale: 600)
        player.seek(to: target, toleranceBefore: .zero, toleranceAfter: .zero) { _ in
            completion()
        }
    }

    func showFirstFrame() {
        cancelPaperReveal()
        fortuneRevealed = false
        hideFortuneOverlay()
        player?.pause()
        player?.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    func playFromStart() {
        cancelPaperReveal()
        fortuneRevealed = false
        didFinishPlayback = false
        hideFortuneOverlay()
        player?.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
            guard let self, let player = self.player else { return }
            HapticManager.prepareCrack()
            player.play()
            self.startPaperRevealTracking()
        }
    }

    private func hideFortuneOverlay() {
        paperBackground.layer.removeAllAnimations()
        fortuneLabel.layer.removeAllAnimations()
        paperBackground.isHidden = true
        paperBackground.alpha = 0
        paperBackground.transform = collapsedPaperTransform()
        fortuneLabel.alpha = 0
    }

    private func paperTransform(scaleX: CGFloat) -> CGAffineTransform {
        CookieVideoLayout.paperRotationTransform.concatenating(CGAffineTransform(scaleX: scaleX, y: 1.0))
    }

    private func collapsedPaperTransform() -> CGAffineTransform {
        paperTransform(scaleX: 0.02)
    }

    private func expandedPaperTransform() -> CGAffineTransform {
        paperTransform(scaleX: 1.0)
    }

    private func startPaperRevealTracking() {
        guard let player else { return }

        cancelPlaybackObservers()
        didRevealPaper = false
        didFireCrackHaptic = false

        let crackTarget = NSValue(time: CMTime(seconds: crackHapticSeconds, preferredTimescale: 600))
        let paperTarget = NSValue(time: CMTime(seconds: paperRevealSeconds, preferredTimescale: 600))
        let endTarget = NSValue(
            time: CMTime(seconds: CookieVideoLayout.playbackEndSeconds, preferredTimescale: 600)
        )

        paperBoundaryObserver = player.addBoundaryTimeObserver(
            forTimes: [paperTarget],
            queue: .main
        ) { [weak self] in
            self?.firePaperRevealIfNeeded()
        }

        crackBoundaryObserver = player.addBoundaryTimeObserver(
            forTimes: [crackTarget],
            queue: .main
        ) { [weak self] in
            self?.fireCrackHapticIfNeeded()
        }

        playbackEndObserver = player.addBoundaryTimeObserver(
            forTimes: [endTarget],
            queue: .main
        ) { [weak self] in
            self?.finishPlaybackIfNeeded()
        }
    }

    private func finishPlaybackIfNeeded() {
        guard !didFinishPlayback else { return }
        didFinishPlayback = true
        cancelPlaybackObservers()
        player?.pause()
        onComplete?()
    }

    private func fireCrackHapticIfNeeded() {
        guard !didFireCrackHaptic else { return }
        didFireCrackHaptic = true
        removeCrackObserver()
        onCrackHaptic?()
    }

    private func firePaperRevealIfNeeded() {
        guard !didRevealPaper else { return }
        didRevealPaper = true
        removePaperObserver()
        onPaperReveal?()
    }

    private func removeCrackObserver() {
        guard let crackBoundaryObserver, let player else { return }
        player.removeTimeObserver(crackBoundaryObserver)
        self.crackBoundaryObserver = nil
    }

    private func removePaperObserver() {
        guard let paperBoundaryObserver, let player else { return }
        player.removeTimeObserver(paperBoundaryObserver)
        self.paperBoundaryObserver = nil
    }

    private func removePlaybackEndObserver() {
        guard let playbackEndObserver, let player else { return }
        player.removeTimeObserver(playbackEndObserver)
        self.playbackEndObserver = nil
    }

    private func cancelPlaybackObservers() {
        removeCrackObserver()
        removePaperObserver()
        removePlaybackEndObserver()
    }

    private func cancelPaperReveal() {
        cancelPlaybackObservers()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = bounds

        let rect = CookieVideoLayout.paperRect(videoSize: bounds.size)
        paperBackground.bounds = CGRect(origin: .zero, size: rect.size)
        paperBackground.center = CGPoint(
            x: rect.midX + CookieVideoLayout.paperOffsetX,
            y: rect.midY
        )
        fortuneLabel.frame = paperBackground.bounds.insetBy(dx: 2, dy: 1)

        if fortuneRevealed, !paperBackground.isHidden, paperBackground.layer.animationKeys() == nil {
            paperBackground.transform = expandedPaperTransform()
        }
        if fortuneRevealed, !paperBackground.isHidden, fortuneLabel.alpha > 0 {
            applyFortuneDisplay(fortuneLabel.attributedText?.string ?? currentFortuneText)
        }

        bringSubviewToFront(paperBackground)
    }

    private func applyFortuneDisplay(_ text: String?) {
        guard let text, !text.isEmpty else {
            fortuneLabel.attributedText = nil
            return
        }

        let bounds = fortuneLabel.bounds.size
        guard bounds.width > 0, bounds.height > 0 else {
            fortuneLabel.attributedText = attributedFortune(text, fontSize: 10)
            return
        }

        let fontSize = bestFontSize(for: text, in: bounds)
        fortuneLabel.attributedText = attributedFortune(text, fontSize: fontSize)
    }

    private func attributedFortune(_ text: String, fontSize: CGFloat) -> NSAttributedString {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineBreakMode = .byWordWrapping
        paragraph.lineSpacing = 0

        return NSAttributedString(
            string: text,
            attributes: [
                .font: UIFont.systemFont(ofSize: fontSize, weight: .medium),
                .foregroundColor: UIColor.black,
                .paragraphStyle: paragraph,
            ]
        )
    }

    private func bestFontSize(for text: String, in bounds: CGSize) -> CGFloat {
        let minSize: CGFloat = 5
        let maxSize = max(bounds.height * 0.48, minSize)

        var low = minSize
        var high = maxSize
        var best = minSize

        while high - low > 0.1 {
            let mid = (low + high) / 2
            if fortuneFitsInTwoLines(text, fontSize: mid, in: bounds) {
                best = mid
                low = mid
            } else {
                high = mid
            }
        }

        if !fortuneFitsInTwoLines(text, fontSize: best, in: bounds) {
            var size = best
            while size > minSize {
                size -= 0.25
                if fortuneFitsInTwoLines(text, fontSize: size, in: bounds) {
                    return size
                }
            }
            return minSize
        }

        return best
    }

    private func fortuneFitsInTwoLines(_ text: String, fontSize: CGFloat, in bounds: CGSize) -> Bool {
        let attributed = attributedFortune(text, fontSize: fontSize)
        let framesetter = CTFramesetterCreateWithAttributedString(attributed)
        let length = (text as NSString).length

        var fitRange = CFRange()
        let fittedSize = CTFramesetterSuggestFrameSizeWithConstraints(
            framesetter,
            CFRange(location: 0, length: length),
            nil,
            CGSize(width: bounds.width, height: bounds.height),
            &fitRange
        )

        guard fitRange.length >= length else { return false }
        guard fittedSize.height <= bounds.height + 0.5 else { return false }

        let path = CGPath(
            rect: CGRect(origin: .zero, size: CGSize(width: bounds.width, height: .greatestFiniteMagnitude)),
            transform: nil
        )
        let frame = CTFramesetterCreateFrame(framesetter, CFRange(location: 0, length: length), path, nil)
        let lineCount = (CTFrameGetLines(frame) as NSArray).count
        return lineCount <= 2
    }

    deinit {
        cancelPaperReveal()
    }
}

struct VideoCookieView: UIViewRepresentable {
    let displayMode: VideoCookieDisplayMode
    let playToken: Int
    var fortune: String?
    var fortuneVisible: Bool
    var onContainerReady: ((CookieVideoContainer) -> Void)?
    var onCrackHaptic: (() -> Void)?
    var onPaperReveal: (() -> Void)?
    var onComplete: (() -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> CookieVideoContainer {
        let view = CookieVideoContainer()
        view.configure(videoName: "todays_fortune")
        context.coordinator.container = view
        publishContainer(view)
        return view
    }

    func updateUIView(_ uiView: CookieVideoContainer, context: Context) {
        uiView.onComplete = onComplete
        uiView.onCrackHaptic = onCrackHaptic
        uiView.onPaperReveal = onPaperReveal
        uiView.updateFortune(fortune, visible: fortuneVisible)

        switch displayMode {
        case .firstFrame:
            if context.coordinator.lastMode != .firstFrame {
                uiView.showFirstFrame()
            }
        case .playing:
            if playToken != context.coordinator.lastToken {
                context.coordinator.lastToken = playToken
                uiView.playFromStart()
            }
        case .lastFrame:
            if fortuneVisible {
                uiView.restoreRevealedDisplay(fortune: fortune)
            } else if context.coordinator.lastMode != .lastFrame {
                uiView.seekToLastFrameForDisplay()
            }
        }

        context.coordinator.lastMode = displayMode
        context.coordinator.container = uiView
        publishContainer(uiView)
    }

    private func publishContainer(_ container: CookieVideoContainer) {
        guard let onContainerReady else { return }
        Task { @MainActor in
            onContainerReady(container)
        }
    }

    final class Coordinator {
        var lastToken = -1
        var lastMode: VideoCookieDisplayMode?
        weak var container: CookieVideoContainer?
    }
}
