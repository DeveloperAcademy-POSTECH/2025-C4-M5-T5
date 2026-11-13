# 플레이어 색상 안내·방 목록 정리

**상태: 검증 대기 · 우선순위: 중간 · 갱신: 2026-11-13**

AR 안내·스캔·게이지·결과에 말 색을 연결하고 방 목록 배경과 바깥 여백을 맞췄다. 새로운 색상 에셋은 추가하지 않고 기존 디자인 시스템을 확장했다. 실기기 카메라 환경에서의 스캔 색·가독성은 확인 대기다.

## 적용 내용

| 대상 | 적용 기준 |
| --- | --- |
| 공통 색상 | 기존 piece_yellow/jade/blue/red 에셋과 고정 갈색/흰색 전경을 ThemeColors의 SurfaceColors 쌍으로 재사용. 파랑은 흰 글자, 나머지는 기존 갈색 글자 |
| 스캔 영역·배치 안내 | 해당 기기에 등록된 플레이어 색. 한 기기에 여러 명이면 명단의 첫 순서 플레이어를 기준으로 사용. 평면 투명도 0.6·배치 후 숨김·충돌 유지 |
| 스캔 게이지 | 채워지는 부분은 같은 말 색과 대비 글자색. 빈 부분은 기존 공통 표면·글자색. 채움 경계에 맞춰 글자도 마스킹해 두 배경에서 읽히도록 구성 |
| 게임 안내 | 현재 턴 플레이어의 색. 기존 안내가 표시되는 단계·문구·크기 유지 |
| 결과·추가 던지기 안내 | 던진 플레이어 색을 ViewModel이 보관. 차례 변경 후에도 이전 결과 색을 유지하고 새 투사에서 갱신 |
| 빈 방 목록 | ScrollView의 전체 크기를 명시해 방이 없어도 화면 전체에 canvas 적용 |
| 방 카드 | 바깥 좌우 20pt로 기존 로비 콘텐츠와 통일. 카드 내부 좌우 24pt는 유지 |

SurfaceStyle·InstructionView·ProgressBar를 확장했다. 공용 UI는 색상 값만 받고 게임 플레이어를 판단하지 않는다. PieceType의 화면용 매핑은 Winner 폴더에서 [공용 확장](../../../Yut/Yut/Sources/Utility/Extensions/Game/PieceType+Appearance.swift)으로 옮겼다.

근거: [ThemeColors](../../../Yut/Yut/Sources/DesignSystem/Color/ThemeColors.swift), [ProgressBar](../../../Yut/Yut/Sources/DesignSystem/Component/Feedback/ProgressBar.swift), [PlayViewModel](../../../Yut/Yut/Sources/ViewModels/Game/Play/PlayViewModel.swift), [평면 표시](../../../Yut/Yut/Sources/Utility/Managers/AR/PlaneManager.swift), [RoomListView](../../../Yut/Yut/Sources/Views/Lobby/RoomList/RoomListView.swift).

## 검증

- **회귀 85개 / 15개 suite 통과.** 플레이어 4종의 로컬 스캔 색·턴 색 분리, 차례 변경 후 결과 색 유지 포함. 공통 전경/배경 대비 테스트는 라이트·다크 각각 4.5:1 이상 통과.
- **iOS·iOS Simulator 빌드 성공.** 새 Swift 컴파일 오류·경고 없음. 기존 AppIntents 미사용 메타데이터 경고는 유지된다.
- **라이트·다크 캡처 12장:** 플레이어별 안내·부분/전체 게이지·결과 8장과 빈/채워진 방 목록 4장. ScrollView는 실제 UIHostingController 윈도에서 캡처했다. 게이지 겹침을 발견해 레이어 순서를 수정한 뒤 재검증했다.
- **실제 앱 UI 4개 통과:** 방 참여·뒤로가기와 AR 배치→모으기→수동 던지기를 라이트·다크 각각 실행했다. 빈 방 목록 전체 배경과 AR 상단의 노란 턴 배경·갈색 글자도 캡처로 확인했다.
- 단위·UI 실행에는 기존 iOS 18.3.1 임시 검증 프로젝트를 사용했다. 저장소 배포 대상 iOS 18.5는 유지했다.

근거: `/tmp/yut-player-network-verified-unit.xcresult`, `/tmp/yut-player-network-verified-device.log`, `/tmp/yut-player-network-verified-simulator.log`, `/tmp/yut-player-network-final-gallery`. UI: `/tmp/yut-player-network-light-ui.xcresult`, `/tmp/yut-player-network-dark-ui.xcresult`. 보존 범위: `/tmp/yut-player-network-scope.json`.

## 남은 확인·작업 이력

- **2026-11-13:** 한 기기 플레이 슬롯의 이름·말 색상을 번호에 고정했다. 현황판 말 아이콘을 20→40pt로 확대하고 공용 `PieceIcon`으로 투명 여백을 보정했다. 현황판 높이는 기본 144pt이며 기존 150pt 이하 검사·AR UI가 통과했다. [플레이 방식 분리 검증](../game/local-play-and-multiplayer.md).
- **2026-11-12:** 기존 팔레트·표면 스타일 재사용, 스캔/턴/결과 색상 연결, 빈 목록 배경·바깥 여백 수정. 빌드 2종·회귀 85개·UI 4개·갤러리 12장 검증 완료. 원본 투사/판정·리소스 136개 내용 일치 확인.
- **실기기 검증 대기:** 실제 방 스캔의 투명도와 네 말 색 가독성, 참가자별 스캔 색, 턴 전환·결과 표시. 기존 15 Pro 발열·모으기 지연 실측도 별도로 유지한다.
