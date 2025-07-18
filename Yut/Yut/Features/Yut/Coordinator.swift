

import Foundation
import CoreMotion
import RealityKit

final class Coordinator: NSObject {
    // CoreMotion 센서 매니저
    private let motionManager = CMMotionManager()
    
    // ARView에 직접 접근하기 위해 참조 보관
    private weak var arView: ARView?
    
    // 너무 자주 던지지 않도록 타이머 제한
    private var lastThrowTime = Date(timeIntervalSince1970: 0)
    
    // 초기화 시 ARView 주입
    init(arView: ARView) {
        self.arView = arView
        super.init()
    }
    
    /// CoreMotion의 장치 모션 센서를 사용해서
    /// "던지는 듯한 흔들림"을 감지하는 함수
    func startMonitoringMotion() {
        // 1. 기기가 "디바이스 모션" 기능을 지원하는지 확인
        // (디바이스 모션은: 중력, 회전, 사용자 가속도 등을 통합적으로 감지하는 센서)
        guard motionManager.isDeviceMotionAvailable else {
            print("❌ 디바이스 모션 사용 불가")
            return  // 사용 불가이면 아래 코드 실행하지 않고 종료
        }
        
        // 2. 센서 업데이트 주기 설정 (0.05초마다 → 초당 20번 데이터 받음)
        motionManager.deviceMotionUpdateInterval = 0.05
        
        // 3. 디바이스 모션 업데이트 시작
        //    → 센서 데이터를 지속적으로 수신하면서, 클로저 내부에서 처리함
        // 후행 클로저를 활용한 콜백 함수인거야?
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self, let motion = motion else { return }
            
            // 5. 현재 시점의 "순수한 사용자 가속도"만 가져옴
            //    (중력 제외된, 즉 손으로 흔들었을 때 발생한 가속도만)
            let acceleration = motion.userAcceleration
            
            // 6. 가속도의 크기(세기)를 계산
            //    → 벡터의 크기를 구하는 공식: √(x² + y² + z²)
            //    → 실제로 얼마나 세게 흔들었는지를 수치화함
            let magnitude = sqrt(
                acceleration.x * acceleration.x +
                acceleration.y * acceleration.y +
                acceleration.z * acceleration.z
            )
            
            // 7. 이 값을 판단 기준으로 쓸 임계값(Threshold)을 설정
            //    → 흔들림 세기가 1.5 이상일 때만 "던짐"으로 간주
            let threshold = 1.5  // 던지기 감지 민감도
            
            // 8. 이전에 윷을 던진 이후, 일정 시간(1초) 이상 지났는지도 확인
            //    → 연속 감지 방지 (의도치 않은 반복 던지기 차단)
            let cooldown: TimeInterval = 1.0  // 1초 간격 제한
            
            // 9. 조건 두 가지를 모두 만족해야 윷을 던짐
            //    (1) 흔들림 세기 > 임계값
            //    (2) 마지막 던짐 이후 1초 이상 경과
            if magnitude > threshold,
               Date().timeIntervalSince(self.lastThrowTime) > cooldown {
                
                // 10. 던짐 판정을 내렸다면, 현재 시간을 저장해 다음 감지를 잠시 막음
                self.lastThrowTime = Date()
                
                // 11. 실제로 윷을 던지는 물리 로직 실행
                self.throwYuts() // 🎯 감지되면 윷 던지기 실행
            }
        }
    }
    
    func throwYuts() {
        guard let arView = arView else { return }
        
        let spacing: Float = 0.07
        let impulseStrength: Float = 20.0
        
        guard let yutEntity = try? ModelEntity.loadModel(named: "Yut") else { // 윷 모델 불러오기
            print("❌ 오류: Yut.usdz 모델을 불러오지 못했습니다.")
            return
        }
        
        for i in 0..<4 {
            let yut = yutEntity.clone(recursive: true)
            
            // 물리 속성 정의 (중력, 질량, 반발력 등) - 커스텀 가능
            let physics = PhysicsBodyComponent( //중력/힘/충돌 적용
                massProperties: .default, // 질량 및 모양 관련
                material: .default, //마찰, 반발력 같은 물리 재질
                mode: .dynamic // 중력, 충돌 적용됨
            )
            
            yut.generateCollisionShapes(recursive: true) // 충돌 모양 생성 (실제 모델 생김새 기반)
            yut.components.set(physics) // 물리 컴포넌트 적용 (중력/충돌 활성화)
//            yut.components.set(PhysicsMotionComponent()) // 지속적인 힘 작용이 가능하도록 Motion 컴포넌트 설정
            var motion = PhysicsMotionComponent()
            motion.angularVelocity = .zero
            yut.components.set(motion)

            // 1. 현재 AR 세션에서 "카메라의 transform"을 가져온다.
            //    - ARKit은 매 프레임마다 기기의 위치와 회전을 추적하며,
            //    - `currentFrame?.camera.transform`은 4x4 행렬로 카메라의 위치/방향을 나타냄
            if let camTransform = arView.session.currentFrame?.camera.transform {
                
                // 2. 변환을 위한 기본 단위행렬을 만든다.
                //    - 단위행렬(identity matrix)은 아무런 변환도 없는 상태를 의미함.
                //    - 여기에 우리가 원하는 이동 값을 덧붙여 새로운 위치로 옮기게 됨.
                // matrix.columns.0 → x축 방향 벡터 (오른쪽 향함)
                // matrix.columns.1 → y축 방향 벡터 (위쪽 향함)
                // matrix.columns.2 → z축 방향 벡터 (앞/뒤 향함)
                // matrix.columns.3 → **위치 정보 (x, y, z, w)**
                var translation = matrix_identity_float4x4 // 현재 기본 위치
                
                // 3. z축 방향으로 -0.3m 이동시킴
                //    - z축은 "카메라가 보는 방향"을 의미함 (즉, 앞쪽)
                //    - -0.3은 카메라에서 앞쪽으로 30cm 떨어진 곳
                translation.columns.3.z = -1
                
                // 4. y축 방향으로 0.2m 위로 올림
                //    - y축은 "위쪽" 방향이므로 0.2은 20cm 위
                //    - 땅에 닿지 않고 공중에서 윷이 등장하게 됨
                translation.columns.3.y = 0.2
                
                
                // 5. x축 방향으로 좌우 위치를 조절
                //    - x축은 "좌우" 방향이므로
                //    - i: 0 ~ 3 → 각각 -1.5, -0.5, +0.5, +1.5 로 좌우 퍼지게 됨
                //    - spacing: 윷 간격 (예: 7cm)
                //    - 전체 윷이 가로로 나란히 놓이는 위치 계산
                translation.columns.3.x += (Float(i) - 1.5) * spacing
                
                // 6. 최종 변환 행렬 계산
                //    → 카메라 위치를 기준으로 위에서 만든 translation을 곱해
                //       카메라 앞·위·좌우에 적절히 배치된 좌표 계산
                let finalTransform = simd_mul(camTransform, translation)

                // 📌 yut의 위치, 회전, 크기 정보를 "최종 월드 좌표계"로 설정
                // finalTransform은 카메라 위치 + 이동값이 반영된 결과 행렬
                yut.transform.matrix = finalTransform

                //     현재 yut 엔티티의 위치(위치 + 회전 + 스케일)를 기반으로
                //     새로운 AnchorEntity를 생성한다.
                //     (즉, 현재 위치 그대로 월드 공간에 '고정'시킬 앵커를 만든다)
                let anchor = AnchorEntity(world: yut.transform.matrix)
                
                //     위에서 생성한 앵커의 자식으로 yut 엔티티를 붙인다.
                //     → yut는 anchor를 기준으로 위치가 결정된다.
                //     → anchor가 움직이면 yut도 함께 움직이게 된다.
                anchor.addChild(yut)
                
                //     구성한 앵커(= 위치 고정된 yut 포함)를 AR 장면(Scene)에 추가한다.
                //     → 이제 ARView에서 실제로 이 윷이 **보이고, 상호작용도 가능**해짐
                arView.scene.anchors.append(anchor)

                // impulse 적용
                // 📌 1. 카메라가 바라보는 방향(Z축)을 가져옴
                // ARKit/RealityKit에서는 카메라의 Z축이 '뒤쪽(눈 방향)'을 향하므로,
                // 반대 방향인 '-Z'가 우리가 던지고 싶은 '앞쪽'을 의미함
                let forward = -simd_make_float3(camTransform.columns.2)
                
                // 📌 2. 카메라 기준 좌우 방향(X축)을 가져옴
                // → 윷을 좌우로 퍼지게 만들기 위한 보조 방향 벡터
                let side = simd_make_float3(camTransform.columns.0)
                
                // 📌 3. 윷 하나하나에 적용할 최종 impulse(충격 힘) 벡터를 계산
                // forward: 카메라 앞 방향으로 던지는 힘
                // side * (...) : 좌우로 퍼지게 만드는 힘
                // (Float(i) - 1.5): 4개의 윷을 기준으로 좌우에 나눠서 적용
                let impulse = forward * impulseStrength /*+ side * (Float(i) - 1.5) * 1.0*/
                
                // 📌 4. 계산한 impulse 벡터를 실제 윷에 적용
                // applyLinearImpulse: RealityKit에서 순간적인 충격을 주는 메서드
                // relativeTo: nil → 월드 좌표계 기준으로 힘을 적용
                yut.applyLinearImpulse(impulse, relativeTo: nil)
            }
        }
    }
}
