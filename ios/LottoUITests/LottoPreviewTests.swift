import XCTest

final class LottoPreviewTests: XCTestCase {
    @MainActor
    func testDrawSaveRestoreAndCompare() {
        let app = XCUIApplication()
        app.launchEnvironment["LOTTO_UI_TEST_RUN"] = UUID().uuidString
        app.launch()
        capture("lotto-first-launch", from: app)
        app.buttons["quick-draw"].tap()
        capture("lotto-orb-launch", from: app)
        let result = app.descendants(matching: .any).matching(identifier: "draw-result").firstMatch
        XCTAssertTrue(result.exists)
        XCTAssertEqual(result.label.split(whereSeparator: { !$0.isNumber }).count, 6)
        Thread.sleep(forTimeInterval: 0.48)
        capture("lotto-orb-result", from: app)

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
        app.buttons["패턴으로 뽑기"].tap()
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
    }

    @MainActor
    private func capture(_ name: String, from app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
