import CoreData
import Foundation
import SwiftSoup

@MainActor
final class SubscriptionService {
    private let persistence: PersistenceController
    private let parser: FeedParserService
    private let fetcher: FeedFetcher
    private let faviconFetcher: FaviconFetcher

    init(persistence: PersistenceController,
         parser: FeedParserService,
         fetcher: FeedFetcher,
         faviconFetcher: FaviconFetcher) {
        self.persistence = persistence
        self.parser = parser
        self.fetcher = fetcher
        self.faviconFetcher = faviconFetcher
    }

    func ensureDefaults() async {
        let context = persistence.viewContext
        let request: NSFetchRequest<Settings> = Settings.fetchRequest()
        if ((try? context.count(for: request)) ?? 0) == 0 {
            let settings = Settings(context: context)
            settings.id = UUID()
            settings.themeMode = "system"
            settings.retentionDays = 30
            settings.markReadOnScrollThreshold = 0.7
            settings.autoTranslateEnglishTitles = false
            settings.cellularImageBlocking = false
            persistence.save()
        }
        let folderRequest: NSFetchRequest<Folder> = Folder.fetchRequest()
        if ((try? context.count(for: folderRequest)) ?? 0) == 0 {
            let folder = Folder(context: context)
            folder.id = UUID()
            folder.name = "未分類"
            folder.sortOrder = 0
            persistence.save()
        }
    }

    func addFeed(from inputURL: URL) async throws -> Feed {
        let feedURL = try await discoverFeedURL(for: inputURL)
        let result = try await fetcher.fetch(url: feedURL)
        guard !result.data.isEmpty else { throw URLError(.badServerResponse) }
        let parsed = try parser.parse(data: result.data, url: feedURL)
        let context = persistence.viewContext
        if let existing = try existingFeed(for: feedURL.absoluteString, context: context) {
            return existing
        }
        let feed = Feed(context: context)
        feed.id = UUID()
        feed.feedURL = feedURL.absoluteString
        feed.siteURL = parsed.siteURL?.absoluteString
        feed.title = parsed.title
        feed.refreshIntervalMin = 60
        feed.etag = result.etag
        feed.lastModified = result.lastModified
        feed.faviconURL = try await faviconFetcher.faviconURL(for: parsed.siteURL ?? feedURL)?.absoluteString
        parsed.articles.forEach { entry in
            let article = Article(context: context)
            article.id = UUID()
            article.feed = feed
            article.feedID = feed.id
            article.guid = entry.guid
            article.title = entry.title
            article.author = entry.author
            article.summary = entry.summary
            article.link = entry.link?.absoluteString
            article.publishedAt = entry.publishedAt
            article.languageCode = entry.languageCode
        }
        persistence.save()
        return feed
    }

    func importOPML(from url: URL) async throws {
        let data = try Data(contentsOf: url)
        guard let xml = String(data: data, encoding: .utf8) else { return }
        let document = try SwiftSoup.parse(xml)
        let outlines = try document.select("outline[type=rss], outline[type=atom]")
        for outline in outlines.array() {
            if let feedURL = try? outline.attr("xmlUrl"), let url = URL(string: feedURL) {
                _ = try? await addFeed(from: url)
            }
        }
    }

    func exportOPML() async {
        let context = persistence.viewContext
        let request: NSFetchRequest<Feed> = Feed.fetchRequest()
        guard let feeds = try? context.fetch(request) else { return }
        var opml = """
        <?xml version=\"1.0\" encoding=\"UTF-8\"?>
        <opml version=\"2.0\">
          <head><title>KitsuneReader Export</title></head>
          <body>
        """
        feeds.forEach { feed in
            opml += """
            <outline text=\"\(feed.title ?? "Feed")\" type=\"rss\" xmlUrl=\"\(feed.feedURL ?? "")\" htmlUrl=\"\(feed.siteURL ?? "")\" />
            """
        }
        opml += """
          </body>
        </opml>
        """
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("KitsuneReader.opml")
        try? opml.write(to: url, atomically: true, encoding: .utf8)
    }

    private func existingFeed(for feedURL: String, context: NSManagedObjectContext) throws -> Feed? {
        let request: NSFetchRequest<Feed> = Feed.fetchRequest()
        request.predicate = NSPredicate(format: "feedURL == %@", feedURL)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    private func discoverFeedURL(for url: URL) async throws -> URL {
        if url.absoluteString.lowercased().hasSuffix(".xml") {
            return url
        }
        let response = try await fetcher.fetch(url: url)
        guard let html = String(data: response.data, encoding: .utf8) else { return url }
        let document = try SwiftSoup.parse(html)
        if let alternate = try document.select("link[rel=alternate][type=application/rss+xml], link[rel=alternate][type=application/atom+xml]").first(),
           let href = try? alternate.attr("href"),
           let candidate = URL(string: href, relativeTo: url) {
            return candidate
        }
        return url
    }
}
