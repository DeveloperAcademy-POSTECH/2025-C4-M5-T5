# Swift 코딩 컨벤션

이 문서는 저장소의 Swift 및 SwiftUI 코드 작성 기준이다. 예시는 의도를 설명하기 위한 것이며, 컴파일 가능한 최신 Swift 문법을 사용한다.

## 1. 기본 형식

- 들여쓰기는 공백 4칸을 사용한다.
- 콜론 왼쪽에는 공백을 두지 않고 오른쪽에는 한 칸을 둔다.
- import는 알파벳순으로 정렬하고 중복을 제거한다.
- 파일명, 타입명, 폴더명은 UpperCamelCase를 사용한다.
- 변수, 프로퍼티, 메서드, enum case는 lowerCamelCase를 사용한다.
- 컴파일러가 명확히 추론할 수 있는 타입은 생략한다. `CGFloat`, `Int64`처럼 의도가 필요한 타입은 명시한다.
- 컬렉션은 `Array<T>`, `Dictionary<K, V>` 대신 `[T]`, `[K: V]`를 사용한다.
- 빈 컬렉션은 타입을 명시한다.

```swift
import Foundation
import SwiftUI

let title = "YUT"
let frameWidth: CGFloat = 120
var photos: [Photo] = []
var metadata: [String: String] = [:]
```

## 2. 네이밍

### 변수와 프로퍼티

- 복수 값을 담는 컬렉션은 의미가 자연스러운 복수형을 사용한다.
- Bool은 상태나 판단이 드러나는 `is`, `has`, `can`, `should` 접두사를 우선한다.
- 축약어보다 역할이 드러나는 이름을 사용한다.

```swift
var categories: [String]
var person: Person
var isShowing: Bool
```

`category: [String]`, `show: Bool`처럼 타입 또는 의미와 맞지 않는 이름은 피한다.

### 함수

- 함수는 동사 원형으로 시작한다.
- 이벤트 콜백은 시점을 드러내는 `will...`, `did...`를 사용한다.
- 사용자 액션은 `tapStartButton()`, `selectDog()`처럼 행위를 구체적으로 표현한다.
- 데이터를 얻는 함수에 모호한 `get`을 사용하지 않는다.
  - `request`: 네트워크처럼 실패 가능한 비동기 요청
  - `fetch`: 로컬 조회처럼 즉시 결과를 제공하거나 실패를 타입으로 명확히 표현하는 조회

```swift
func requestProfile(for user: User) async throws -> Profile
func fetchCachedProfile(for user: User) -> Profile?
func scheduleDidChange()
func didFinishSession()
```

### 타입과 enum

- struct, class, enum, protocol은 UpperCamelCase를 사용한다.
- enum case는 lowerCamelCase를 사용한다.
- 타입명에 임의의 프로젝트 prefix를 붙이지 않는다. 단, 이미 확립된 DesignSystem 공개 타입의 브랜드 prefix는 호환성을 위해 유지할 수 있다.

```swift
enum UploadResult {
    case success
    case failure
}

struct PhotoGrid {
    let photos: [Photo]
}
```

### 프로토콜

- 구조나 역할을 나타내면 명사를 사용한다.
- 능력을 나타내면 `Drivable`, `Persistable` 같은 형용사를 사용한다.
- 관리 책임을 추상화하는 프로토콜은 `Managing` 접미사를 사용한다.

```swift
protocol PetStorageManaging {
    func fetchPetName() -> String?
    func savePetName(_ name: String)
}
```

## 3. 선언 순서와 접근 제어

타입 내부 선언은 다음 순서를 기본으로 한다.

1. nested type
2. property wrapper가 적용된 관찰/상태 프로퍼티
3. 일반 저장 프로퍼티: 상수, 변수 순
4. property observer가 있는 저장 프로퍼티
5. 연산 프로퍼티
6. initializer
7. 생명주기 메서드
8. 공개/internal 메서드
9. private 메서드

- 가능한 가장 좁은 접근 수준을 사용한다.
- 상속 의도가 없는 class는 `final`로 선언한다.
- SwiftUI의 `@State`는 항상 `private`로 선언한다.
- 관련 영역이 길어질 때만 `// MARK: - Section`으로 구분한다.

## 4. 주석과 문서화

- 코드가 무엇을 하는지 그대로 반복하는 주석은 쓰지 않는다.
- 공개 API, 복잡한 알고리즘, 비직관적인 제약에는 `///` 문서 주석을 작성한다.
- 매개변수와 반환값이 의미상 분명하지 않을 때 `- Parameters:`, `- Returns:`, `- Throws:`를 작성한다.
- `TODO`와 `FIXME`에는 해야 할 일과 이유를 구체적으로 남긴다. 이슈가 있으면 번호를 포함한다.
- 실패를 삼키는 용도로 TODO만 남기지 않는다. 사용자 영향이 있는 실패는 상태, throw, 로그 등으로 처리한다.

```swift
/// 사용자 이름과 식별자로 나이를 조회합니다.
/// - Parameters:
///   - id: 사용자 식별자
///   - name: 사용자 전체 이름
/// - Returns: 저장된 사용자 나이
func fetchAge(id: Int, name: String) -> Int? {
    // ...
}
```

## 5. 클로저

