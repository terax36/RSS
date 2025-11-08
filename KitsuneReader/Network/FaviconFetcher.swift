import Foundation
import SwiftSoup

actor FaviconFetcher {
    private let client: HTTPClient
    private var cache: [URL: URL] = [:]

    init(client: HTTPClient) {
        self.client = client
    }

    func faviconURL(for site: URL) async -> URL? {
        if let cached = cache[site] { return cached }
        let icoURL = site.appendingPathComponent("favicon.ico")
        if let head = try? await client.fetch(url: icoURL), head.response.statusCode == 200 {
            cache[site] = icoURL
            return icoURL
        }
        guard let html = try? await client.fetch(url: site).data,
              let document = try? SwiftSoup.parse(String(data: html, encoding: .utf8) ?? "", site.absoluteString),
              let link = try? document.select("link[rel~=icon]").first(),
              let href = try? link.attr("href"),
              let url = URL(string: href, relativeTo: site) else {
            return nil
        }
        cache[site] = url
        return url
    }
}
