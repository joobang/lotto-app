import XCTest

final class LottoPreviewTests: XCTestCase {
    @MainActor
    func testDrawSaveRestoreAndCompare() {
        let app = XCUIApplication()
        app.launchEnvironment["LOTTO_UI_TEST_RUN"] = UUID().uuidString
        app.launch()
        capture("lotto-first-launch", from: app)
        app.buttons["quick-draw"].tap()
        let result = app.descendants(matching: .any).matching(identifier: "draw-result").firstMatch
        XCTAssertTrue(result.exists)
        capture("lotto-draw", from: app)

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
        app.buttons["통계로 뽑기"].tap()
        XCTAssertTrue(app.buttons["저장"].exists)
        XCTAssertTrue(app.staticTexts["45개 번호의 출현 횟수"].exists)
        capture("lotto-stats", from: app)
    }

    @MainActor
    private func capture(_ name: String, from app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
