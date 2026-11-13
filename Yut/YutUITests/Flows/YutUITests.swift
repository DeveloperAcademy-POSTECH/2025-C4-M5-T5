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
    func testSettingsDocumentsCreatorsAndSupportMenu() {
        let app = XCUIApplication()
        app.launch()
        app.buttons["설정"].tap()
        XCTAssertTrue(app.buttons["이용약관"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["제작자"].exists)
        XCTAssertFalse(app.staticTexts["장성태"].exists)
        capture(app, named: "Settings-Menu")
        app.buttons["제작자"].tap()
        XCTAssertTrue(app.staticTexts["제작자"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["CREATED BY"].exists)
        XCTAssertTrue(app.staticTexts["장성태 · 이윤서 · 소연수"].exists)
        XCTAssertTrue(app.staticTexts["박승은 · 황세연"].exists)
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
        XCTAssertTrue(app.buttons["문의하기"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["준비중"].exists)
        app.buttons["문의하기"].tap()
        XCTAssertTrue(app.wait(for: .runningBackground, timeout: 10))
        app.activate()
        XCTAssertTrue(app.navigationBars["설정"].waitForExistence(timeout: 5))
        app.buttons["뒤로"].tap()
        XCTAssertTrue(app.buttons["방 만들기"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["방 참여하기"].exists)
    }

    @MainActor
    func testMultiplayerLobbyHasNoLocalAdditionAndCanReopen() {
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
            XCTAssertFalse(app.buttons["플레이어 추가"].exists)
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
        XCTAssertFalse(app.buttons["플레이어 추가"].exists)
        app.buttons["방 나가기"].tap()
        app.alerts.buttons["나가기"].tap()
        XCTAssertTrue(app.buttons["방 만들기"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testLocalSlotsToggleWithoutNicknameAndResetAfterLeaving() {
        let app = XCUIApplication()
        app.launch()
        app.buttons["한 기기로 플레이"].tap()
        let first = app.buttons["localPlayerSlot1"]
        XCTAssertTrue(first.waitForExistence(timeout: 5))
        XCTAssertFalse(app.textFields.firstMatch.exists)
        XCTAssertEqual(first.label, "플레이어 1 삭제")
        first.tap()
        XCTAssertEqual(first.label, "플레이어 1 추가")
        XCTAssertFalse(app.buttons["인원 모으는 중..."].isEnabled)
        app.buttons["localPlayerSlot3"].tap()
        XCTAssertTrue(app.buttons["둘이서 윷놀이 시작하기"].isEnabled)
        XCTAssertEqual(app.buttons["localPlayerSlot2"].label, "플레이어 2 삭제")
        app.buttons["localPlayerSlot4"].tap()
        capture(app, named: "LocalPlay-Slots-2-3-4")
        app.buttons["localPlayerSlot3"].tap()
        XCTAssertEqual(app.buttons["localPlayerSlot3"].label, "플레이어 3 추가")
        app.buttons["돌아가기"].tap()
        XCTAssertTrue(app.buttons["한 기기로 플레이"].waitForExistence(timeout: 5))
        app.buttons["한 기기로 플레이"].tap()
        XCTAssertEqual(app.buttons["localPlayerSlot1"].label, "플레이어 1 삭제")
        XCTAssertEqual(app.buttons["localPlayerSlot4"].label, "플레이어 4 추가")
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
        app.buttons["한 기기로 플레이"].tap()
        XCTAssertFalse(app.textFields.firstMatch.exists)
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
        XCTAssertTrue(app.buttons["윷 모으기"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["윷놀이 시작!"].exists)
        XCTAssertFalse(app.buttons["게임 나가기"].exists)
        let placement = XCTAttachment(screenshot: app.screenshot())
        placement.name = "OriginalARBoardConfirmed"
        placement.lifetime = .keepAlways
        add(placement)
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "playerPieceProgress").firstMatch.waitForExistence(timeout: 5))
        let progressFrame = app.descendants(matching: .any).matching(identifier: "playerPieceProgress").firstMatch.frame
        XCTAssertLessThanOrEqual(progressFrame.height, 150)
        XCTAssertLessThan(progressFrame.maxY, app.frame.height * 0.4)
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "대기 중인 말")).firstMatch.exists)
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "완주한 말")).firstMatch.exists)
        XCTAssertFalse(app.staticTexts["이 기기"].exists)
        XCTAssertFalse(app.staticTexts["차례"].exists)
        XCTAssertFalse(app.staticTexts["윷을 모아주세요"].exists)
        let panel = app.descendants(matching: .any).matching(identifier: "playActionPanel").firstMatch
        XCTAssertTrue(panel.waitForExistence(timeout: 5))
        XCTAssertGreaterThan(panel.frame.minY, app.frame.height * 0.5)
        capture(app, named: "AR-PlayerPieceProgress")
        let gather = app.buttons["윷 모으기"]
        XCTAssertTrue(gather.waitForExistence(timeout: 5))
        let actionFrame = gather.frame
        XCTAssertTrue(gather.isEnabled)
        XCTAssertFalse(app.descendants(matching: .any).matching(identifier: "storedResults").firstMatch.exists)
        gather.tap()
        let manualThrow = app.buttons["윷 던지기"]
        XCTAssertTrue(manualThrow.waitForExistence(timeout: 10))
        let hand = XCTAttachment(screenshot: app.screenshot())
        hand.name = "OriginalARHandAndManualFallback"
        hand.lifetime = .keepAlways
        add(hand)
        manualThrow.tap()
        let waiting = app.buttons["윷이 멈출 때까지 기다려주세요"]
        XCTAssertTrue(waiting.waitForExistence(timeout: 5))
        XCTAssertFalse(waiting.isEnabled)
        XCTAssertEqual(waiting.frame.height, actionFrame.height, accuracy: 1)
        XCTAssertEqual(waiting.frame.width, actionFrame.width, accuracy: 1)
        XCTAssertFalse(app.descendants(matching: .any).matching(identifier: "storedResults").firstMatch.exists)
        capture(app, named: "AR-DisabledThrowStatus")
        let completed = NSPredicate { _, _ in
            app.buttons["새 말 놓기"].exists || app.buttons["윷 모으기"].exists
        }
        expectation(for: completed, evaluatedWith: app)
        waitForExpectations(timeout: 30)
        if app.buttons["새 말 놓기"].exists {
            XCTAssertFalse(app.staticTexts["이동할 결과를 선택하세요"].exists)
            XCTAssertFalse(app.staticTexts["움직일 말을 선택하세요"].exists)
            let results = app.descendants(matching: .any).matching(identifier: "storedResults").firstMatch
            XCTAssertTrue(results.exists)
            XCTAssertGreaterThan(results.frame.minY, app.frame.height * 0.5)
            XCTAssertEqual(panel.frame.minY - results.frame.maxY, 12, accuracy: 2)
        }
        let thrown = XCTAttachment(screenshot: app.screenshot())
        thrown.name = "OriginalARThrowCompleted"
        thrown.lifetime = .keepAlways
        add(thrown)
        XCTAssertFalse(app.buttons["게임 나가기"].exists)
    }

}