- 단일 클로저는 후행 클로저 문법을 사용한다.
- 여러 클로저가 마지막 매개변수들일 때 다중 후행 클로저 문법을 사용한다.
- escaping closure가 객체를 캡처할 때 생명주기를 분석한다.
- 순환 참조 가능성이 있으면 `[weak self]`를 사용하고 nil 경로를 처리한다.
- `unowned`는 캡처된 객체가 클로저보다 반드시 오래 산다는 불변식이 있을 때만 사용한다.

```swift
requestData { result in
    // ...
} onFailure: { error in
    // ...
}
```

## 6. 오류 처리와 동시성

- 실패 조건은 `guard`와 early return으로 정상 흐름을 평평하게 유지한다.
- 복구 가능한 오류를 무시하지 않는다. `throws`, Result, 화면 상태 중 적절한 방법으로 전달한다.
- 비동기 작업은 `async/await`를 우선하며 새 코드에 불필요한 Combine 또는 중첩 DispatchQueue를 추가하지 않는다.
- UI 상태를 소유하는 ViewModel은 메인 액터로 격리한다.
- 취소 가능한 작업은 `Task.isCancelled` 또는 `CancellationError`를 존중한다.

```swift
@MainActor
func tapStartButton() async {
    guard isValidInput else { return }

    do {
        try await petService.save(name: name, type: selectedType)
    } catch {
        errorMessage = error.localizedDescription
    }
}
```

## 7. SwiftUI View

### View 선언

- 화면과 의미 있는 섹션은 `struct: View`로 정의한다.
- 단순히 body를 나누기 위한 계산 프로퍼티 또는 `@ViewBuilder` 함수보다 별도 View 타입을 우선한다.
- 작은 장식 조각이 독립적인 상태나 의미를 갖지 않고 같은 body에서 짧게 반복될 때만 helper를 허용한다.
- 한 View가 여러 중첩 레이아웃과 서로 다른 책임을 갖기 시작하면 섹션 View로 분리한다. “컨테이너 1개”는 절대 규칙이 아니라 분리 필요성을 알리는 리뷰 기준이다.
- 하위 View에는 실제 사용하는 최소 데이터만 전달한다.
- View initializer에서는 I/O, 디코딩, 데이터 조회, 무거운 포맷팅을 하지 않는다.

```swift
struct ArticleListView: View {
    let featuredTitles: [String]
    let articleTitles: [String]

    var body: some View {
        VStack {
            FeaturedArticlesView(titles: featuredTitles)
            AllArticlesView(titles: articleTitles)
        }
    }
}
```

### 상태와 데이터 흐름

- View가 소유하는 값 타입 상태는 `@State private`로 관리한다.
- 부모 상태를 수정하는 자식 View에는 `@Binding`을 전달한다.
- 외부에서 받은 모델을 View가 새로 생성하지 않는다.
- 지원 OS가 iOS 17 이상이면 새 관찰 모델은 Observation의 `@Observable`을 우선한다.
- 기존 `ObservableObject` 코드에서는 소유자가 `@StateObject`, 외부 주입 객체가 `@ObservedObject`임을 구분한다.
- `onChange(of:)`는 현재 SDK의 두 매개변수 또는 매개변수 없는 오버로드를 사용하고, 값 이름을 명확히 한다.

```swift
@MainActor
@Observable
final class PetInfoViewModel {
    var name = ""
    var isError = false

    func updateName(_ newName: String) {
        name = newName
        isError = newName.isEmpty || newName.count > 5
    }
}

struct PetInfoView: View {
    @State private var viewModel = PetInfoViewModel()

    var body: some View {
        TextField("이름", text: $viewModel.name)
            .onChange(of: viewModel.name) { oldValue, newValue in
                viewModel.updateName(newValue)
            }
    }
}
```

### modifier 순서

modifier는 의미 흐름에 따라 배치한다.

1. 콘텐츠와 스타일
2. 크기와 레이아웃
3. 배경과 장식
4. 상호작용과 접근성

- 같은 축의 반복 padding은 가능하면 하나의 `EdgeInsets` 또는 의미 있는 컨테이너로 합친다.
- padding 두 번은 경고 기준이며, 디자인 의도가 명확하면 허용한다.
- `.foregroundStyle`, `.clipShape`, `NavigationStack` 등 현재 API를 우선한다.

## 8. MVVM

- ViewModel 이름은 `[ViewName]ViewModel` 형식을 사용한다.
- ViewModel은 View 타입을 반환하거나 레이아웃을 결정하지 않는다.
- ViewModel의 공개 메서드는 UI 이벤트가 아니라 비즈니스 의도가 드러나게 작성한다.
- 의존성은 initializer로 주입하며 기본값은 조립 지점에서 제공한다.
- 테스트에서 대체할 수 있도록 외부 I/O는 프로토콜 뒤에 둔다.
- 자세한 경계는 `architecture.md`를 따른다.

## 9. 리소스 관리

- 오디오, 카메라, 파일, AR 리소스 관리 타입은 상속 필요가 없으면 `final class`로 선언한다.
- 획득과 해제의 생명주기를 대칭적으로 설계한다. 필요하면 `stop()`, `cancel()`, `releaseResources()` 같은 명시적 API를 제공한다.
- 시스템 API 실패를 빈 catch로 삼키지 않는다.
- delegate 또는 closure가 소유자를 강하게 순환 참조하지 않는지 확인한다.
