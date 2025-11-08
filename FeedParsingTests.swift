import XCTest
@testable import KitsuneReader

final class FeedParsingTests: XCTestCase {
    func testParseRSS() throws {
        let feedXML = """
        <?xml version=\"1.0\"?>
        <rss version=\"2.0\">
          <channel>
            <title>テストフィード</title>
            <link>https://example.com</link>
            <item>
              <title>記事1</title>
              <link>https://example.com/a</link>
              <guid>1</guid>
            </item>
          </channel>
        </rss>
        """.data(using: .utf8)!
        let parser = FeedParserService()
        let parsed = try parser.parse(data: feedXML, url: URL(string: "https://example.com/feed")!)
        XCTAssertEqual(parsed.title, "テストフィード")
        XCTAssertEqual(parsed.articles.count, 1)
        XCTAssertEqual(parsed.articles.first?.guid, "1")
    }
}
