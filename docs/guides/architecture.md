# Yut MVVM 아키텍처

이 문서는 Yut의 MVVM 책임과 폴더 구조를 정의한다. Resources/Sources 분리, Application 내 내비게이션 집중, 화면별 View/ViewModel 대응, DesignSystem 분리를 기준으로 의존성 주입과 테스트 가능성을 유지한다.

## 1. 목표

- 화면 코드와 비즈니스 로직을 분리한다.
- 기능 간 의존성을 명확히 하고 순환 의존을 막는다.
- AR, 오디오, 저장소, 네트워크 같은 외부 시스템을 교체하고 테스트할 수 있게 한다.
- 공용 디자인 요소와 화면 전용 UI를 구분한다.
- Resources와 Sources를 분리해 리소스와 코드의 위치를 명확히 한다.

## 2. 계층과 의존성 방향

```text
App / Application
        │ 조립·라우팅
        ▼
View ───── 사용자 액션 ────▶ ViewModel
 ▲                              │
 │ 화면 상태                    │ 유스케이스 호출
 └──────────────────────────────┘
                                ▼
                         Domain Model / Service
                                │
                                ▼
                      Repository / System Adapter
```

허용되는 의존성 방향은 바깥쪽에서 안쪽으로 향한다.

- View → ViewModel, DesignSystem
- ViewModel → Model, Service/Repository protocol, Navigation abstraction
- Service → Model, Repository protocol
- Repository/Manager 구현 → Foundation, SwiftData, AVFoundation, ARKit, RealityKit 등
- Application → 모든 구현을 알고 생성·주입하는 composition root

Model과 ViewModel은 구체적인 View에 의존하지 않는다. ViewModel은 SwiftUI View를 만들거나 반환하지 않는다.

## 3. 역할 정의

### Application

앱의 진입점과 객체 그래프를 조립한다.

- `App` 구현
- RootView
- 내비게이션 route와 destination 매핑
- 앱 전역 생명주기
- 실제 Service/Repository/Manager 구현 생성과 주입
- 앱 전역 설정

`AppDependencies`에서 의존성을 조립하고 `RootView`·`NavigationManager`·`Route`로 화면을 연결한다. ViewModel에는 내비게이션 프로토콜을 initializer로 주입한다.

### View

표현과 입력 전달만 담당한다.

- 상태를 화면에 렌더링
- 사용자 입력을 ViewModel 메서드로 전달
- 포커스, 일시적 sheet 표시 여부, 애니메이션처럼 화면 전용인 로컬 상태 보유
- DesignSystem 컴포넌트 조합
- 접근성 정보 제공

View에 저장소 접근, 비즈니스 규칙, 네트워크/파일 I/O를 두지 않는다.

### ViewModel

한 화면의 프레젠테이션 상태와 사용자 액션을 관리한다.

- `[ViewName]ViewModel`로 명명
- `@MainActor`로 UI 상태 격리
- 지원 OS가 허용하면 `@Observable final class` 사용
- 사용자 입력 검증
- Service/UseCase 호출
- 로딩, 성공, 빈 상태, 오류 상태 변환
- 내비게이션 의도를 abstraction을 통해 전달

ViewModel은 재사용 가능한 도메인 규칙의 최종 저장소가 아니다. 여러 화면에서 공유하는 규칙은 Service 또는 Model로 이동한다.

### Model

UI와 무관한 데이터와 도메인 규칙을 표현한다.

- entity와 value type
- enum
- 상태 전이와 불변식
- 저장/전송 모델과 화면 모델 간 변환

SwiftData의 `@Model`처럼 프레임워크 결합이 필요한 persistence model은 `Data/Persistence`에 두고, 가능하면 도메인 Model과 분리한다.

### Service / UseCase

여러 저장소나 시스템 동작을 조합하는 애플리케이션 로직을 담당한다.

- 촬영 세션 시작과 종료
- 게임 턴 진행
- 사진 처리 파이프라인
- 온보딩 완료 처리

