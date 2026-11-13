# YUT 디자인 시스템

현재 실행 대상인 `YUT` 기준이다. 원본의 갈색·크림색과 말 이미지를 유지하며, 라이트·다크모드의 전경·배경을 역할별로 짝지어 사용한다. 검증 결과는 [다크모드 QA](../qa/ui/design-system-dark-mode.md)에서 추적한다.

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
│   │   ├── Image/     PieceIcon
│   │   ├── Feedback/  InstructionView, ProgressBar
│   │   └── Layout/    DecoratedBackground
│   └── Modifier/      키보드 닫기
└── Views/
    ├── Lobby/
    │   ├── HomeView.swift
    │   ├── NameInput/SubViews/    공통 화면과 Components/NameInputFormView
    │   ├── RoomList/SubViews/     목록 행
    │   └── WaitingRoom/SubViews/  공통 대기실 배치·헤더·로컬 슬롯
    ├── Game/
    │   ├── Play/SubViews/         배치·조작·현황판·완주·결과·모으기
    │   │   └── Components/       ARViewContainer, YutThrowButton
    │   └── Winner/SubViews/       승자·패자·버튼 행
    └── Settings/
        ├── SubViews/              설정 메뉴와 Components/SettingsMenuRow
        ├── Legal/SubViews/        문서 섹션
        └── Creators/SubViews/     제작자 헤더·이름 목록
```

DesignSystem에는 게임 규칙·네트워크·플레이어 모델을 전달하지 않는다. 예를 들어 `PlayerCard`는 `PlayerModel` 대신 `name`·`profileImage`만 받는다. 게임 결과·차례·완주처럼 해당 기능에서만 의미 있는 뷰는 기능의 `SubViews`에 둔다. 독립 화면의 ViewModel 대응은 [화면별 MVVM 기준](architecture.md#독립-화면의-viewviewmodel-대응)을 따른다.

## 공용 컴포넌트

| 컴포넌트 | 사용 기준 |
| --- | --- |
| `ActionButton` | 입력 완료·추가·게임 시작·AR 액션·종료/재경기·완주·상태 안내. primary/secondary, compact/regular/large와 선택적 `SurfaceColors` 제공. 안내도 같은 높이에 두 줄까지 표시하고 isEnabled로 색상과 터치를 구분 |
| `ChoiceButton` | 결과 등 항목 선택. 배경·글자색과 테두리로 상태를 표시하며 크기·아이콘·선택 애니메이션 변화 없음. 비활성 색은 공통 토큰 사용 |
| `CountIndicator` | 주어진 전체 수와 현재 개수를 점등으로 표현. 값·색상 쌍과 선택적 비활성 색을 받고 게임 규칙에 의존하지 않음 |
| `PieceIcon` | 말 이미지 이름·크기만 전달. 원본 이미지의 투명 여백을 1.65배 확대·클리핑으로 보정. AR 현황판에서 40pt 사용. 대기실은 기존 PlayerCard의 프로필 이미지를 유지 |
| `IconButton` | 뒤로가기·로비 나가기. 아이콘과 접근성 이름·액션을 받고 44pt 입력 영역 제공 |
| `TextInputField` | 입력 글자·힌트·커서·테두리·글자 수 표시. 화면이 글자 수 제한과 자동 포커스 여부를 전달 |
| `SurfaceStyle` | 카드·방 목록 행·AR 안내의 공통 배경·테두리·그림자. overlay는 테마 표면을 충분히 덮어 카메라 배경과 글자가 섞이지 않게 함. 현황판은 showsShadow를 false로 전달 |
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
- `ActionButton(colors:)`, `surfaceStyle(colors:)`, `InstructionView(colors:)`, `ProgressBar(colors:)`는 이 색상 쌍을 전달받는다. 게이지는 채워진 영역에만 해당 배경·전경을 적용한다. DesignSystem은 플레이어·턴을 판단하지 않는다.
- 말 종류와 색상 쌍의 연결은 [PieceType+Appearance](../../Yut/Yut/Sources/Utility/Extensions/Game/PieceType+Appearance.swift)에 둔다. 스캔은 해당 기기의 첫 등록 플레이어, 게임 안내는 현재 턴, 결과는 던진 플레이어를 기준으로 한다. [검증 기록](../qa/ui/player-colors-and-room-list.md).
- 색상 에셋은 생성된 접근자를 우선한다. `Color("White1")`처럼 실제 이름 `white1`과 대소문자가 다른 문자열을 화면에 추가하지 않는다.
- 반복 글꼴은 `Typography`에서 관리한다. 홈 로고·승리 제목처럼 화면 전용인 큰 글꼴은 해당 화면에 둔다.
- 새 공용 UI는 `Component`의 역할별 폴더에 추가하고, 특정 화면 전용 뷰를 범용 컴포넌트로 올리지 않는다.
- 앱 전체를 라이트모드로 강제하지 않는다. 새 색상 조합은 두 모드에서 대비와 실제 화면을 확인한다.
