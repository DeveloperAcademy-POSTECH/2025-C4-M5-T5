import Foundation
import simd

/// 던진 사람의 카메라 자세를 공유 말판 앵커 기준(미터 단위, 배율 제외)으로 저장한다.
/// 각 기기의 카메라에서 따로 던지지 않도록 명령과 게임 스냅샷에 함께 전송한다.
struct YutThrowLaunch: Codable, Equatable, Sendable {
    let cameraPosition: SIMD3<Float>
    let cameraRotation: SIMD4<Float>
    /// 원본의 축 보정과 투사자의 월드 카메라 회전 조합. 수신 기기의 월드 원점으로 다시 계산하지 않는다.
    let yutLocalRotation: SIMD4<Float>

    var isValid: Bool {
        cameraPosition.indices.allSatisfy { cameraPosition[$0].isFinite }
            && cameraRotation.indices.allSatisfy { cameraRotation[$0].isFinite }
            && abs(simd_length(cameraRotation) - 1) < 0.001
            && yutLocalRotation.indices.allSatisfy { yutLocalRotation[$0].isFinite }
            && abs(simd_length(yutLocalRotation) - 1) < 0.001
    }
}
