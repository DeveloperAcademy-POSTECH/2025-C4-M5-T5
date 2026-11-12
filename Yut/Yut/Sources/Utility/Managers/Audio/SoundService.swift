import AVFoundation
import OSLog

/// 입력 전에 효과음을 준비한다. 원본 모으기 속도 1.2와 충돌 효과음은 유지한다.
@MainActor
final class SoundService: NSObject, AVAudioPlayerDelegate, GameSoundPlaying {
    private let audioSession: AVAudioSession
    private let logger = Logger(subsystem: "Yut", category: "Sound")
    private var players: [String: AVAudioPlayer] = [:]
    private var isActive = false

    init(audioSession: AVAudioSession) { self.audioSession = audioSession; super.init() }

    func prepare() {
        do {
            if !isActive {
                try audioSession.setCategory(.playback, mode: .default)
                try audioSession.setActive(true)
                isActive = true
            }
            for name in ["CollectYut", "ShootAndYut"] {
                if players[name] == nil {
                    guard let url = Bundle.main.url(forResource: name, withExtension: "mp3") else { continue }
                    let player = try AVAudioPlayer(contentsOf: url)
                    player.enableRate = true
                    player.rate = name == "CollectYut" ? 1.2 : 1
                    player.delegate = self
                    players[name] = player
                }
                if let player = players[name], !player.isPlaying, !player.prepareToPlay() { logger.error("효과음 준비 실패") }
            }
        } catch { logger.error("오디오 준비 실패: \(error.localizedDescription)") }
    }

    func playCollectYutSound() { play("CollectYut") }
    func playCollisionSound() { play("ShootAndYut") }

    func stop() {
        players.values.forEach { $0.delegate = nil; $0.stop() }
        players = [:]
        guard isActive else { return }
        do { try audioSession.setActive(false, options: .notifyOthersOnDeactivation); isActive = false }
        catch { logger.error("오디오 중단 실패: \(error.localizedDescription)") }
    }

    private func play(_ name: String) {
        guard let player = players[name] else { return }
        for other in players.values where other !== player { other.pause() }
        player.currentTime = 0
        if !player.play() { logger.error("효과음 재생 실패") }
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor [weak self] in
            guard let self, players.values.contains(where: { $0 === player }), !player.isPlaying else { return }
            if !player.prepareToPlay() { logger.error("효과음 재준비 실패") }
        }
    }
}
