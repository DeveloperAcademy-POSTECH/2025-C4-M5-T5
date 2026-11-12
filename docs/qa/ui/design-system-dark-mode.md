# 다크모드 가독성·디자인 시스템 정리

**상태: 검증 대기 · 우선순위: 높음 · 갱신: 2026-11-11**

추가·게임 시작 버튼 등이 다크모드에서 밝은 배경과 흰 글자로 겹치던 문제를 수정했다. **버튼·입력창·모달·카드·안내 UI의 색상·스타일을 공용화하고 역할별 디렉토리로 정리했다.** 실제 iPhone 15 Pro 화면 확인은 대기다. 구조·추가 방법은 [디자인 시스템 문서](../../guides/design-system.md)를 따른다.

## 원인과 적용

| 확인한 문제 | 적용 |
| --- | --- |
| Brown4는 다크모드에서 크림색이 되지만 추가·시작 버튼 글자는 고정 흰색 | `ThemeColors`의 배경·전경 쌍과 `ActionButton`으로 통일. 다크모드의 밝은 버튼 위에는 어두운 글자 적용 |
| 입력창·모달 제목은 기본 글자색, 안내 배경은 고정 흰색 등 조합 혼재 | 입력 문자·힌트·카운터·커서와 패널의 테마 색을 명시. 공통 `TextInputField`, `ModalPanel`, `SurfaceStyle` 적용 |
| 닉네임 화면의 `Color("White1")`은 실제 `white1`과 이름이 다름 | 생성된 색상 접근자를 사용하는 `ThemeColors.canvas`로 교체 |
| 비활성 버튼에 낮은 대비의 회색·흰색 조합과 잘못된 활성 외형 | 활성/비활성 색을 공용 버튼에서 관리. 대기실은 `canStartGame`으로 색·입력 권한을 함께 표시 |
| 추가·업기 모달, 이름 입력·승리 버튼·카드 스타일이 화면마다 중복 | 공통 버튼·입력·패널·카드 표면 적용. 모달 글자 수 표시를 입력창 아래로 정렬. 닉네임 10자 제한 유지 |
| 고정 파란 말 배경 위 승리 제목에 테마 반전 색을 사용 | 말 색은 유지하고 고정 밝은/어두운 전경을 대응. 네 승자 색을 두 모드에서 검증 |
| 공용 UI 폴더에 게임 모델·화면 전용 뷰가 섞임 | 공용 뷰는 Button/Input/Surface/Card/Feedback/Layout으로 분리. 업기·결과·모으기·던지기는 AR 화면 폴더, 승리 화면·표시 색은 Lobby/Winner로 이동 |

`PlayerCard`는 `PlayerModel` 대신 이름·이미지 이름만 받는다. 사용하지 않는 `EmptyPlayerCard`·Font.PR 별칭, 교체된 UIViewButton·RoundedBrownButton과 중복 스타일은 제거했다. 앱의 색상 모드를 강제하지 않는다.

## 검증

| 검증 | 결과 |
| --- | --- |
| 색상 대비 | 라이트·다크의 주요 글자/배경·활성/비활성/보조 버튼·힌트·네 승자 색 조합이 테스트 기준 4.5 이상 통과 |
| UI: 실제 시스템 다크모드 | **2개 통과.** 닉네임·빈/입력된 추가 창·대기실 활성/비활성 시작 버튼·퇴장, AR 배치·시작·모으기·수동 투사·결과 후 진행 |
| UI: 실제 시스템 라이트모드 | **3개 통과.** 같은 닉네임·추가·대기실 흐름, 방 목록 뒤로가기, 방 생성·퇴장·재생성 |
| 렌더 이미지 | 두 모드의 공용 컴포넌트·업기 모달·네 승자 화면, 총 12장 생성. 버튼·패널·승리 제목 대비 확인 |
| 전체 단위·통합 회귀 | **61개 / 11개 suite 최종 통과**, 실패·건너뜀 없음 |
| iOS / iOS Simulator 빌드 | 두 대상 성공. 변경 코드의 새 Swift 컴파일 오류·경고 없음 |
| 보존 범위 | 리소스 136개, Utility·ViewModel·게임 규칙·정지 모델 해시 일치. 모으기 연출·던지기 이미지 버튼은 내용 수정 없이 이동 |
| 실기기 | **검증 대기.** 15 Pro 라이트/다크·실제 카메라 배경 위 안내·모달 가독성 확인 |

UI 검증은 실행 인수의 이름만으로 테마를 판단하지 않고, `simctl ui <기기 ID> appearance dark/light`로 시스템 모드를 전환한 후 캡처의 실제 배경·글자를 확인했다. 완료 후 원래 라이트모드로 복구했다. iOS 18.3.1 시뮬레이터 / SDK 27.2로 실행했으며 임시 테스트 프로젝트만 배포 대상 18.3을 사용했다. 저장소 기본값은 18.5다.

결과: `/tmp/yut-design-system-unit.xcresult`, `/tmp/yut-design-system-final-unit.xcresult`, `/tmp/yut-design-system-dark-ui.xcresult`, `/tmp/yut-design-system-light-ui.xcresult`. 빌드: `/tmp/yut-design-system-device-final.log`, `/tmp/yut-design-system-simulator-final.log`. UI 캡처: `/tmp/yut-design-system-dark-ui-attachments`; 렌더 이미지: `/tmp/yut-design-system-gallery`. 보존 근거: `/tmp/yut-design-system-preservation.json`.

테스트: [대비 검증](../../../Yut/YutTests/DesignSystem/DesignSystemContrastTests.swift), [컴포넌트·승리 렌더](../../../Yut/YutTests/DesignSystem/DesignSystemRenderingTests.swift), [실제 화면 흐름](../../../Yut/YutUITests/Flows/YutUITests.swift). 윷 물리·면 판정·판정 시간·게임 규칙·통신 동작은 이번 변경 범위가 아니다.

## 작업 이력

| 날짜 | 작업 | 결과·후속 |
| --- | --- | --- |
| 2026-11-11 | 고정 흰 글자·색 반전 불일치 수정, 공용 UI·색상 역할·폴더 정리 | 대비·렌더·라이트/다크 UI 통과, 15 Pro 검증 대기 |
