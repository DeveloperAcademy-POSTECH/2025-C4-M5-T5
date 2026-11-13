import Foundation

/// 현재 게임의 결과 확정 revision을 식별자로 사용해 재전송·재시도에도 같은 결과를 유지한다.
struct StoredYutResult: Codable, Equatable, Identifiable, Sendable {
    let id: Int
    let result: YutResult

    init(id: Int, result: YutResult) {
        self.id = id
        self.result = result
    }
}
