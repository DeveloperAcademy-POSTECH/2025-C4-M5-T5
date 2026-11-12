# Yut 디렉토리 구조·컨벤션 검토

**상태: 디렉토리 적용 완료 · 책임 분리 후속 · 우선순위: 중간 · 갱신: 2026-11-12**

Yut 소스의 폴더·사용 관계를 검토해 디렉토리를 재배치했다. **독립 화면 7개의 대응을 유지하며 기능별 화면·SubViews와 시스템별 매니저 구조를 적용했다.** 실행 성능 비교나 모델·AR 타입의 내부 책임 분리까지 완료한 작업은 아니다.

## 디렉토리 적용 결과 — 2026-11-12

| 영역 | 반영 내용 |
| --- | --- |
| 화면·ViewModel | 로비 5개 화면은 `Lobby`, 플레이·승리는 `Game` 바로 아래 배치. ViewModel도 같은 기능 경로로 대응 |
| 하위 뷰 | `SubViews/{NameInput,RoomList,WaitingRoom}`와 `SubViews/{Play,Winner}`로 구분. NameInput의 폼, Play의 AR 연결·던지기 버튼만 해당 영역의 Components에 배치 |
| 공용 UI | 기존 DesignSystem 유지. 기능 전용 하위 뷰를 공용 UI로 승격하지 않음 |
| 시스템·모델 | `Utility/Managers/{AR,Game,Multipeer,Asset,Audio,Haptic}`, `Models/{AR,Game,Lobby}`, `Utility/Extensions/{AR,Game}`로 정리. 프로토콜은 담당 경계의 Protocols에 배치 |
| 이름·내비게이션 | `Router.swift` → `Destination/Route.swift`, `CoreHaptics.swift` → `HapticsService.swift`. MPC 분리 파일은 `MPCManager+Host/Guest/Session.swift`로 통일 |
| 미사용 파일 | 활성 참조 없는 BoardModel·ARAction·Room과 주석 예제만 남은 YutTests.swift 제거. 현재 GameBoard·RoomModel과 실행 중인 회귀 테스트는 유지 |
| 테스트·참조 | 단위 테스트를 Models·ViewModels·Utility·DesignSystem·Support로, UI 테스트를 Flows·Launch로 분류. 문서 링크·폴더 규칙도 갱신 |

파일 **82개 이동·4개 제거**. 이동 전후 해시로 남겨 둔 모든 Swift 파일의 내용 일치를 확인했다. 윷 투사·물리·면 판정·모으기·통신·발열 제어 구현과 리소스는 이번 작업에서 변경하지 않았다. Xcode의 파일 시스템 동기화 그룹이 새 경로를 자동 반영하므로 프로젝트 파일의 수동 소스 목록 수정은 필요하지 않았다.

| 검증 | 결과 |
| --- | --- |
| 빌드·진단 | iOS / Simulator 모두 성공. 새 Swift 오류·경고 없음. 기존 AppIntents 메타데이터 경고만 확인 |
| 회귀 | 단위·통합 **85개 / 15개 suite 통과**, 홈·로비 재생성 / 방 참여 / AR 배치→모으기→던지기 UI **3개 통과** |
| 구조·보존 | 독립 화면 7개 View–ViewModel 경로 일치, 빈 디렉토리 없음. 유지한 Swift·리소스·프로젝트 설정 내용 보존 |
| 문서 | 이동한 소스·테스트 링크와 폴더 규칙 갱신, 저장소 문서의 로컬 링크 대상 확인 |

테스트는 SDK 27.2 / iOS 18.3.1 시뮬레이터에서 실행했다. 테스트용 임시 프로젝트만 배포 대상을 18.3으로 낮췄으며 저장소의 18.5 설정은 유지했다. 실기기 성능이나 발열 감소는 이번 작업에서 측정하지 않았다. 기존 기기 검증 대기 항목의 상태도 유지한다.

