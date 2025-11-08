import Foundation
import FeedKit

struct ParsedArticle {
    let guid: String
    let title: String
    let author: String?
    let link: URL?
    let publishedAt: Date?
    let updatedAt: Date?
    let summary: String?
    let content: String?
    let languageCode: String?
}

struct ParsedFeed {
    let title: String
    let siteURL: URL?
    let articles: [ParsedArticle]
}

struct FeedParserService {
    func parse(data: Data, url: URL) throws -> ParsedFeed {
        let feed = try FeedKit.Feed(data: data)
        switch feed {
        case .atom(let atomFeed):
            return parseAtom(atomFeed, fallbackURL: url)
        case .rss(let rssFeed):
            return parseRSS(rssFeed, fallbackURL: url)
        case .json:
            throw NSError(domain: "FeedParserService", code: 1, userInfo: [NSLocalizedDescriptionKey: "JSON Feed は未対応です"])
        }
    }

    private func parseAtom(_ feed: AtomFeed, fallbackURL: URL) -> ParsedFeed {
        let siteURL = feed.links?.compactMap { $0.attributes?.href }.first.flatMap { URL(string: $0) }
        let title = feed.title?.text ?? fallbackURL.host ?? "フィード"
        let articles = (feed.entries ?? []).compactMap { mapAtomEntry($0) }
        return ParsedFeed(title: title, siteURL: siteURL, articles: articles)
    }

    private func mapAtomEntry(_ entry: AtomFeedEntry) -> ParsedArticle? {
        let link = entry.links?.compactMap { $0.attributes?.href }.first.flatMap { URL(string: $0) }
        let guid = entry.id ?? link?.absoluteString ?? UUID().uuidString
        let contentText = entry.content?.text ?? entry.summary?.text
        return ParsedArticle(
            guid: guid,
            title: entry.title ?? "無題",
            author: entry.authors?.first?.name,
            link: link,
            publishedAt: entry.published ?? entry.updated,
            updatedAt: entry.updated,
            summary: entry.summary?.text,
            content: contentText,
            languageCode: entry.dublinCore?.language
        )
    }

    private func parseRSS(_ feed: RSSFeed, fallbackURL: URL) -> ParsedFeed {
        let channel = feed.channel
        let siteURL = channel?.link.flatMap { URL(string: $0) }
        let title = channel?.title ?? siteURL?.host ?? fallbackURL.host ?? "フィード"
        let articles = (channel?.items ?? []).compactMap { mapRSSItem($0, defaultLanguage: channel?.language) }
        return ParsedFeed(title: title, siteURL: siteURL, articles: articles)
    }

    private func mapRSSItem(_ item: RSSFeedItem, defaultLanguage: String?) -> ParsedArticle? {
        let link = item.link.flatMap { URL(string: $0) }
        let guid = item.guid?.text ?? link?.absoluteString ?? UUID().uuidString
        return ParsedArticle(
            guid: guid,
            title: item.title ?? "無題",
            author: item.author ?? item.dublinCore?.creator,
            link: link,
            publishedAt: item.pubDate,
            updatedAt: item.pubDate,
            summary: item.description ?? item.content?.encoded,
            content: item.content?.encoded,
            languageCode: item.dublinCore?.language ?? defaultLanguage
        )
    }
}
