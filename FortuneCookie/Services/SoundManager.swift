import AVFoundation
import AudioToolbox

final class SoundManager {
    static let shared = SoundManager()

    private var crackPlayer: AVAudioPlayer?
    private var revealPlayer: AVAudioPlayer?
    private var rustlePlayer: AVAudioPlayer?
    private var rustleStopWorkItem: DispatchWorkItem?
    private var lastRustleTimestamp: TimeInterval = 0
    private let rustlePlaybackDuration: TimeInterval = 0.65

    private init() {
        configureSession()
        loadSounds()
    }

    private func configureSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // Silent fallback — haptics still work
        }
    }

    private func loadSounds() {
        crackPlayer = player(for: "crack", ext: "wav")
        revealPlayer = player(for: "reveal", ext: "wav")
        rustlePlayer = player(for: "rustling_sound", ext: "mp4")
    }

    private func player(for name: String, ext: String) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else { return nil }
        let player = try? AVAudioPlayer(contentsOf: url)
        player?.prepareToPlay()
        return player
    }

    func playCrack() {
        if let crackPlayer {
            crackPlayer.currentTime = 0
            crackPlayer.play()
        } else {
            AudioServicesPlaySystemSound(1104)
        }
    }

    func playReveal() {
        if let revealPlayer {
            revealPlayer.currentTime = 0
            revealPlayer.play()
        } else {
            AudioServicesPlaySystemSound(1057)
        }
    }

    func playRustle() {
        let now = CACurrentMediaTime()
        guard now - lastRustleTimestamp > 0.12 else { return }
        lastRustleTimestamp = now

        guard let rustlePlayer else { return }

        rustleStopWorkItem?.cancel()
        rustlePlayer.currentTime = 0
        rustlePlayer.play()

        let work = DispatchWorkItem { [weak rustlePlayer] in
            rustlePlayer?.stop()
        }
        rustleStopWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + rustlePlaybackDuration, execute: work)
    }
}