검증 자료: `/tmp/yut-directory-scope.json`, `/tmp/yut-directory-tests.xcresult`, `/tmp/yut-directory-device.log`, `/tmp/yut-directory-simulator.log`. 구조 규칙은 [아키텍처](../../guides/architecture.md#5-기능별-하위-폴더-규칙), 화면 목록은 [MVVM 대응](screen-viewmodel-mapping.md)에서 관리한다.

## 변경 전 구조와 후속 제안

아래 표는 재배치 전 정적 검토 결과다. 파일 위치·이름은 위 내용대로 반영했으며, 타입 내부 책임·작성 형식은 후속이다.

| 항목 | 확인한 사실 | Yut 수정 제안 |
| --- | --- | --- |
| 기능·시스템 폴더 | 재배치 전 Yut은 Utility/ARGamePlay/Managers·Services, Utility/Lobby/Manager, Utility 루트가 섞여 있다 | 역할별 배치 기준 통일. 특히 AR 말 모델을 갱신하는 GameManager가 Lobby/Manager에 있는 위치와 AssetCacheManager의 루트 배치를 정리 |
| 큰 타입의 책임 | ARCoordinator 692줄에 AR 세션 수명·배치·공유 공간·협업 데이터·원격 자세 송수신/렌더·열 상태가 함께 있다 | 원격 투사 표시와 공유 공간/세션 수명의 실제 책임 경계를 나눔. 단순히 extension 파일만 늘리는 것보다 객체의 담당 범위를 줄이는 것이 목적 |
| 모델과 외부 시스템 | PlayerModel에 MCPeerID·Codable·화면 에셋 이름·PieceModel이 섞여 있다. PieceModel에는 RealityKit Entity와 동기 로딩 initializer가 있다 | GamePlayer·GamePiece의 순수 규칙 모델, 로비 전달 데이터, AR 시각 모델을 구분. 일반 모델 생성·디코딩이 리소스 I/O를 유발하지 않도록 정리 |
| 상태의 기준 | GameState.phase/ARState.placementPhase와 함께 옛 ARState.gamePhase를 updateLegacyPhase로 복제한다. GestureHandler의 배치 제스처 3곳이 옛 값을 읽는다 | 게임 진행과 AR 배치 상태의 분리는 유지. 옛 gamePhase 복제를 제거하고 제스처는 placementPhase를 직접 기준으로 삼도록 통일 |
| 하위 뷰 입력 | Yut PlayControls는 GameState 전체를 받는다 | 실제로 필요한 단계·이름·순서·새 말 가능 여부 등 표시 값과 액션만 전달 |
| 디자인 시스템 | Yut은 ThemeColors·Typography·ActionButton은 있으나 toolbar·여백·일부 글꼴 설정은 화면에 반복된다 | 기존 Yut 컴포넌트 안에서 반복되는 화면 여백·내비게이션·텍스트 역할을 보완. 화면 하나에만 쓰는 큰 로고/결과 글꼴까지 일괄 공용화하지 않음 |
| 파일명·형식·잔재 | CoreHaptics.swift의 타입은 HapticsService, Router.swift의 타입은 Route다. 한 줄에 여러 문장을 넣는 코드·오래된 파일 헤더·주석 처리한 구현도 남아 있다 | 파일/타입 이름 대응, 선언 순서·들여쓰기·여러 줄 액션 형식 통일. 구현을 되풀이하는 주석은 정리하고 좌표·물리 제약·취소 조건의 이유는 보존 |

PlayerModel의 현재 로비 생성 경로는 `preparePieces: false`를 전달한다. 따라서 **현재 모든 통신 수신에서 동기 모델 로딩이 실행된다고 판단하지 않는다.** 기본 initializer와 Codable 복원 등 남은 경로의 책임을 정리하자는 제안이다. `fatalError` 분기도 존재하지만 실제 크래시를 재현한 결과는 아니다.

참조 Yut 코드: [ARCoordinator](../../../Yut/Yut/Sources/Utility/Managers/AR/ARCoordinator.swift), [GameManager](../../../Yut/Yut/Sources/Utility/Managers/AR/GameManager.swift), [PlayerModel](../../../Yut/Yut/Sources/Models/Lobby/PlayerModel.swift), [PieceModel](../../../Yut/Yut/Sources/Models/AR/PieceModel.swift), [PlayControls](../../../Yut/Yut/Sources/Views/Game/SubViews/Play/PlayControls.swift), [PlayViewModel](../../../Yut/Yut/Sources/ViewModels/Game/PlayViewModel.swift), [타이포그래피](../../../Yut/Yut/Sources/DesignSystem/Font/Typography.swift).

## 미사용 후보와 확인 범위

재배치 전 Sources·테스트 참조 검색에서 `BoardModel`, `ARAction`, `Room`, `YutManager.preloadYutModels()`의 활성 호출을 찾지 못했다. 앞의 독립 타입 3개와 주석 예제 파일은 빌드 타깃·호출 경로 재확인 후 제거했다. `preloadYutModels()`, 쓰기만 하는 `isAnimationDone`, BoardManager의 주석 처리된 이전 배치 함수·꺼진 Preview는 내부 코드 정리 범위로 남겼다.

## 하위 뷰 구조 재대조·설명 정정

하위 뷰는 크기나 전체 화면 여부로 분류하지 않는다. 같은 기능의 독립 화면은 기능 폴더 바로 아래에 두고, 하위 구성 뷰는 `SubViews/<영역>`에 둔다. 구성 요소를 별도로 묶을 실제 관계가 있을 때만 `Components`를 추가한다. 모든 기능의 폴더 깊이를 같게 맞추지 않는다.

구체적인 경로와 예시는 [기능별 하위 폴더 규칙](../../guides/architecture.md#5-기능별-하위-폴더-규칙)을 따른다.

변경 전 Yut은 `Lobby/WaitingRoom/WaitingRoomView.swift + Components`, `ARGamePlay/Play/PlayView.swift + Components`처럼 화면별 폴더를 추가하고 하위 뷰를 한 단계에 모았다. 최상위 분리와 화면–ViewModel 대응은 유사했지만 기능 내부 구조는 달랐다. 이번에는 기능별 화면 배치, SubViews의 영역 구분, 필요한 Components의 위치를 함께 적용했다.

## 유지할 부분과 적용 순서

- Resources/Sources 분리, Application 내 내비게이션, 화면–ViewModel 대응, 기능별 하위 뷰, 기존 디자인 시스템은 유지한다.
- initializer 주입·작은 프로토콜·게임 회귀 검증을 유지한다. 화면과 ViewModel에서 전역 싱글턴에 새로 의존하지 않는다.
- 권장 순서: **파일 위치/이름·형식 → 미사용 후보/옛 상태 → 모델 경계 → AR 조정자 책임 분리 → 남은 공통 UI 정리**. 단계별로 동작을 보존하고 검증한다.
- 원본 투사의 질량·마찰·반발·투사/판정 시점과 감각은 이번 구조 정리 제안의 변경 대상이 아니다.

## 작업 이력·검증

- **2026-11-12:** 당시 Yut Swift 파일 97개의 위치를 목록화하고 대표 구현·참조 경로를 검토했다. 표의 구조적 위험과 제안은 정적 검토 결과이다.
- **2026-11-12 / 설명 정정:** 하위 계층과 사용 관계를 다시 검토했다. 기능 내부 구조 설명과 뷰 크기만으로 SubViews/Components를 구분한 설명을 정정했다.
- **비교 단계:** 앱 소스는 변경하지 않았으며 문서 링크만 확인했다. 이 단계에서는 빌드·테스트를 실행하지 않았다.
- **2026-11-12 / 적용:** 승인한 디렉토리·파일명·미사용 독립 파일·테스트 분류를 반영했다. 빌드 2종·회귀 85개·UI 3개 통과, 이동 전후 구현·리소스 보존과 문서 경로를 확인했다.
- **다음 작업:** 별도 범위로 옛 상태 중복, 모델 경계, ARCoordinator 책임, 하위 뷰 최소 입력·남은 공용 UI와 작성 형식을 검토한다. 이번 폴더 작업으로 해당 개선까지 완료했다고 판단하지 않는다.

- **2026-11-12 / 문서 기준 통일:** 외부 프로젝트의 비교 문구·예시·경로를 제거하고 Yut의 구조·컴포넌트 기준으로 정리했다. 문서 파일명과 연결된 링크를 갱신했다. 문서만 변경해 빌드는 생략했다.

- **2026-11-12 / 개발 문서 경로 정리:** 개발 기준 3개를 `docs/guides`에 모으고 문서 안내의 기능·출시 섹션을 제거했다. AGENTS.md·문서·소스 참조 링크를 갱신했다. 문서만 변경해 빌드는 생략했다.

- **2026-11-12 / 문서 현행화:** 현재 Yut의 구현·보완 내역과 검증 근거를 유지하면서 삭제된 프로젝트의 비교 설명·소스 경로·보관 문서 링크를 제거했다. 기능 보완표를 Yut 기준으로 정리하고 문서 내부 경로·앵커를 점검했다. 문서만 변경해 빌드는 생략했다.