작은 프로젝트에서는 Service로 시작하고, 유스케이스가 복잡해질 때 명시적인 `UseCase` 타입으로 분리한다. 이름만 다른 전달 계층은 만들지 않는다.

### Repository / Manager

외부 데이터와 시스템 프레임워크의 경계다.

- SwiftData/UserDefaults 저장
- 네트워크 요청
- 파일 시스템
- 오디오/카메라/AR 세션
- RealityKit entity와 asset 수명 관리

ViewModel에는 protocol을 주입하고 실제 구현은 Application에서 만든다. Manager는 “무엇이든 관리하는” 타입이 되지 않도록 하나의 자원 또는 책임만 가진다.

### DesignSystem

화면과 무관하게 재사용되는 시각 언어를 제공한다.

- Color, Typography, Spacing, Shape token
- Button, Label, TextField, Indicator, BottomSheet
- 공용 modifier와 접근성 기본값

비즈니스 모델 또는 특정 화면 ViewModel에 의존하지 않는다. `ActionButton`, `TextInputField`, `Typography`는 표시와 스타일을 담당하는 공용 요소다.

## 4. 폴더 구조

Yut은 리소스를 `Resources`, 코드를 `Sources`에 둔다. `Views`와 `ViewModels`는 각각 최상위에서 관리하고, 같은 기능의 파일은 그 아래 동일한 기능 이름의 하위 폴더로 대응시킨다.

```text
ProjectName/                 Yut의 앱 타깃 폴더: Yut/Yut
├── Resources/
│   ├── Assets.xcassets/
│   ├── Color.xcassets/
│   ├── Fonts/
│   ├── Sounds/
│   └── Preview Content/
└── Sources/
    ├── Application/
    │   ├── AppNameApp.swift
    │   ├── RootView.swift
    │   └── Navigation/
    │       └── Destination/
    ├── Views/
    │   └── FeatureName/          독립 화면들과 SubViews/<영역>
    ├── ViewModels/
    │   └── FeatureName/          화면과 같은 기능 경로
    ├── DesignSystem/
    │   ├── Color/
    │   ├── Font/
    │   └── Component/
    ├── Models/
    │   ├── AR/
    │   ├── Game/
    │   └── Lobby/
    └── Utility/
        ├── Extensions/<영역>/
        └── Managers/<시스템>/
            └── Protocols/      해당 경계의 작은 프로토콜
```

테스트 타깃은 앱 타깃 폴더와 나란히 `Yut/YutTests`와 `Yut/YutUITests`에 둔다. 단위 테스트는 `DesignSystem`·`Models`·`ViewModels`·`Utility`·`Support`, UI 테스트는 `Flows`·`Launch`로 구분한다.

최상위 `Features` 디렉토리는 사용하지 않는다. 화면과 ViewModel은 각각 `Sources/Views/<FeatureName>`, `Sources/ViewModels/<FeatureName>`에 두며 동일한 기능 이름으로 연결한다. 앱 진입점과 내비게이션은 `Application`, 공용 시각 요소는 `DesignSystem`, 모델은 `Models`, 시스템 어댑터와 확장은 `Utility`에 둔다.

## 5. 기능별 하위 폴더 규칙

같은 기능의 독립 화면 여러 개를 기능 폴더 바로 아래에 두고, 하위 구성 뷰는 `SubViews`에서 영역별로 묶는다.

```text
Sources/
├── Views/
│   ├── Lobby/
│   │   ├── HomeView.swift
│   │   ├── HostNameInputView.swift
│   │   ├── GuestNameInputView.swift
│   │   ├── RoomListView.swift
│   │   ├── WaitingRoomView.swift
│   │   └── SubViews/
│   │       ├── NameInput/
│   │       │   ├── NameInputScreen.swift
│   │       │   └── Components/NameInputFormView.swift
│   │       ├── RoomList/RoomRowView.swift
│   │       └── WaitingRoom/   헤더·인원 추가 모달
│   └── Game/
│       ├── PlayView.swift
│       ├── WinnerView.swift
│       └── SubViews/
│           ├── Play/          배치·플레이 조작·업기·결과·모으기
│           │   └── Components/  ARViewContainer, YutThrowButton
│           └── Winner/        승자·패자·버튼 행
└── ViewModels/
    ├── Lobby/                 위 로비 화면 5개의 ViewModel
    └── Game/                  PlayViewModel, WinnerViewModel
```

