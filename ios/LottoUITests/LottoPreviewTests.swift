import XCTest

final class LottoPreviewTests: XCTestCase {
    @MainActor
    func testDrawSaveRestoreAndCompare() {
        let app = XCUIApplication()
        app.launchEnvironment["LOTTO_UI_TEST_RUN"] = UUID().uuidString
        app.launch()
        capture("lotto-first-launch", from: app)
        let result = app.descendants(matching: .any).matching(identifier: "draw-result").firstMatch
        let orb = app.buttons["quick-pull"]
        XCTAssertTrue(orb.exists)
        pull(orb, distance: 27, hold: 0.10)
        XCTAssertFalse(result.exists)
        pull(orb, distance: 93, hold: 0.28)
        capture("lotto-pull-cutscene", from: app)
        XCTAssertTrue(result.exists)
        XCTAssertEqual(result.label.split(whereSeparator: { !$0.isNumber }).count, 6)
        Thread.sleep(forTimeInterval: 0.48)
        capture("lotto-pull-number-orbs", from: app)
        Thread.sleep(forTimeInterval: 1.05)
        capture("lotto-pull-result", from: app)

        app.buttons["내 번호에 저장"].tap()
        XCTAssertTrue(app.buttons["저장됨"].exists)
        app.terminate()
        app.launch()
        app.buttons["내 번호"].tap()
        XCTAssertTrue(app.buttons["역대 회차 비교"].exists)

        app.buttons["번호 직접 추가"].tap()
        for number in [3, 11, 19, 24, 32, 41] {
            app.buttons["\(number)번"].tap()
        }
        app.buttons["조합 저장"].tap()
        let comparisons = app.buttons.matching(identifier: "역대 회차 비교")
        comparisons.element(boundBy: comparisons.count - 1).tap()
        XCTAssertTrue(app.staticTexts["전체에서 2회 · 가장 최근 268회"].exists)
        capture("lotto-comparison", from: app)
        app.buttons["닮은 회차"].tap()
        XCTAssertTrue(app.staticTexts["268회"].exists)
        capture("lotto-matching-rounds", from: app)
        app.buttons["번호별"].tap()
        XCTAssertTrue(app.staticTexts["내 번호가 나온 횟수"].exists)
        app.buttons["번호 쌍"].tap()
        XCTAssertTrue(app.staticTexts["같은 회차에 함께 나온 번호"].exists)
        app.buttons["닫기"].tap()

        app.buttons["역대 통계"].tap()
        XCTAssertTrue(app.staticTexts["1~1251회 이력"].exists)
        pull(app.buttons["pattern-pull"], distance: 78, hold: 0.12)
        let pattern = app.descendants(matching: .any).matching(identifier: "pattern-result").firstMatch
        XCTAssertTrue(pattern.exists)
        XCTAssertEqual(pattern.label.split(whereSeparator: { !$0.isNumber }).count, 6)
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label BEGINSWITH %@", "이 구성은 역대")).firstMatch.exists)
        XCTAssertTrue(app.buttons["저장"].exists)
        // This capture shows the result card after the cutscene has cleared.
        Thread.sleep(forTimeInterval: 1.62)
        capture("lotto-pattern-result", from: app)
        app.swipeUp()
        XCTAssertTrue(app.staticTexts["역대 조합 뜯어보기"].exists)
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "416회")).firstMatch.exists)
        capture("lotto-pattern-distribution", from: app)
        app.terminate()
        app.launch()
        app.buttons["quick-draw"].tap()
        XCTAssertTrue(result.exists)
    }

    @MainActor
    private func pull(_ orb: XCUIElement, distance: CGFloat, hold: TimeInterval) {
        let start = orb.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let end = start.withOffset(CGVector(dx: 0, dy: distance))
        start.press(forDuration: 0.08, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: hold)
    }

    @MainActor
    private func capture(_ name: String, from app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
