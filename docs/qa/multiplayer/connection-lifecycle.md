# 연결 종료·홈 복귀

**상태: 검증 대기 · 우선순위: 높음 · 갱신: 2026-11-12**

참가자 이탈 시 홈으로 돌아가고, 정상 완주는 승리 화면으로 이동한다. 종료 뒤 이전 오류나 작업이 화면을 다시 열지 않도록 보완했다. 실기기의 동일 증상 재현·응답성은 미확인이다.

## 게임 종료 후 로딩 화면 재진입·공통 스캔 안내 — 2026-11-12

**상태: 수정 반영 · 실기기 검증 대기.** 참가자 이탈로 게임이 종료되면 홈에 머물러야 하며, 종료된 게임의 카메라 준비 화면이 다시 열리지 않도록 수정했다.

| 항목 | 확인·변경 |
| --- | --- |
| 종료 후 화면 재진입 | WaitingRoomViewModel은 RunLoop로 전달된 과거 시작 알림만 보고 화면을 열었다. 실제 MPCManager·게임 컨트롤러·화면 ViewModel·내비게이션을 조합한 테스트에서 시작 직후 종료하면 홈 복귀 뒤 플레이 경로가 다시 생기는 것을 재현했다. 사용자 기기에서 발생한 정확한 이벤트 순서를 확인한 결과는 아니다 |
| 홈 복귀 | 지연된 시작 알림을 현재 hasStartedGame과 대조해 차단한다. 시작했던 게임이 중단되면 별도 방 종료 메시지가 없어도 홈으로 이동한다. 게임 상태가 없을 때 PlayView는 AR·로딩 화면을 만들지 않고, resume도 AR을 재개하지 않고 홈으로 보낸다 |
| 공통 스캔 | 기존 ProgressBar와 각 기기의 recognizedArea·minRequiredArea를 재사용한다. 두 역할 모두 “주변 공간을 스캔해주세요”로 통일하며 참가자도 로컬 게이지를 표시한다. 참가자가 기준을 채우면 방장 배치 대기 안내로 전환하고, 실제 배치 조작은 계속 방장만 표시한다 |
| 보존 | AR 인식·충돌 처리·윷 물리·판정·게임 규칙·전송 메시지 형식은 변경하지 않았다. 통신 불안정과 재참여 실패의 직접 원인을 해결했다고 판단하지 않는다 |
| 검증 | 수정 전 종료 후 화면 재진입·AR 재개 및 참가자 스캔 안내 누락을 테스트에서 확인했다. 수정 후 빌드·회귀·로비/AR UI·라이트/다크 캡처 확인 중이다 |

**남은 확인:** 실제 두 기기에서 배치 준비 중·게임 중 한 기기 이탈 후 남은 기기의 홈 복귀, 각 기기의 공간 스캔 게이지와 배치 완료 후 전환을 확인한다.

검증 자료: `/tmp/yut-game-exit-scan-before.xcresult`(수정 전 재현 실패), `/tmp/yut-game-exit-scan-tests.xcresult`, `/tmp/yut-game-exit-scan-device.log`, `/tmp/yut-game-exit-scan-simulator.log`, `/tmp/yut-game-exit-scan-gallery`. SDK 27.2 / iOS 18.3.1 시뮬레이터에서 테스트했으며 저장소의 배포 설정은 유지했다.

관련 코드: [대기실 종료·시작 처리](../../../Yut/Yut/Sources/ViewModels/Lobby/WaitingRoomViewModel.swift), [플레이 상태·스캔 표시](../../../Yut/Yut/Sources/ViewModels/Game/PlayViewModel.swift), [플레이 화면](../../../Yut/Yut/Sources/Views/Game/PlayView.swift), [배치·스캔 UI](../../../Yut/Yut/Sources/Views/Game/SubViews/Play/PlacementControls.swift), [회귀 테스트](../../../Yut/YutTests/ViewModels/Game/PlayViewModelTests.swift).

## 갑작스러운 연결 종료 후 게임 오류창·흰 화면 — 2026-11-12

**상태: 수정 완료 · 실기기 검증 대기.** 연결 종료 후 다시 시도/방 나가기 창이 잠시 나타나고 흰 화면에 남는다는 제보에 대한 수정이다. 실제 기기의 메인 스레드 정지나 동일 화면 순서까지 측정한 결과는 아니다.

| 코드에서 확인한 원인 후보 | 수정 |
| --- | --- |
| PlayView의 시스템 alert가 홈 이동 중 제거되며 RootView의 다른 alert와 수명이 겹침 | 안내를 RootView의 공통 AppNoticeView로 통합. 연결 종료 안내를 우선 표시하고 확인 시 모델·연결 안내를 함께 해제 |
| 종료된 match에도 retry가 AR 재시작·동기화 요청을 실행 | PlayViewModel·GameSessionController 모두 활성 게임 확인. 종료 후 pause·늦은 오류도 무시 |
| 이전 방의 예약된 오류가 새 로비에 남거나 홈으로 이동 | 현재 연결 상태와 일치하는 알림만 적용. nil 상태도 반영하고 확인 시 원본 안내 상태를 초기화 |
| AR 준비·말판 공유의 늦은 실패가 종료 뒤 오류를 재생성 | 오류·완료 경로에도 generation 확인. 이전 말판 확정 작업이 새 게임을 재개하지 않도록 게임 ID 확인 |
| match가 nil이면 남은 PlayView 경로의 내용이 비어 있음 | 종료 문구·홈으로 버튼 제공. 기본 종료 흐름은 홈 복귀 유지 |

**보존:** 정상 완주 → WinnerView → 재경기 경로, 기존 윷 물리·모으기·판정 시점은 변경하지 않았다. 재참여 프로토콜이나 연결 방식은 이번 수정 대상이 아니다.

**회귀 근거:** 수정 전 소스 복사본에 새 테스트 3개를 적용한 격리 실행에서 종료 후 재시도·늦은 오류·이전 로비 안내 문제가 7개 assertion으로 재현됐다. 테스트 29개 중 해당 3개가 실패했다. 이는 상태 전이 재현이며 실제 기기의 흰 화면 재현과 구분한다. `/tmp/yut-settings-exit-baseline-fixedresources.xcresult`.

**수정 후 검증:** 전체 단위·통합 111개 / 17개 suite 통과. 위 3개 회귀와 활성 오류 재시도·해제, 정상 승리·재경기 포함. 로비 생성·추가·퇴장·재생성, 방 목록 UI 통과. AR 배치→모으기→수동 던지기도 재실행 통과했다. 공통 안내·종료 대체 화면은 라이트/다크 렌더 확인. iOS·Simulator 빌드 성공, 변경 Swift 코드의 새 오류·경고 없음.

결과는 `/tmp/yut-settings-exit-final.xcresult`와 `/tmp/yut-settings-exit-tests.xcresult`에 나뉘어 있다. 첫 통합 실행의 AR UI는 RealityKit Metal 타입 반영 내부 EXC_BAD_ACCESS로 종료됐으며 같은 코드 재실행은 통과했다. 실제 연결 종료 중 화면 순서·응답성 확인은 사용자 요청으로 수행하지 않아 **검증 대기**로 남긴다.

관련 코드: [오류·종료·재시도](../../../Yut/Yut/Sources/ViewModels/Game/PlayViewModel.swift), [앱 공통 안내](../../../Yut/Yut/Sources/Application/RootView.swift), [종료 화면](../../../Yut/Yut/Sources/Views/Game/SubViews/Play/GameEndedView.swift), [AR 비동기 정리](../../../Yut/Yut/Sources/Utility/Managers/AR/ARCoordinator.swift).

