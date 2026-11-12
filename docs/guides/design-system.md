# Yut 디자인 시스템

현재 실행 대상인 `Yut` 기준이다. 원본의 갈색·크림색과 말 이미지를 유지하며, 라이트·다크모드의 전경·배경을 역할별로 짝지어 사용한다. 검증 결과는 [다크모드 QA](../qa/ui/design-system-dark-mode.md)에서 추적한다.

## 구조와 책임

```text
Yut/Yut/Sources/
├── DesignSystem/
│   ├── Color/         ThemeColors, UIKit 색상 변환
│   ├── Font/          글꼴 등록 이름, Typography
│   ├── Component/
│   │   ├── Button/    ActionButton, IconButton
│   │   ├── Input/     TextInputField
│   │   ├── Surface/   SurfaceStyle, ModalPanel
│   │   ├── Card/      PlayerCard, AddPlayerCard
│   │   ├── Feedback/  InstructionView, ProgressBar
│   │   └── Layout/    DecoratedBackground
│   └── Modifier/      키보드 닫기
└── Views/
    ├── Lobby/                 Home, Host/GuestNameInput, RoomList, WaitingRoom
    │   └── SubViews/
    │       ├── NameInput/     공통 화면과 Components/NameInputFormView
    │       ├── WaitingRoom/   헤더·인원 추가 모달
    │       └── RoomList/      목록 행
    └── Game/                  PlayView, WinnerView
        └── SubViews/
            ├── Play/         배치·플레이 조작, 업기·결과·모으기
            │   └── Components/  ARViewContainer, YutThrowButton
            └── Winner/       승자·패자·버튼 행
```

DesignSystem에는 게임 규칙·네트워크·플레이어 모델을 전달하지 않는다. 예를 들어 `PlayerCard`는 `PlayerModel` 대신 `name`·`profileImage`만 받는다. 게임 결과·차례·업기처럼 해당 기능에서만 의미 있는 뷰는 기능의 `SubViews`에 둔다. 독립 화면의 ViewModel 대응은 [화면별 MVVM 기준](architecture.md#독립-화면의-viewviewmodel-대응)을 따른다.

## 공용 컴포넌트

| 컴포넌트 | 사용 기준 |
| --- | --- |
| `ActionButton` | 입력 완료·추가·게임 시작·AR 액션·종료/재경기·업기 선택. primary/secondary, compact/regular/large 제공. 활성·비활성·눌림 색은 컴포넌트에서 결정 |
| `IconButton` | 뒤로가기·로비 나가기. 아이콘과 접근성 이름·액션을 받고 44pt 입력 영역 제공 |
| `TextInputField` | 입력 글자·힌트·커서·테두리·글자 수 표시. 화면이 글자 수 제한과 자동 포커스 여부를 전달 |
| `SurfaceStyle` | 카드·방 목록 행·AR 안내의 공통 배경·테두리·그림자. overlay는 테마 표면을 충분히 덮어 카메라 배경과 글자가 섞이지 않게 함 |
| `ModalPanel` | 딤 배경·패널·여백. 내용과 결정 액션은 기능 뷰가 소유하며, 바깥 탭 닫기는 전달한 경우만 수행 |
| `InstructionView`, `ProgressBar` | 안내·진행 표시. 화면은 표시할 문구와 수치만 전달 |

```swift
ActionButton(title: "추가", isEnabled: !nickname.isEmpty, size: .compact) {
    submitNickname()
}

TextInputField(text: $nickname, placeholder: "닉네임", characterLimit: 10)
```

## 색상·작성 규칙

- 텍스트는 `ThemeColors.textPrimary/textSecondary`, 화면 배경은 `canvas`, 패널은 `surface`를 사용한다. 버튼 바깥에서 배경·글자색을 따로 덮어쓰지 않는다.
- 기존 Brown4 에셋은 다크모드에서 밝은 크림색으로 바뀐다. 그 위 글자는 고정 `.white`가 아니라 `primaryButtonText`를 사용하며 함께 어두운 색으로 전환한다.
- 말 색은 두 모드에서 고정이다. `ThemeColors.playerYellow/Jade/Blue/Red`가 `SurfaceColors(background:foreground:)`로 기존 말 색과 대비 글자색을 함께 제공한다. 파랑은 기존 흰색, 나머지는 기존 갈색 전경을 사용한다.
- `surfaceStyle(colors:)`, `InstructionView(colors:)`, `ProgressBar(colors:)`는 이 색상 쌍을 전달받는다. 게이지는 채워진 영역에만 해당 배경·전경을 적용한다. DesignSystem은 플레이어·턴을 판단하지 않는다.
- 말 종류와 색상 쌍의 연결은 [PieceType+Appearance](../../Yut/Yut/Sources/Utility/Extensions/Game/PieceType+Appearance.swift)에 둔다. 스캔은 해당 기기의 첫 등록 플레이어, 게임 안내는 현재 턴, 결과는 던진 플레이어를 기준으로 한다. [검증 기록](../qa/ui/player-colors-and-room-list.md).
- 색상 에셋은 생성된 접근자를 우선한다. `Color("White1")`처럼 실제 이름 `white1`과 대소문자가 다른 문자열을 화면에 추가하지 않는다.
- 반복 글꼴은 `Typography`에서 관리한다. 홈 로고·승리 제목처럼 화면 전용인 큰 글꼴은 해당 화면에 둔다.
- 새 공용 UI는 `Component`의 역할별 폴더에 추가하고, 특정 화면 전용 뷰를 범용 컴포넌트로 올리지 않는다.
- 앱 전체를 라이트모드로 강제하지 않는다. 새 색상 조합은 두 모드에서 대비와 실제 화면을 확인한다.
