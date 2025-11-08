import Foundation

struct FeedFetchResult {
    let data: Data
    let etag: String?
    let lastModified: Date?
    let statusCode: Int
}

actor FeedFetcher {
    private let client: HTTPClient
    private var etagCache: [URL: String] = [:]
    private var modifiedCache: [URL: Date] = [:]
    private var retryBudget: [URL: Date] = [:]

    init(client: HTTPClient) {
        self.client = client
    }

    func fetch(url: URL) async throws -> FeedFetchResult {
        if let retryDate = retryBudget[url], retryDate > Date() {
            throw URLError(.cannotLoadFromNetwork)
        }
        var headers: [String: String] = [:]
        if let tag = etagCache[url] {
            headers["If-None-Match"] = tag
        }
        if let modified = modifiedCache[url] {
            headers["If-Modified-Since"] = HTTPDate.format(modified)
        }
        let response = try await client.fetch(url: url, headers: headers)
        let http = response.response
        let status = http.statusCode
        if status == 304 {
            return FeedFetchResult(data: Data(), etag: etagCache[url], lastModified: modifiedCache[url], statusCode: status)
        }
        if (500..<600).contains(status) {
            retryBudget[url] = Date(timeIntervalSinceNow: 5 * 60)
        } else {
            retryBudget[url] = nil
        }
        let etag = http.value(forHTTPHeaderField: "Etag")
        let lastModified = http.value(forHTTPHeaderField: "Last-Modified").flatMap(HTTPDate.parse)
        if status == 200 {
            etagCache[url] = etag
            modifiedCache[url] = lastModified
        }
        return FeedFetchResult(data: response.data, etag: etag, lastModified: lastModified, statusCode: status)
    }
}

enum HTTPDate {
    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "EEE',' dd MMM yyyy HH':'mm':'ss z"
        return formatter
    }()

    static func format(_ date: Date) -> String {
        formatter.string(from: date)
    }

    static func parse(_ string: String) -> Date? {
        formatter.date(from: string)
    }
}
