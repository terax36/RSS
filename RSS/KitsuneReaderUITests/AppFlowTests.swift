import XCTest

final class AppFlowTests: XCTestCase {
    func testLaunchShowsTabs() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["記事"].exists)
        app.tabBars.buttons["購読"].tap()
        XCTAssertTrue(app.navigationBars["購読"].exists)
    }
}
