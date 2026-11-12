# AR 환경 부하·발열

**현재 대상: Yut · 상태: 검증 대기 · 우선순위: 높음 · 갱신: 2026-11-12**

원본 윷의 자연스러운 투사·사물 충돌을 유지하면서 대기 중 반복 계산과 불필요한 렌더링을 줄였다. **아래 수치는 코드·리소스·자동 테스트 결과이며, iPhone 15 Pro의 온도·전력·CPU·GPU 개선율은 미측정이다.**

## 현재 Yut에서 확인하고 수정한 내용

| 항목 | 확인한 문제 | 적용한 변경 |
| --- | --- | --- |
| 평면 갱신 | 매 갱신마다 메시 생성·별도 비동기 충돌면 생성. 동일 형상 재사용·중단 처리가 없음 | 평면별 최신 경계 병합, 동일 경계 캐시, 직렬 생성. 기존 충돌면을 교체 직전까지 유지. 새 평면도 첫 등록부터 충돌면 생성 |
| 갱신 간격·수명 | 중단·삭제 후 늦은 생성 결과가 적용될 수 있음 | 정상 250ms, fair 500ms, serious/critical 1초 배치 간격. 중단·초기화·평면 삭제 결과 무효화. 취소를 늦게 처리하는 생성이 끝난 뒤 다음 작업 시작 |
| 윷판 렌더링 | 본체 20개 + 투명 선택 칸 30개 × 8,064개 = **241,940개 삼각형** | 투명 칸의 ModelComponent만 숨기고 강조할 때 원본 메시 복원. 칸의 좌표·충돌·자식 말·골인 이름 유지. 대기 중 말판 자체는 본체 **20개**, 강조 칸마다 8,064개 추가. 말 모델은 별도 |
| 모델 중복 준비 | 미리 읽은 평탄화 말판은 사용하지 않고 배치 때 USDZ를 다시 동기 로드 | 칸 계층을 보존한 Entity 템플릿을 한 번 준비해 복제. 게임 초기화 시 모델·이미지 캐시 해제 |
| 모으기 시작·메모리 | 상태마다 중복 render, body에서 파일 읽기, 수명이 관리되지 않는 Timer | 상태 1회 렌더, 연출 단계만 바뀌면 말 배열 재구성 생략. 압축 데이터 사전 준비, 시작 3장·마지막 1장만 상시 디코딩. 나머지는 비동기 준비 후 표시하고 화면 종료 시 작업 취소 |
| 열 상태 | 열 상태별 렌더링 조절 없음 | serious/critical에서 모션 블러·심도·카메라 그레인 후처리만 줄이고 정상화 시 원래 옵션 복구. 열 상태 알림 작업도 화면 중단 시 취소 |

삼각형 감소는 **장면에 등록하는 메시 수치**다. GPU 처리 시간이나 발열이 같은 비율로 감소한다는 의미가 아니다. PNG 30장 전체의 RGBA8 규모는 약 191MiB, 명시적으로 준비해 유지하는 4장은 약 25.5MiB이며 압축 데이터는 약 9.9MiB다. UIKit·GPU 내부 캐시를 포함한 실제 최대 메모리는 실측해야 한다.

## 보존 범위와 공간 인식 판단

- `YutManager.swift`·`YutModel.swift`와 리소스 **136개 모두 작업 전 SHA-256 일치**를 확인했다. 윷 질량·마찰·반발·투사 위치/속도/회전·힘 적용 순서·정지/면 판정 조건은 유지했다.
- 충돌용 박스의 기존 크기·위치·정적 물리와 평면의 실제 삼각형 경계는 유지한다. 칸은 엔티티를 끄거나 삭제하지 않고 그리기용 컴포넌트만 제거한다. 고정 앵커 복제 후에도 골인 강조·선택을 검증한다.
- **수평·수직 평면 감지, LiDAR 메시, 공간 물리는 유지한다.** 평면 감지는 LiDAR 메시 평탄화에도 쓰인다. 배치 후 일괄 해제하면 새 탁자·벽·바닥 충돌이나 경계 품질이 달라질 수 있어, 먼저 갱신 낭비를 제거했다.
- 카메라 영상 해상도·프레임률·물리 시간 간격·정상 열 상태의 그림자/후처리·텍스처 해상도는 낮추지 않았다. 추가 품질 조절은 실측 후 비교한다. 단독 협업 해제·화면 중단 시 세션/센서 정리는 기존 반영을 유지했다.

