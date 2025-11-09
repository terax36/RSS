import XCTest

final class TranslationToggleTests: XCTestCase {
    func testToggleAutoTranslate() {
        let app = XCUIApplication()
        app.launch()
        app.tabBars.buttons["設定"].tap()
        let toggle = app.switches["英語タイトルを自動翻訳"]
        if toggle.waitForExistence(timeout: 2) {
            toggle.tap()
            toggle.tap()
        }
    }
}