- 다른 기능에서도 재사용하는 UI는 `DesignSystem/Component`로 승격한다.
- 한 화면의 섹션과 같은 기능의 여러 화면이 공유하는 뷰 모두 `Views/<기능>/SubViews/<영역>`에서 관리한다. 화면 파일에는 독립 화면의 조합을 남긴다.
- `Components`는 해당 영역의 구성 요소를 별도로 묶을 실제 관계가 있을 때 추가한다. `SubViews`와의 구분은 크기·전체 화면 여부·재사용 횟수로 결정하지 않으며, 모든 영역에 같은 깊이를 강제하지 않는다.
- `NameInputScreen`이 사용하는 폼은 `SubViews/NameInput/Components`, 플레이 조작을 구성하는 `ARViewContainer`·`YutThrowButton`은 `SubViews/Play/Components`에 둔다.
- 시스템 구현은 `Utility/Managers/{AR,Game,Multipeer,Asset,Audio,Haptic}`에 둔다. 프로토콜은 해당 경계의 `Protocols`, 내비게이션 프로토콜은 `Application/Navigation/Protocols`, route는 `Destination`에 둔다.
- 모델은 `Models/{AR,Game,Lobby}`, 확장은 `Utility/Extensions/{AR,Game}`처럼 책임별로 묶는다. 폴더 재배치가 모델 경계나 큰 타입의 책임 분리까지 완료했다는 뜻은 아니다.
- 기능 사이에서 서로의 ViewModel을 직접 참조하지 않는다.
- 공유할 데이터와 동작은 `Models` 또는 `Utility`의 작은 프로토콜 뒤에 둔다.

### 독립 화면의 View–ViewModel 대응

- 내비게이션의 독립 화면은 `[화면명]View`–`[화면명]ViewModel`을 1:1로 대응시킨다. 각 ViewModel 타입은 이름이 같은 별도 파일에 둔다.
- `Views/<기능>/<화면명>View.swift`와 `ViewModels/<기능>/<화면명>ViewModel.swift`의 기능 경로를 맞춘다. 독립 화면이 단순해도 사용자 액션·화면 전환 의도는 화면 ViewModel에서 조정한다.
- 화면 내부 섹션·단순 모달은 부모의 값·Binding·액션으로 표시한다. `NameInputScreen`·`NameInputFormView`는 Host/Guest 닉네임 화면의 공통 구성 뷰이므로 별도 ViewModel을 만들지 않는다.
- DesignSystem에는 업무 상태와 ViewModel을 전달하지 않는다. 버튼·입력창·카드마다 빈 ViewModel을 만들지 않는다.
- `RootView`는 Application의 화면 조립·route 매핑, `ARViewContainer`는 UIKit/AR 연결 어댑터다. 두 타입은 독립 화면 대응 대상이 아니다.
- 화면 전환 프로토콜과 NavigationManager의 구현은 `Application/Navigation`에 두고, ViewModel에는 작은 프로토콜을 주입한다. View에서 구체 내비게이션을 직접 호출하지 않는다.

현재 Yut의 화면 대응 목록·검증은 [화면별 MVVM 정리 QA](../qa/structure/screen-viewmodel-mapping.md)에서 확인한다.

## 6. 상태 소유권

| 상태 종류 | 소유 위치 | 예 |
|---|---|---|
| 일시적인 UI 상태 | View | focus, 펼침 여부, 애니메이션 |
| 화면 프레젠테이션 상태 | ViewModel | loading, error, 입력 검증 |
| 여러 화면이 공유하는 앱 상태 | 앱에서 생성한 shared model | 로그인 세션, 게임 세션 |
| 영속 데이터 | Repository | 사진, 사용자 설정 |
| 시스템 자원 상태 | 전용 Manager/Adapter | 카메라, 오디오, AR 세션 |

