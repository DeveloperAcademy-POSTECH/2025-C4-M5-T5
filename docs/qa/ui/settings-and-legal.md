# 설정·약관·문의 QA

**상태: 자동 검증 완료 · 실기기 검증 대기 · 출시 정보 미정 / 갱신: 2026-11-13**

홈 우측 상단 톱니바퀴로 설정에 들어가 약관·개인정보처리방침·제작자를 확인하고, 문의하기에서 카카오 오픈채팅을 연다.

| 항목 | 구현·검증 |
| --- | --- |
| 화면 구조 | Settings·LegalDocument·Creators의 View–ViewModel 3쌍. 기능별 SubViews, 기존 디자인 시스템 재사용 |
| 문서 | 앱 번들에서 비동기 로딩. 오프라인 표시, 실패 시 재시도 |
| 데이터 설명 | 닉네임·게임 상태·AR 공간 정보의 참가자 간 전달, 카메라·센서·로컬 네트워크 사용을 코드 기준으로 작성 |
| 문의 | 전달받은 카카오 오픈채팅 링크를 바로 열고, 실패하면 재시도 안내. 중복 열기 방지 |
| 제작자 | 약관·방침·문의와 같은 메뉴에 배치. 누르면 기본 배경 위에 제작자·CREATED BY·이름 두 줄을 상단에 배치하고 가로 중앙 정렬. 첫 줄 장성태·이윤서·소연수, 둘째 줄 박승은·황세연 |
| 문서 날짜·문의처 | 시행일 2026년 11월 13일. 작성일 제거, 문의처는 카카오 오픈채팅. 공개 약관/방침 URL은 미정 |

## 초기 구현 검증 결과

- iOS·iOS Simulator 빌드 성공. 변경 Swift 코드에 새 컴파일 오류·경고 없음. 기존 AppIntents 메타데이터 추출 안내만 발생했다.
- 전체 단위·통합 **111개 / 17개 suite 통과**. 새 설정 경로·제작자 순서·미등록 문의·메일 실패/복사·문서 번들·문서 재시도 포함.
- 라이트 UI: 설정 진입 → 제작자 5명 → 약관 → 개인정보처리방침 → 미등록 문의 → 홈 복귀 통과. 메일·복사 버튼 비활성 확인.
- 다크 UI: 같은 설정 흐름 통과. 라이트/다크 화면 캡처의 배경·글자 대비와 카드 여백 확인.
- 실제 주소의 메일 작성·발송은 수행하지 않았다. 메일 열기 실패와 복사는 주입한 대역으로 검증했다. 실기기 QA는 사용자 요청에 따라 진행하지 않았다.

범위 대조: `/tmp/yut-settings-exit-scope.json`. 기존 리소스·윷 투사 코드·게임 모델은 보존했다.

결과: `/tmp/yut-settings-exit-final.xcresult`(단위), `/tmp/yut-settings-exit-tests.xcresult`(라이트 설정·로비 UI), `/tmp/yut-settings-dark.xcresult`(다크 설정 UI). 빌드 로그: `/tmp/yut-settings-exit-device-final.log`, `/tmp/yut-settings-exit-simulator.log`.

시뮬레이터는 iOS 18.3.1 / SDK 27.2이다. 테스트용 임시 프로젝트만 배포 대상을 18.3으로 맞췄고 저장소의 18.5는 유지했다. AR UI에서 한 차례 RealityKit의 Metal 타입 반영 내부 EXC_BAD_ACCESS가 발생했으며 같은 코드 재실행은 통과했다. 시뮬레이터 프레임워크 종료와 실제 연결 종료 제보는 구분한다.

## 출시 전 남은 항목

실제 운영 책임 주체, 문의 내용의 보유·삭제 기준과 공개 개인정보처리방침 URL을 확정한다. 최종 약관·방침을 검토하고 배포본의 App Store 개인정보 응답과 일치시킨다. 실제 카카오톡에서 방이 열리고 문의를 주고받을 수 있는지는 검증 대기다.

