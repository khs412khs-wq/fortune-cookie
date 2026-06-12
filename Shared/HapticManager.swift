import CoreHaptics
import UIKit

enum HapticManager {
    private static let rigidGenerator = UIImpactFeedbackGenerator(style: .rigid)
    private static let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private static let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private static let softGenerator = UIImpactFeedbackGenerator(style: .soft)
    private static let notificationGenerator = UINotificationFeedbackGenerator()

    private static var hapticEngine: CHHapticEngine?
    private static var supportsCoreHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics
    private static var lastCrackTimestamp: TimeInterval = 0

    static func tap() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }

    static func prepareCrack() {
        rigidGenerator.prepare()
        heavyGenerator.prepare()
        notificationGenerator.prepare()
        startHapticEngineIfNeeded()
    }

    static func crack() {
        let now = CACurrentMediaTime()
        guard now - lastCrackTimestamp > 0.2 else { return }
        lastCrackTimestamp = now

        startHapticEngineIfNeeded()
        playCoreHapticCrack()
        playUIKitCrack()
    }

    static func reveal() {
        notificationGenerator.prepare()
        notificationGenerator.notificationOccurred(.success)
    }

    static func denied() {
        notificationGenerator.prepare()
        notificationGenerator.notificationOccurred(.warning)
    }

    /// 다 쓴 빈 봉지 탭 — 비닐 찌그러지는 느낌
    static func emptyBag() {
        startHapticEngineIfNeeded()
        playCoreHapticEmptyBag()
        playUIKitEmptyBag()
    }

    private static func startHapticEngineIfNeeded() {
        guard supportsCoreHaptics else { return }

        if let engine = hapticEngine {
            try? engine.start()
            return
        }

        do {
            let engine = try CHHapticEngine()
            engine.isAutoShutdownEnabled = false
            engine.resetHandler = {
                try? hapticEngine?.start()
            }
            engine.stoppedHandler = { _ in
                try? hapticEngine?.start()
            }
            hapticEngine = engine
            try engine.start()
        } catch {
            hapticEngine = nil
        }
    }

    private static func playCoreHapticCrack() {
        guard let engine = hapticEngine else { return }

        do {
            try engine.start()

            let events = [
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0),
                    ],
                    relativeTime: 0
                ),
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0),
                    ],
                    relativeTime: 0.04
                ),
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.75),
                    ],
                    relativeTime: 0.09
                ),
                CHHapticEvent(
                    eventType: .hapticContinuous,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.35),
                    ],
                    relativeTime: 0.12,
                    duration: 0.18
                ),
            ]

            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            // UIKit fallback already runs in crack().
        }
    }

    private static func playCoreHapticEmptyBag() {
        guard let engine = hapticEngine else { return }

        do {
            try engine.start()

            let events = [
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.95),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0),
                    ],
                    relativeTime: 0
                ),
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.85),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9),
                    ],
                    relativeTime: 0.035
                ),
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.75),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.85),
                    ],
                    relativeTime: 0.07
                ),
                CHHapticEvent(
                    eventType: .hapticContinuous,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.55),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.65),
                    ],
                    relativeTime: 0.09,
                    duration: 0.12
                ),
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.65),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.55),
                    ],
                    relativeTime: 0.16
                ),
            ]

            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            // UIKit fallback already runs in emptyBag().
        }
    }

    private static func playUIKitEmptyBag() {
        rigidGenerator.prepare()
        rigidGenerator.impactOccurred(intensity: 1.0)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.035) {
            mediumGenerator.prepare()
            mediumGenerator.impactOccurred(intensity: 0.95)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.07) {
            rigidGenerator.prepare()
            rigidGenerator.impactOccurred(intensity: 0.85)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.11) {
            softGenerator.prepare()
            softGenerator.impactOccurred(intensity: 0.9)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            mediumGenerator.prepare()
            mediumGenerator.impactOccurred(intensity: 0.75)
        }
    }

    private static func playUIKitCrack() {
        rigidGenerator.prepare()
        rigidGenerator.impactOccurred(intensity: 1.0)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.04) {
            heavyGenerator.prepare()
            heavyGenerator.impactOccurred(intensity: 1.0)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            rigidGenerator.prepare()
            rigidGenerator.impactOccurred(intensity: 1.0)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            notificationGenerator.prepare()
            notificationGenerator.notificationOccurred(.error)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            heavyGenerator.prepare()
            heavyGenerator.impactOccurred(intensity: 1.0)
        }
    }
}
