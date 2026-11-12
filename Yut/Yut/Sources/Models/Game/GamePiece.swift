import Foundation

/// 판 밖 대기와 완주를 분리하고, 진행 중에는 중복된 칸 이름 대신 경로·인덱스로 위치를 식별한다.
enum PiecePosition: Codable, Equatable, Hashable, Sendable {
    case home
    case onBoard(route: Int, index: Int)
    case finished
}

/// 네트워크로 공유하는 말의 논리 상태다. RealityKit 엔티티의 수명과는 분리한다.
struct GamePiece: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let playerID: UUID
    var position: PiecePosition
    /// 같은 플레이어의 말 중 이 값이 같으면 업힌 그룹으로 함께 이동한다.
    var groupID: UUID
    /// 현재 위치까지 실제로 지나온 순서다. 분기 이후 빽도와 업힌 말의 역이동에 사용한다.
    var history: [PiecePosition]

    /// 초기 위치가 진행 중이면 해당 경로의 시작부터 현재 위치까지 이력을 구성한다.
    /// 그룹을 지정하지 않은 말은 자신의 식별자를 사용해 독립적으로 이동한다.
    init(id: UUID = UUID(), playerID: UUID, position: PiecePosition = .home, groupID: UUID? = nil) {
        self.id = id
        self.playerID = playerID
        self.position = position
        self.groupID = groupID ?? id
        if case .onBoard(let route, let index) = position,
           GameBoard.routes.indices.contains(route), index > 0, index < GameBoard.routes[route].count {
            history = (1...index).map { .onBoard(route: route, index: $0) }
        } else {
            history = []
        }
    }

    var cell: String? { GameBoard.cell(for: position) }
}

/// 호스트가 확정해 모든 기기에 공유하는 게임 단계다. 기기별 AR 배치·재정렬 단계는 포함하지 않는다.
enum MatchPhase: String, Codable, Sendable {
    case preparing
    case readyToThrow
    case gathering
    case waitingForShake
    case throwing
    case showingResult
    case selectingPiece
    case selectingDestination
    case promptingForCarry
    case showingBonus
    case finished
}

/// 게임 규칙에 전달하는 명령이다. 발신 기기와 차례 검증은 `GameSessionController`가 수행한다.
enum GameAction: Codable, Equatable, Sendable {
    case startPlaying
    case beginThrow
    case armThrow
    case releaseThrow(launch: YutThrowLaunch)
    case recordThrow(YutResult)
    case dismissResult
    case selectPiece(UUID)
    case selectDestination(MoveDestination)
    case resolveCarry(Bool)
    case cancelSelection
    /// 중단된 로컬 투사를 무효화하고 같은 차례의 준비 단계로 돌아간다.
    case cancelThrow
}

/// 명령을 생성한 게임과 상태 버전을 함께 보내 이전 판·이전 차례의 요청을 식별한다.
struct GameRequest: Codable, Equatable, Sendable {
    let gameID: UUID
    let revision: Int
    let action: GameAction
}
