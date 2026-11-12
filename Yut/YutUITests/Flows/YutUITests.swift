//
//  YutUITests.swift
//  YutUITests
//
//  Created by Jay on 7/11/25.
//

import XCTest

final class YutUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    @MainActor
    func testSettingsDocumentsCreatorsAndUnconfiguredSupport() {
        let app = XCUIApplication()
        app.launch()
        app.buttons["설정"].tap()
        XCTAssertTrue(app.buttons["이용약관"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["제작자"].exists)
        XCTAssertFalse(app.staticTexts["장성태"].exists)
        capture(app, named: "Settings-Menu")
        app.buttons["제작자"].tap()
        XCTAssertTrue(app.navigationBars["제작자"].waitForExistence(timeout: 5))
        for name in ["장성태", "이윤서", "박승은", "소연수", "황세연"] {
            XCTAssertTrue(app.staticTexts[name].exists)
        }
        capture(app, named: "Settings-Creators")
        app.buttons["뒤로"].tap()
        XCTAssertTrue(app.buttons["제작자"].waitForExistence(timeout: 5))
        app.buttons["이용약관"].tap()
        XCTAssertTrue(app.staticTexts["제1조 목적 및 적용 범위"].waitForExistence(timeout: 5))
        capture(app, named: "Settings-Terms")
        app.buttons["뒤로"].tap()
        app.buttons["개인정보처리방침"].tap()
        XCTAssertTrue(app.staticTexts["제1조 처리 목적과 범위"].waitForExistence(timeout: 5))
        capture(app, named: "Settings-Privacy")
        app.buttons["뒤로"].tap()
        app.buttons["문의하기"].tap()
        XCTAssertTrue(app.staticTexts["준비중"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["이메일 보내기"].exists)
        XCTAssertFalse(app.buttons["이메일 주소 복사"].exists)
        capture(app, named: "Settings-Support-ComingSoon")
        app.buttons["뒤로"].tap()
        app.buttons["뒤로"].tap()
        XCTAssertTrue(app.buttons["방 만들기"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["방 참여하기"].exists)
    }

    @MainActor
    func testOriginalHostLobbyCanAddPlayerLeaveAndCreateAgain() {
        let app = XCUIApplication()
        app.launch()
        addUIInterruptionMonitor(withDescription: "Local network access") { alert in
            for title in ["허용", "Allow", "확인", "OK"] where alert.buttons[title].exists {
                alert.buttons[title].tap()
                return true
            }
            return false
        }
        for index in 1...2 {
            app.buttons["방 만들기"].tap()
            let name = app.textFields.firstMatch
            XCTAssertTrue(name.waitForExistence(timeout: 5))
            name.tap()
            name.typeText("Host\(index)")
            app.buttons["입력 완료"].tap()
            XCTAssertTrue(app.staticTexts["Host\(index)의 윷놀이방"].waitForExistence(timeout: 10))
            XCTAssertFalse(app.buttons["인원 모으는 중..."].isEnabled)
            app.buttons["플레이어 추가"].firstMatch.tap()
            let friend = app.textFields.firstMatch
            XCTAssertTrue(friend.waitForExistence(timeout: 5))
            friend.tap()
            friend.typeText("Friend")
            app.buttons["추가"].tap()
            XCTAssertTrue(app.staticTexts["Friend"].waitForExistence(timeout: 5))
            XCTAssertTrue(app.buttons["둘이서 윷놀이 시작하기"].isEnabled)
            let capture = XCTAttachment(screenshot: app.screenshot())
            capture.name = "OriginalLobby\(index)"
            capture.lifetime = .keepAlways
            add(capture)
            app.buttons["방 나가기"].tap()
            app.alerts.buttons["나가기"].tap()
            XCTAssertTrue(app.buttons["방 만들기"].waitForExistence(timeout: 5))
        }
    }

    @MainActor
    func testGuestChoosesRoomFromOriginalRoomList() {
        let app = XCUIApplication()
        app.launch()
        app.buttons["방 참여하기"].tap()
        let name = app.textFields.firstMatch
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap()
        name.typeText("Guest")
        app.buttons["입력 완료"].tap()
        XCTAssertTrue(app.staticTexts["주변 윷놀이방 참여하기"].waitForExistence(timeout: 5))
        capture(app, named: "OriginalEmptyRoomList")
        app.buttons["뒤로"].tap()
        XCTAssertTrue(app.staticTexts["닉네임을 입력해주세요"].waitForExistence(timeout: 5))
    }
    @MainActor
    func testNicknameAndLobbyColors() {
        let app = XCUIApplication()
        app.launch()
        capture(app, named: "Theme-Home")
        app.buttons["방 만들기"].tap()
        let nickname = app.textFields.firstMatch
        XCTAssertTrue(nickname.waitForExistence(timeout: 5))
        nickname.tap()
        nickname.typeText("ThemeHost")
        XCTAssertTrue(app.staticTexts["9/10"].waitForExistence(timeout: 5))
        capture(app, named: "Theme-Nickname")
        app.buttons["입력 완료"].tap()
        XCTAssertTrue(app.staticTexts["ThemeHost의 윷놀이방"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["인원 모으는 중..."].isEnabled)
        capture(app, named: "Theme-WaitingDisabled")
        app.buttons["플레이어 추가"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["닉네임을 입력하세요"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["추가"].isEnabled)
        capture(app, named: "Theme-AddDisabled")
        let friend = app.textFields.firstMatch
        friend.tap()
        friend.typeText("Friend")
        XCTAssertTrue(app.buttons["추가"].isEnabled)
        capture(app, named: "Theme-AddEnabled")
        app.buttons["추가"].tap()
        XCTAssertTrue(app.staticTexts["Friend"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["둘이서 윷놀이 시작하기"].isEnabled)
        capture(app, named: "Theme-WaitingEnabled")
        app.buttons["방 나가기"].tap()
        app.alerts.buttons["나가기"].tap()
        XCTAssertTrue(app.buttons["방 만들기"].waitForExistence(timeout: 5))
    }

    @MainActor
    private func capture(_ app: XCUIApplication, named name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testOriginalARPlacementGatheringAndManualThrow() {
        let app = XCUIApplication()
        app.launch()
        app.buttons["방 만들기"].tap()
        let name = app.textFields.firstMatch
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap()
        name.typeText("Host")
        app.buttons["입력 완료"].tap()
        XCTAssertTrue(app.buttons["플레이어 추가"].firstMatch.waitForExistence(timeout: 10))
        app.buttons["플레이어 추가"].firstMatch.tap()
        let friend = app.textFields.firstMatch
        XCTAssertTrue(friend.waitForExistence(timeout: 5))
        friend.tap()
        friend.typeText("Friend")
        app.buttons["추가"].tap()
        let start = app.buttons["둘이서 윷놀이 시작하기"]
        XCTAssertTrue(start.waitForExistence(timeout: 5))
        start.tap()
        let next = app.buttons["다음"]
        if next.waitForExistence(timeout: 15) { next.tap() }
        XCTAssertTrue(app.staticTexts["탭해서 말판을 배치하세요"].waitForExistence(timeout: 10))
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        let confirm = app.buttons["배치하기"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 10))
        confirm.tap()
        let play = app.buttons["윷놀이 시작!"]
        XCTAssertTrue(play.waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["게임 나가기"].exists)
        let placement = XCTAttachment(screenshot: app.screenshot())
        placement.name = "OriginalARBoardConfirmed"
        placement.lifetime = .keepAlways
        add(placement)
        play.tap()
        let gather = app.buttons["윷 모으기"]
        XCTAssertTrue(gather.waitForExistence(timeout: 5))
        gather.tap()
        let manualThrow = app.buttons["윷 던지기"]
        XCTAssertTrue(manualThrow.waitForExistence(timeout: 10))
        let hand = XCTAttachment(screenshot: app.screenshot())
        hand.name = "OriginalARHandAndManualFallback"
        hand.lifetime = .keepAlways
        add(hand)
        manualThrow.tap()
        let completed = NSPredicate { _, _ in
            app.buttons["새 말 놓기"].exists || app.buttons["윷 모으기"].exists
        }
        expectation(for: completed, evaluatedWith: app)
        waitForExpectations(timeout: 30)
        let thrown = XCTAttachment(screenshot: app.screenshot())
        thrown.name = "OriginalARThrowCompleted"
        thrown.lifetime = .keepAlways
        add(thrown)
        XCTAssertFalse(app.buttons["게임 나가기"].exists)
    }

}
