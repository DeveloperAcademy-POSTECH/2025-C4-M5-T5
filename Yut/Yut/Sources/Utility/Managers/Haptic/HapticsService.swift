import CoreHaptics

/// 충돌 강도는 원본 값을 사용하고, 지원 기기에서 필요한 순간에만 엔진을 실행한다.
@MainActor
final class HapticsService {
    private var engine: CHHapticEngine?

    func stop() { engine?.stop(completionHandler: nil) }

    func playCollisionHaptic(with intensity: Float, sharpness: Float) {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        let intensityParam = CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity)
        let sharpnessParam = CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensityParam, sharpnessParam], relativeTime: 0)
        do {
            if engine == nil { engine = try CHHapticEngine() }
            try engine?.start()
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            // 햅틱 실패는 투사와 게임 진행을 중단하지 않는다.
            engine = nil
        }
    }
}