## 작업 이력

- **2026-11-12:** 설정 3개 화면, 오프라인 약관·방침, 문의 준비·메일/복사 경로, 제작자 구현 및 자동 검증. 연락처·시행일은 미등록 유지.

## 제작자 메뉴 분리 — 2026-11-12

설정 하단의 ‘앱 제작자’ 카드 대신 네 번째 ‘제작자’ 메뉴를 추가했다. 선택하면 CreatorsView–CreatorsViewModel 화면에 이름 5개가 표시되고 뒤로 가면 설정으로 돌아온다. 기존 이름·순서와 팔레트·카드·간격을 재사용했다. 목록 섹션은 `SubViews/Creators`로 이동했다.

**검증:** iOS·Simulator 빌드 성공. 설정 ViewModel 테스트 5개 통과. 라이트/다크 UI 2회 모두 설정에서 이름이 숨겨져 있고 ‘제작자’ 선택 시 5명이 표시되는지, 뒤로가기 및 기존 약관·방침·문의 경로가 동작하는지 확인했다. 새 Swift 오류·경고 없음. 기존 AppIntents 메타데이터 안내만 발생했다. 실기기 QA는 수행하지 않았다.

결과: `/tmp/yut-creators-light.xcresult`, `/tmp/yut-creators-dark.xcresult`. 빌드: `/tmp/yut-creators-device.log`, `/tmp/yut-creators-simulator.log`. 범위 대조: `/tmp/yut-creators-menu-scope.json`.

## 문의 준비 문구·제작자 배경 — 2026-11-12

- 문의 화면의 본문을 ‘준비중’으로 대체하고 연락처 카드·버튼·부가 안내를 제거했다.
- 제작자의 카드 배경·테두리·그림자·카드 내부 여백을 제거했다. 이름·순서는 유지하고, 약관 화면과 같은 바깥 여백 24pt·최대 너비 760pt를 적용했다.
- **검증:** iOS·Simulator 빌드 2종, 설정 단위 5개, 라이트/다크 UI 각 1회 통과. 문의 문구·메일/복사 버튼 부재·제작자 5명·뒤로가기와 기존 문서 경로를 확인했다. 캡처에서 제작자 카드가 제거된 것을 확인했다. 새 Swift 오류·경고 없음. 실기기 QA는 수행하지 않았다.

결과: `/tmp/yut-settings-plain-light.xcresult`, `/tmp/yut-settings-plain-dark.xcresult`. 빌드: `/tmp/yut-settings-plain-device.log`, `/tmp/yut-settings-plain-simulator.log`. 범위 대조: `/tmp/yut-settings-plain-scope.json`.

- **2026-11-12 / 문서 본문 관리:** 중복된 docs/legal 문서 2개와 목차 참조를 제거했다. 앱 표시 본문은 Resources/Legal에서만 관리한다. 앱 리소스의 변경이 없음을 확인하고 내부 링크를 점검했다. 문서만 변경해 빌드는 생략했다.

## 영문 앱 이름 통일 — 2026-11-13

제품 이름과 설치 후 표시되는 CFBundleDisplayName을 `YUT`로 지정했다. 생성되는 CFBundleName·실행 파일 이름과 앱 번들은 `YUT`·`YUT.app`이다. 약관·개인정보처리방침의 `윷(YUT)`, 문의 메일 제목, 로그 subsystem, 파일 헤더와 문서의 영문 앱 이름도 통일했다.

빌드 경로는 `Yut/Yut.xcodeproj`, scheme은 `Yut`, Bundle ID는 `HappyJay.Yut2`를 사용한다. Swift 타입·모듈과 모델·이미지의 이름은 코드·리소스 식별자다.