상태의 단일 소유자를 정하고 하위 계층에는 값 또는 Binding을 전달한다. 같은 상태를 View와 ViewModel에 중복 저장하지 않는다.

## 7. 의존성 주입

```swift
protocol PhotoRepository {
    func requestPhotos() async throws -> [Photo]
}

@MainActor
@Observable
final class GalleryViewModel {
    private let photoRepository: any PhotoRepository

    private(set) var photos: [Photo] = []
    private(set) var errorMessage: String?

    init(photoRepository: any PhotoRepository) {
        self.photoRepository = photoRepository
    }

    func loadPhotos() async {
        do {
            photos = try await photoRepository.requestPhotos()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
```

- 기본 initializer 안에서 구체 구현을 직접 만들지 않는다.
- singleton은 시스템이 제공하는 것 또는 앱 전역 단일성이 도메인 불변식인 경우에 한해 Application 경계에서 감싼다.
- Preview와 테스트에는 fake 구현을 주입한다.

## 8. 내비게이션

- `NavigationStack`과 Hashable route를 사용한다.
- route 선언과 destination-to-View 매핑은 Application/Navigation에 둔다.
- 화면은 가능한 한 “어디로 갈지”보다 “무슨 일이 완료됐는지”를 ViewModel에 알린다.
- ViewModel이 내비게이션을 요청해야 한다면 작은 `Navigating` 프로토콜을 주입한다.
- destination에서 View를 생성하는 패턴은 허용하지만, 의존성이 필요한 화면은 composition root의 factory에서 생성한다.
- `NavigationView`, 문자열 기반 route, 화면 곳곳의 전역 singleton 접근을 새로 추가하지 않는다.

## 9. 유지할 구조와 개선 기준

유지할 점:

- Resources와 Sources의 명확한 분리
- Application/Navigation/Destination 구조
- 화면별 View와 ViewModel 네이밍
- DesignSystem의 Color, Font, Component 세분화
- Models의 책임별 분류 및 Utility/Extensions 분리

개선할 점:

- ViewModel의 `NavigationManager.shared` 직접 참조를 initializer 주입으로 변경
- 새 관찰 모델은 배포 타깃이 허용할 때 `ObservableObject` 대신 `@Observable` 사용
- `NavigationView`를 `NavigationStack`으로 통일
- 큰 View의 중첩 레이아웃과 계산 View를 의미 있는 하위 View 타입으로 분리
- View에 선언된 샘플 배열과 임시 비즈니스 데이터를 ViewModel 또는 Model로 이동
- persistence model과 도메인 model의 경계를 명확히 함
- 오류를 TODO로만 남기지 않고 사용자 상태 또는 throw로 전달

## 10. 리팩토링 순서

1. 현재 동작을 테스트 또는 관찰 가능한 시나리오로 고정한다.
2. 화면별 상태와 외부 의존성을 목록화한다.
3. View에서 비즈니스 로직과 I/O를 ViewModel/Service로 이동한다.
4. 구체 의존성 앞에 필요한 최소 protocol을 정의한다.
5. Application에서 객체를 생성하고 initializer로 주입한다.
6. 중복 UI를 DesignSystem으로 옮긴다.
7. 기능 단위로 폴더를 이동한다.
8. 각 단계마다 빌드와 관련 테스트를 실행한다.

동작 변경, 관찰 시스템 전환, 폴더 대이동을 한 번의 커밋에 모두 포함하지 않는다.

## 11. 테스트 전략

- Model: 불변식, 계산, 상태 전이를 Swift Testing으로 검증
- ViewModel: 사용자 액션별 상태와 Service 호출을 fake로 검증
- Service: Repository 조합과 오류 전달을 검증
- Repository: 필요하면 임시 저장소 또는 integration test로 검증
- View: 핵심 사용자 여정만 XCUIAutomation으로 검증

ViewModel 테스트는 실제 NavigationManager, 파일, 네트워크, 카메라, AR 세션에 의존하지 않아야 한다.
