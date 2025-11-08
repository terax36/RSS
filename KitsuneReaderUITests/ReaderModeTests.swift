import XCTest

final class ReaderModeTests: XCTestCase {
    func testSwitchReaderModes() {
        let app = XCUIApplication()
        app.launch()
        app.tabBars.buttons["記事"].tap()
        let segmented = app.segmentedControls
        if segmented.buttons["ウェブ"].waitForExistence(timeout: 2) {
            segmented.buttons["ウェブ"].tap()
            segmented.buttons["リーダー"].tap()
        }
    }
}