**검증:** iOS·Simulator 빌드 2종과 설정 단위 테스트 5개 통과. 두 앱 번들의 표시 이름·번들 이름·실행 파일이 `YUT`인지 확인했다. 약관·방침의 `윷(YUT)`와 설치 정보를 실제 앱 번들에서 검증했다. 설정 UI에서 문서·제작자·문의·뒤로가기를 확인했다. 변경 Swift 코드에 새 오류·경고 없음. 기존 이미지 비트 깊이·AppIntents 메타데이터 안내는 빌드 로그에 남아 있다.

처음에는 자동 생성된 CFBundleName이 제품 이름으로 덮여 단위 테스트 1개가 실패했다. 제품 이름·공유 scheme의 앱 경로·단위 테스트 host 경로를 맞춘 후 재검증했다.

결과: `/tmp/yut-brand-product-tests.xcresult`. 빌드: `/tmp/yut-brand-device-product.log`, `/tmp/yut-brand-simulator-product.log`. 테스트용 임시 프로젝트만 iOS 18.3으로 조정해 iOS 18.3.1에서 실행했다. 실제 기기 QA는 수행하지 않았다.

## 카카오 오픈채팅 문의·문서 날짜 — 2026-11-13

- 설정의 문의하기에서 `https://open.kakao.com/o/sgoSTQWi`를 시스템 URL 열기로 바로 연결한다. SettingsViewModel에 외부 열기 의존성을 주입하고, 열기 실패 시 재시도 안내·진행 중 중복 요청 방지를 추가했다. 준비중 화면과 사용하지 않는 메일·복사 경로는 제거했다.
- 약관·방침의 문의처와 외부 서비스 안내를 카카오 오픈채팅에 맞췄다. 앱은 채팅 내용을 자동으로 전송하지 않는다. 문의 정보 보유·삭제 기준은 아직 정해지지 않아 초안에 출시 전 확정 대상으로 남겼다.
- 작성일을 제거하고 시행일은 미정으로 유지했다. [개인정보보호위원회 작성지침(2026.4.)](https://www.pipc.go.kr/np/cop/bbs/selectBoardArticle.do?bbsId=BS217&mCode=G010030000&nttId=12018)의 Ⅲ-24는 변경·시행 시기와 변경 내용 공개, 이전 버전의 적용기간 확인을 안내한다. 약관도 적용 기준을 알 수 있도록 같은 표기를 유지했다.
- **검증:** iOS 빌드 성공. 설정 단위 테스트 6개에서 정확한 문의 URL·열기 실패/재시도·주소 누락·중복 요청 방지·문서 번들/날짜/문의처·문서 재시도를 확인했다. 설정 UI의 문서·제작자·홈 복귀 통과. 문의하기 선택 → 외부 링크 열기로 앱이 백그라운드 전환 → 앱 재활성화 시 설정 유지 → 홈 복귀 UI가 통과했다. 변경 Swift 코드의 새 컴파일 오류·경고는 없으며 기존 AppIntents 메타데이터 안내만 발생했다. 실제 카카오톡·실기기 문의 접수는 미실시다.

결과: `/tmp/yut-support-chat-tests.xcresult`(단위·설정 UI), `/tmp/yut-support-chat-handoff.xcresult`(외부 링크 전환 UI). 빌드: `/tmp/yut-support-chat-device.log`. iOS 18.3.1 시뮬레이터 테스트용 임시 프로젝트만 배포 대상을 18.3으로 맞췄다.

## 제작자 중앙 정렬 레이아웃 — 2026-11-13

첨부 시안에 맞춰 사람 아이콘 → 제작자 제목 → CREATED BY → 이름 두 줄로 구성했다. 첫 줄은 장성태 · 이윤서 · 소연수, 둘째 줄은 박승은 · 황세연이다. 기존 Typography·ThemeColors를 재사용하며 별도 카드 없이 기본 배경에 표시한다. 화면 상단 제목은 본문 제목으로 모으고 뒤로가기 버튼을 유지했다. 섹션은 기존 `SubViews/Creators`에서 관리한다.

**검증:** iOS 빌드 성공, 설정 단위 테스트 6개 및 라이트·다크 설정 UI 각 1회 통과. 제작자 제목·CREATED BY·이름 두 줄과 뒤로가기, 기존 약관·방침·문의 연결을 확인했다. 두 모드의 캡처에서 중앙 정렬·이름 잘림 없음·기본 배경 대비를 확인했다. 새 Swift 컴파일 오류·경고 없음. 기존 AppIntents 메타데이터 안내만 발생했다. 실기기 검증은 미실시다.

결과: `/tmp/yut-creators-layout-light.xcresult`, `/tmp/yut-creators-layout-dark.xcresult`. 빌드: `/tmp/yut-creators-layout-device.log`. 시뮬레이터는 iOS 18.3.1이며 테스트용 임시 프로젝트만 배포 대상을 18.3으로 조정했다.

## 약관·방침 시행일 확정 — 2026-11-13

사용자 요청으로 이용약관·개인정보처리방침의 시행일을 모두 2026년 11월 13일로 지정했다. 제목·도입부의 초안 및 시행일 미정 안내를 제거했다. 문의 내용의 보유·삭제 기준 등 별도 미정 항목은 출시 전 후속 확인 대상으로 유지한다.

**검증:** iOS 빌드 성공, 설정 단위 테스트 6개 통과. 실제 앱 번들에서 두 문서의 시행일·작성일 부재·초안 안내 제거와 기존 문의처를 확인했다. 새 Swift 오류·경고 없음. 기존 AppIntents 메타데이터 안내만 발생했다.

결과: `/tmp/yut-legal-effective-date-tests.xcresult`. 빌드: `/tmp/yut-legal-effective-date-device.log`. 테스트용 임시 프로젝트에서 iOS 18.3.1 시뮬레이터로 실행했다.

## 제작자 화면 여백·위계 조정 — 2026-11-13

동일한 28pt 간격과 큰 영문 문구로 요소들이 흩어져 보이던 구성을 조정했다. 아이콘은 24pt, CREATED BY는 기존 caption 글꼴로 줄이고 제목·영문을 8pt 간격으로 묶었다. 이름 두 줄 간격은 16pt로 맞췄다. 화면 높이에 맞춰 콘텐츠를 중앙에 배치하고, 콘텐츠가 커지면 스크롤할 수 있도록 했다. 상단 내비게이션 배경을 숨겨 본문과 자연스럽게 이어지도록 했다. 헤더는 `SubViews/Creators/CreatorsHeader`에서 구성하며 기존 Typography·ThemeColors를 사용한다.

**검증 완료** · iOS 빌드와 라이트·다크 설정 UI 각 1회가 통과했다. 캡처에서 중앙 배치, 제목·영문의 크기 차이, 이름 두 줄의 간격과 잘림 여부를 확인했다. 설정에서 진입하고 뒤로가는 흐름도 통과했다. 새 Swift 오류·경고가 발생하지 않았으며 기존 AppIntents 메타데이터 안내가 기록됐다. 실기기 검증은 대기 상태다.

빌드 로그는 `/tmp/yut-creators-refined-device.log`, UI 결과는 `/tmp/yut-creators-refined-light.xcresult`와 `/tmp/yut-creators-refined-dark.xcresult`에 남겼다. 테스트용 임시 프로젝트에서 iOS 18.3.1 시뮬레이터로 실행했다.

**2026-11-13 / 후속 조정** · 사용자 요청으로 제작자 내용을 상단 여백 32pt 아래에 배치하고 사람 아이콘을 제거했다. iOS 빌드·설정 UI 1회가 통과했다. 캡처에서 상단 배치·아이콘 제거·이름 두 줄을 확인했다. 새 Swift 오류·경고는 없으며 기존 AppIntents 메타데이터 안내가 기록됐다. 실기기 검증은 대기다. 결과는 `/tmp/yut-creators-top-ui.xcresult`, 빌드 로그는 `/tmp/yut-creators-top-device.log`에 남겼다.
