import XCTest
@testable import KitsuneReader

final class TranslationTests: XCTestCase {
    func testDictionaryTranslation() async throws {
        let translator = await TranslationCoordinator()
        let output = try await translator.translate("Hello world", from: Locale(identifier: "en"), to: Locale(identifier: "ja"))
        XCTAssertTrue(output.contains("こんにちは"))
        let cached = try await translator.translate("Hello world", from: Locale(identifier: "en"), to: Locale(identifier: "ja"))
        XCTAssertEqual(output, cached)
    }
}