근거: [평면 큐](../../../Yut/Yut/Sources/Utility/Managers/AR/PlaneCollisionUpdateQueue.swift), [평면 적용](../../../Yut/Yut/Sources/Utility/Managers/AR/PlaneManager.swift), [선택 칸 렌더](../../../Yut/Yut/Sources/Utility/Managers/AR/PieceManager.swift), [AR 수명·열 상태](../../../Yut/Yut/Sources/Utility/Managers/AR/ARCoordinator.swift), [자원 준비](../../../Yut/Yut/Sources/Utility/Managers/Asset/AssetCacheManager.swift), [모으기 QA](../game/yut-gathering-hitch.md).

Apple 기준: [CPU·충돌 최적화](https://developer.apple.com/documentation/realitykit/reducing-cpu-utilization-in-your-realitykit-app), [GPU 최적화](https://developer.apple.com/documentation/realitykit/reducing-gpu-utilization-in-your-realitykit-app), [평면 감지와 LiDAR 메시 평탄화](https://developer.apple.com/documentation/arkit/arworldtrackingconfiguration/scenereconstruction), [Entity 계층 로드](https://developer.apple.com/documentation/realitykit/loading-entities-from-a-file), [이미지 비동기 표시 준비](https://developer.apple.com/documentation/uikit/uiimage/preparefordisplay%28completionhandler%3A%29).

## 검증과 남은 실측

- 평면 큐 **7개**: 동일 경계 반복 생성 1회, 생성 중 99회 변경은 처음·최신만 처리, 중단 후 재개까지 동시 생성 1개, 삭제·실패·초기화 검증. 중단 후 중첩 생성은 수정 전 재현 테스트 실패를 확인했다.
- 자동 회귀 **74개 / 14개 suite 통과**. 칸 렌더 토글·충돌 유지·앵커 복제, 같은 스냅샷에서 권한 변경, 실제 골인 탭→승리, 이미지 준비·복귀 재사용·초기화 해제, 모으기 1회 렌더/효과음 검증 포함.
- **iOS·iOS Simulator 빌드 2종, 배치→모으기→수동 던지기 AR UI 1개 통과.** 말판·마지막 대기 이미지 캡처도 확인했다. 새 Swift 컴파일 오류·경고 없음. 기존 AppIntents 미사용 메타데이터 경고는 유지된다. 자동 실행은 기존 iOS 18.3.1 임시 검증 프로젝트를 사용하며 저장소 배포 대상 iOS 18.5는 유지한다.
- **실기기 검증 대기:** 연결된 iPhone이 오프라인이어서 15 Pro의 CPU·GPU·전력·열 상태, 실제 사물 충돌 및 두 기기 재정렬은 측정하지 못했다.

15 Pro에서 같은 Release 빌드·밝기·충전/주변 조건으로 **배치 전 60초 → 배치 후 대기 3분 → 모으기/던지기 10회 → 백그라운드 복귀**를 비교한다. Instruments의 Time Profiler·Metal/프레임·메모리·전력과 `Yut / ARPerformance` signpost를 함께 기록한다. `PlaneCollision`은 생성 구간, `PlacementPhase`·`ThermalState`는 단계/열 변화, `GatherInput`→`GatherViewReady`는 입력부터 뷰 작업 시작까지다. **GatherViewReady는 실제 GPU 화면 표시 완료 시각이 아니다.** 첫 화면 표시 지연은 화면 프레임 기록과 함께 판단한다.

| 실측 항목 | 개선 전 | 개선 후 |
| --- | --- | --- |
| 배치 후 대기 CPU·GPU·프레임·전력·열 상태 | 미측정 | 미측정 |
| 첫/반복/복귀 모으기 지연·최대 메모리 | 미측정 | 미측정 |
| 새 표면 반영·원본 반발·골인·공유 공간 | 비교 대기 | 비교 대기 |

## 작업 이력

- **2026-11-12:** 현재 Yut 부하 재분석, 평면 큐·수명·선택 칸 렌더·모으기/말 상태 중복 처리·자원 캐시·열 상태 후처리 적용. 빌드 2종·회귀 74개·AR UI 1개 통과. 실기기 발열 감소량은 검증 대기.

근거 파일: `/tmp/yut-thermal-validation-tests.xcresult`, `/tmp/yut-thermal-device.log`, `/tmp/yut-thermal-simulator.log`. 재현 실패 기록: `/tmp/yut-thermal-queue-red.xcresult`. 리소스 조사: `/tmp/yut-thermal-board-meshes.log`, `/tmp/yut-thermal-board-materials.log`. 보존 대조: `/tmp/yut-thermal-scope.json`.
