import CoreHaptics

class HapticsService {
    private var engine: CHHapticEngine?

    init() {
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            print("✅ Haptic engine initialization failed:", error)
        }
    }

    func playCollisionHaptic(with intensity: Float, sharpness: Float) {
        let intensityParam = CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity)
        let sharpnessParam = CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)

        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [intensityParam, sharpnessParam],
            relativeTime: 0
        )

        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("✅ Failed to play custom haptic:", error)
        }
    }
}
