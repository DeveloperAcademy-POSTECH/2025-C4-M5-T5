# 설정·약관·문의 QA

**상태: 구현 완료 · 출시 정보 미정 / 갱신: 2026-11-12**

홈 우측 상단 톱니바퀴로 설정에 들어가 약관·개인정보처리방침·문의하기·제작자를 확인한다.

| 항목 | 구현·검증 |
| --- | --- |
| 화면 구조 | Settings·LegalDocument·Support·Creators의 View–ViewModel 4쌍. 기능별 SubViews, 기존 디자인 시스템 재사용 |
| 문서 | 앱 번들에서 비동기 로딩. 오프라인 표시, 실패 시 재시도 |
| 데이터 설명 | 닉네임·게임 상태·AR 공간 정보의 참가자 간 전달, 카메라·센서·로컬 네트워크 사용을 코드 기준으로 작성 |
| 문의 | ‘준비중’ 단독 표시. 연락처·메일·주소 복사 버튼은 노출하지 않음 |
| 제작자 | 약관·방침·문의와 같은 메뉴에 배치. 누르면 별도 화면의 기본 배경에 장성태 → 이윤서 → 박승은 → 소연수 → 황세연 표시. 카드 없음 |
| 미정 값 | 이메일·시행일은 사용자 요청으로 미등록. 공개 URL도 미정, 외부 게시 없음 |

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

사용자 요청으로 비워둔 문의 이메일·시행일, 실제 운영 책임 주체, 공개 개인정보처리방침 URL을 확정한다. 문의 활성화 전 보유·삭제 기준과 최종 약관·방침을 검토하고 배포본의 App Store 개인정보 응답과 일치시킨다.

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
