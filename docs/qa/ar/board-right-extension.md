# 말판 오른쪽 사각형 돌출

**상태: 검증 대기 · 우선순위: 중간 · 갱신: 2026-11-11**

배치 조정 화면에서 말판 오른쪽에 긴 사각형이 보인다는 제보다. **골인 지점을 포함해 넓어진 충돌 박스에서 그리기용 메시를 제거했다.** 시뮬레이터에서 긴 사각형이 사라지고 골인 지점이 남는 것을 확인했다. 골인 선택 기능과 기존 충돌 크기·위치·물리 설정은 유지했다. iPhone 15 Pro의 실제 화면·충돌 확인은 대기다.

## 코드·리소스에서 확인한 사실

| 항목 | 확인 결과 |
| --- | --- |
| 판 본체 | 실제 USDZ를 RealityKit으로 로드한 본체 범위는 약 **60.1 × 6.6 × 60.1cm** |
| 바깥 지점 | `end` 엔티티는 **골인 선택 지점**이다. 판 오른쪽에 있으며 약 8 × 0.4 × 8cm의 투명 재질이다 |
| 전체 범위 | 자식까지 포함하면 약 **72.2 × 6.8 × 60.1cm**. 중심도 오른쪽으로 약 6.0cm 이동한다 |
| 수정 전 충돌용 박스 | 전체 범위를 사용하므로 본체 오른쪽으로 약 **12.1cm** 더 나온다. 충돌 형상뿐 아니라 `generateBox` 메시와 `SimpleMaterial(color: .clear)`도 갖고 있었다 |
| 원본 비교 | 이 범위 계산·박스 메시·재질 생성 코드는 Git HEAD의 원본 Yut에도 있다. 최근 화면별 MVVM 정리에서 추가한 코드는 아니다 |
| 골인 지점 제외 대조 | 별도 분석용 메모리에서 `end`만 제외하면 전체 폭이 **72.2cm → 60.1cm**로 줄어든다. 충돌 박스가 넓어지는 원인은 이 지점으로 확인했다 |

근거: [BoardManager](../../../Yut/Yut/Sources/Utility/Managers/AR/BoardManager.swift#L28), [Board.usdz](../../../Yut/Yut/Resources/Models/Board/Board.usdz). 측정은 모델 기본 배율 기준이며 사용자가 조절한 실제 배치 크기와 구분한다. 본체는 `visualBounds(recursive: false, relativeTo: root)`, 전체는 재귀 범위로 비교했다.

Apple의 [`visualBounds`](https://developer.apple.com/documentation/RealityKit/HasTransform/visualBounds%28recursive%3ArelativeTo%3AexcludeInactive%3A%29)는 기본적으로 자식 엔티티도 포함한다. [충돌 형상](https://developer.apple.com/documentation/realitykit/physics-collision-detection)은 물리·충돌 검사용이며, 충돌을 위해 그리기용 박스 메시까지 만들 필요는 없다.

골인 용도는 당시 원본 `BoardModel`의 모든 경로가 `end`로 끝나는 점과 현재 [GameBoard](../../../Yut/Yut/Sources/Models/Game/GameBoard.swift#L13)의 `isFinish`로 확인했다. 사용하지 않는 `BoardModel` 파일은 11월 12일 [디렉토리 정리](../structure/directory-structure-review.md#디렉토리-적용-결과--2026-11-12)에서 제거했다. 현재 [ARCoordinator](../../../Yut/Yut/Sources/Utility/Managers/AR/ARCoordinator.swift#L290)는 골인 후보의 `end`를 하이라이트하고, 같은 이름의 선택을 이동 액션에 전달한다. [GameState](../../../Yut/Yut/Sources/Models/Game/GameState.swift#L146)는 이를 `.finished`로 처리한다. 따라서 골인 엔티티를 단순 삭제하면 골인 선택 연결이 깨질 수 있다.

## 수정 범위

`BoardManager`에서 박스를 만들 때 메시·투명 재질을 받던 initializer를 `ModelEntity()`로 교체했다. 이 엔티티는 Collision·Physics만 갖고 렌더링할 ModelComponent는 갖지 않는다.

- `end`의 모델·하이라이트·클릭·완주 처리는 유지했다.
- 기존 전체 범위, 박스 위치, CollisionComponent와 정적 PhysicsBodyComponent 설정은 유지했다.
- 윷 생성·투사·질량·마찰·반발·면 판정 코드는 변경하지 않았다.
- 충돌 범위를 판 본체로 줄이지 않았다. 오른쪽의 실제 물리 동작 변경은 이번 범위에서 제외했다.

## 검증·이력

- **2026-11-11:** 원본·현재 생성 코드 대조, 실제 USDZ의 본체·전체 범위와 `end` 투명 재질 확인. 분석 스크립트: `/tmp/yut-board-extra-inspect.swift`, 결과: `/tmp/yut-board-extra-inspect.log`.
- **2026-11-11 / 골인 지점 확인:** 원본·현재 경로, 골인 하이라이트·선택·완주 처리를 추적했다. 분석용 모델에서 `end`만 제외해 폭이 60.1cm로 복귀함을 확인했다. 스크립트·결과: `/tmp/yut-board-goal-bounds.swift`, `/tmp/yut-board-goal-bounds.log`. 앱·리소스 변경 없음.
- **2026-11-11 / 수정:** 충돌용 메시·투명 재질 생성만 제거했다. 앱·테스트·리소스의 작업 전 SHA-256 대조에서 변경 파일은 `BoardManager.swift` 하나다. 범위 기록: `/tmp/yut-board-visual-scope.json`.
- **빌드·회귀:** iOS·iOS Simulator 빌드 성공, 기존 단위·통합 테스트 **62개 / 12개 suite 통과**. AR 준비·복구, 말 선택·이동, 게임 규칙 회귀 포함. 새 Swift 컴파일 오류·경고 없음. AppIntents 미사용 메타데이터 경고는 기존과 동일하다. 결과: `/tmp/yut-board-visual-tests.xcresult`, 빌드 로그: `/tmp/yut-board-visual-device.log`, `/tmp/yut-board-visual-simulator.log`.
- **UI·화면:** 배치→모으기→수동 던지기 기존 UI 테스트 **1개 통과**. 이전 배치 확정 캡처의 긴 사각형이 수정 후 사라졌고, 오른쪽 작은 골인 지점은 남았다. 시뮬레이터 장면 비교이며 실제 카메라·조명 실험과 구분한다. 결과: `/tmp/yut-board-visual-ui.xcresult`. 수정 후 캡처: `/tmp/yut-board-visual-ui-attachments/3F149DDB-59F0-4FBD-B98D-AF425CA5D1B1.png`.
- 테스트는 기존과 같이 iOS 18.3 시뮬레이터용 임시 프로젝트로 실행했다. 저장소 배포 대상 iOS 18.5는 유지했다.
- **검증 대기:** iPhone 15 Pro에서 돌출 영역 제거, 골인 강조·선택·완주, 윷 충돌 유지 확인.
- **2026-11-12 / 발열 작업 후속:** 투명 골인 칸도 대기 중 ModelComponent를 숨기고 선택 후보일 때만 원본 메시로 강조한다. 엔티티·충돌·좌표는 유지하며 앵커 복제와 실제 골인 탭→승리 회귀가 통과했다. 상세 검증은 [AR 부하 QA](ar-overheating.md)에 기록했다.
