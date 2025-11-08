import XCTest
@testable import KitsuneReader

final class ReadabilityTests: XCTestCase {
    func testReadabilityExtractsBody() throws {
        let testDir = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        let htmlURL = testDir.appendingPathComponent("../KitsuneReader/Samples/sample.html").standardizedFileURL
        let html = try String(contentsOf: htmlURL)
        let result = Readability().parse(html: html, url: nil)
        XCTAssertTrue(result.text.contains("RSS"))
        XCTAssertGreaterThan(result.wordCount, 5)
    }
}
