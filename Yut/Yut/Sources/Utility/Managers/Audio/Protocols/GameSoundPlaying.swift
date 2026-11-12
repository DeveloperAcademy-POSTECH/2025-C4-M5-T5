/// AR 세션 수명과 투사 효과음의 재생 경계다.
@MainActor
protocol GameSoundPlaying: AnyObject {
    func prepare()
    func stop()
    func playCollectYutSound()
    func playCollisionSound()
}
