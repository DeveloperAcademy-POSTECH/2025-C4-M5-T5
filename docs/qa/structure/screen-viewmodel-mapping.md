# 독립 화면별 View–ViewModel 대응

**상태: 완료 · 우선순위: 중간 · 갱신: 2026-11-12**

독립 화면은 View–ViewModel 1:1과 파일·기능 폴더 대응을 지키도록 정리했다. 화면 섹션·단순 모달·DesignSystem에는 별도 ViewModel을 추가하지 않았다. [아키텍처 기준](../../guides/architecture.md#독립-화면의-viewviewmodel-대응)을 따른다.

## 화면 대응 목록

`Yut/Yut/Sources/Views`와 `ViewModels` 아래에서 같은 기능 경로를 사용한다.

| 기능 경로 | View 파일 | ViewModel 파일 |
| --- | --- | --- |
| `Lobby` | `HomeView.swift` | `HomeViewModel.swift` |
| `Lobby` | `HostNameInputView.swift` | `HostNameInputViewModel.swift` |
| `Lobby` | `GuestNameInputView.swift` | `GuestNameInputViewModel.swift` |
| `Lobby` | `RoomListView.swift` | `RoomListViewModel.swift` |
| `Lobby` | `WaitingRoomView.swift` | `WaitingRoomViewModel.swift` |
| `Game` | `WinnerView.swift` | `WinnerViewModel.swift` |
| `Game` | `PlayView.swift` | `PlayViewModel.swift` |
| `Settings` | `SettingsView.swift` | `SettingsViewModel.swift` |
| `Settings` | `LegalDocumentView.swift` | `LegalDocumentViewModel.swift` |
| `Settings` | `SupportView.swift` | `SupportViewModel.swift` |
| `Settings` | `CreatorsView.swift` | `CreatorsViewModel.swift` |

## 변경 내용

- Home의 직접 route 호출을 제거했다. AppDependencies가 HomeViewModel을 생성·주입하며, 방 만들기·참여하기는 작은 HomeNavigating 프로토콜을 거쳐 같은 닉네임 화면으로 이동한다.
- 한 파일에 묶였던 Host/Guest 닉네임 ViewModel을 각각 분리했다. Winner·RoomList·WaitingRoom ViewModel은 View와 같은 기능 경로로 옮겼다.
- ViewModel 파일에 있던 내비게이션 프로토콜·NavigationManager 구현을 Application/Navigation으로 이동했다. 기존 구현 내용은 유지했다.
- AGENTS.md·아키텍처 문서에 독립 화면과 내부 구성 뷰의 기준을 명시했다. 기존 ObservableObject 영역은 같은 관찰 방식을 사용한다.

관련 코드: [홈 View](../../../Yut/Yut/Sources/Views/Lobby/HomeView.swift), [홈 ViewModel](../../../Yut/Yut/Sources/ViewModels/Lobby/HomeViewModel.swift), [내비게이션](../../../Yut/Yut/Sources/Application/Navigation/Protocols/HomeNavigating.swift), [앱 조립](../../../Yut/Yut/Sources/Application/AppDependencies.swift).

## 하위 뷰 폴더 정리 — 2026-11-11

당시에는 화면과 구성 뷰가 같은 위치에 섞여 있던 부분을 부모 기준으로 묶었다. 아래는 이전 구조이며, 현재 경로는 상단 표와 11월 12일 기록을 따른다.

```text
Views/Lobby/WaitingRoom/
├── WaitingRoomView.swift
└── Components/
    ├── WaitingRoomHeader.swift
    └── AddPlayerModalView.swift
```

- RoomList의 행, Winner의 승자·패자·버튼 행, Play의 배치·플레이 조작과 AR 연결·이미지 뷰도 각 화면의 `Components`에 모았다. 화면 파일 내부의 의미 있는 하위 View 6개를 별도 파일로 옮겼다.
- Host·Guest는 각각 화면 폴더로 구분하고, 둘이 공유하는 닉네임 화면·폼은 `NameInput/Components`에 뒀다. ViewModel은 각 화면 경로에 맞췄다.
- 이동한 타입의 이름·입력·body·액션은 유지했다. 별도 파일에서 참조하도록 기존 하위 View의 타입 접근 수준만 `private`에서 internal로 바꿨다. ViewModel·게임·AR·물리·모으기 동작은 변경하지 않았다.
- 관련 문서의 이동된 소스 링크도 갱신했다. 후속 빌드 2종·회귀 62개·홈/로비/AR UI 3개가 통과했다.

## 기능별 구조 적용 — 2026-11-12

화면별 중간 폴더를 걷고 로비 5개 화면은 `Lobby`, 플레이·승리 화면은 `Game` 바로 아래에 배치했다. ViewModel도 같은 기능 경로로 맞췄다. 하위 뷰는 `SubViews/NameInput`·`RoomList`·`WaitingRoom`·`Play`·`Winner`에 묶고, 구성 관계가 있는 폼·AR 연결·던지기 버튼만 해당 영역의 `Components`에 두었다. 타입과 구현은 그대로 유지했다. [전체 폴더 정리·검증](directory-structure-review.md#디렉토리-적용-결과--2026-11-12)에서 이번 검증 결과를 확인한다.

## 검증

| 검증 | 결과 |
| --- | --- |
| iOS / iOS Simulator 빌드 | 둘 다 성공. 변경 코드의 새 Swift 컴파일 오류·경고 없음 |
| 전체 단위·통합 회귀 | **62개 / 12개 suite 통과.** 새 Home 액션 구분과 기존 닉네임·로비·승리/재경기·게임 회귀 포함 |
| UI | **3개 통과.** 홈 → 방 생성·추가 인원·퇴장·재생성, 홈 → 참여·방 목록·뒤로가기, AR 배치→모으기→수동 던지기 확인 |
| 파일·폴더 대응 | 독립 화면 7개의 View·ViewModel 타입·파일·기능 경로 일치 확인 |
| 보존 | 닉네임·로비·승리·Play ViewModel의 기존 동작, 내비게이션 구현 내용 대조. 게임 규칙·AR·물리·모으기 코드는 변경하지 않음 |

범위 대조: `/tmp/yut-screen-mvvm-scope.json`. 결과: `/tmp/yut-screen-mvvm-tests.xcresult`, `/tmp/yut-screen-mvvm-ui.xcresult`. 빌드: `/tmp/yut-screen-mvvm-device.log`, `/tmp/yut-screen-mvvm-simulator.log`. 단위 실행은 iOS 18.3.1 시뮬레이터 / SDK 27.2이며 테스트용 임시 프로젝트만 배포 대상을 18.3으로 바꿨다. 저장소 기본값 18.5는 유지했다.

**하위 뷰 정리 후 재검증:** `/tmp/yut-view-hierarchy-tests.xcresult`에 회귀 62개·UI 3개 통과 기록. 빌드: `/tmp/yut-view-hierarchy-device.log`, `/tmp/yut-view-hierarchy-simulator.log`. 이동 파일 14개의 내용 일치, 화면·하위 뷰 9개 정의 일치(타입 접근 수준·공백 제외), Views/ViewModels 외 앱·리소스·테스트 해시 보존을 `/tmp/yut-view-hierarchy-scope.json`으로 확인했다. 실기기 실행은 하지 않았으며 폴더·파일 분리로 인한 동작 변화는 자동 검증에서 발견되지 않았다.

[모으기 시작 지연](../game/yut-gathering-hitch.md#현재-yut-모으기-끊김-분석--2026-11-11)은 후속 작업이며 이번 구조 정리가 해당 성능 문제를 해결한 것은 아니다.

## 작업 이력

| 날짜 | 작업 | 결과·후속 |
| --- | --- | --- |
| 2026-11-11 | 독립 화면 7개 매칭·Home 액션 분리·파일/폴더/내비게이션 정리 | 빌드 2종·회귀 62개·UI 2개 통과, 화면 7개 대응 확인 |
| 2026-11-11 | 부모 화면별 Components 구성, 하위 View 6개 파일 분리, 화면·ViewModel 경로 재대응 | 빌드 2종·회귀 62개·홈/로비/AR UI 3개 통과. 동작 코드·리소스 보존 |
| 2026-11-12 | 기능별 화면/VM·SubViews 재배치, 승리 화면 Game으로 이동 | 화면 7개 대응 유지, 빌드 2종·회귀 85개·UI 3개 통과. 구현 내용 보존 |

## 설정 화면 추가 — 2026-11-12

초기 설정·문서·문의 화면 3쌍을 추가해 당시 독립 화면은 10개였다. 같은 기능 경로 `Settings`를 사용하며 섹션은 `SubViews/{Settings,Legal,Support}`에 둔다. Terms·Privacy는 데이터 종류가 다른 같은 문서 화면을 사용한다. 앱 공통 안내와 게임 종료 대체 뷰는 값·액션을 받는 구성 요소이므로 빈 ViewModel을 추가하지 않았다. [설정 QA](../ui/settings-and-legal.md).

**2026-11-12 / 제작자 분리:** 제작자 메뉴의 독립 화면 CreatorsView–CreatorsViewModel을 추가해 현재 11개 화면이 대응한다. 이름 목록은 SubViews/Creators에 두었다. [설정 QA](../ui/settings-and-legal.md#제작자-메뉴-분리--2026-11-12).
