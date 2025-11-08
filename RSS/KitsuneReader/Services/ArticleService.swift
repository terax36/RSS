@preconcurrency import CoreData
import Foundation

@MainActor
final class ArticleService {
    private let persistence: PersistenceController
    private let readability: Readability
    private let sanitizer: HTMLSanitizer
    private let fetcher: FeedFetcher
    private let translation: TranslationService

    init(persistence: PersistenceController,
         readability: Readability,
         sanitizer: HTMLSanitizer,
         fetcher: FeedFetcher,
         translation: TranslationService) {
        self.persistence = persistence
        self.readability = readability
        self.sanitizer = sanitizer
        self.fetcher = fetcher
        self.translation = translation
    }

    func refreshAllFeeds() async throws {
        let context = persistence.viewContext
        let request: NSFetchRequest<Feed> = Feed.fetchRequest()
        let feeds = (try? context.fetch(request)) ?? []
        try await withThrowingTaskGroup(of: Void.self) { group in
            for feed in feeds where !feed.isMuted {
                let objectID = feed.objectID
                group.addTask { [weak self] in
                    try await self?.refreshFeed(objectID: objectID)
                }
            }
            try await group.waitForAll()
        }
    }

    private func refreshFeed(objectID: NSManagedObjectID) async throws {
        let context = persistence.newBackgroundContext()
        var feedURL: URL?
        context.performAndWait {
            if let feed = try? context.existingObject(with: objectID) as? Feed,
               let urlString = feed.feedURL,
               let url = URL(string: urlString) {
                feedURL = url
            }
        }
        guard let url = feedURL else { return }
        let result = try await fetcher.fetch(url: url)
        guard result.statusCode != 304 else { return }
        let parsed = try parser().parse(data: result.data, url: url)
        context.performAndWait {
            guard let feed = try? context.existingObject(with: objectID) as? Feed else { return }
            feed.title = feed.title ?? parsed.title
            feed.etag = result.etag
            feed.lastModified = result.lastModified
            for entry in parsed.articles {
                if (try? existsArticle(guid: entry.guid, context: context)) == true { continue }
                let article = Article(context: context)
                article.id = UUID()
                article.feed = feed
                article.feedID = feed.id
                article.guid = entry.guid
                article.title = entry.title
                article.author = entry.author
                article.link = entry.link?.absoluteString
                article.publishedAt = entry.publishedAt
                article.updatedAt = entry.updatedAt
                article.summary = entry.summary
                article.languageCode = entry.languageCode
                article.isRead = false
                article.isStarred = false
                if let html = entry.content ?? entry.summary {
                    cacheReadability(html: html, link: entry.link, for: article)
                }
            }
            do { try context.save() } catch { context.rollback() }
        }
    }

    private func existsArticle(guid: String, context: NSManagedObjectContext) throws -> Bool {
        let request: NSFetchRequest<Article> = Article.fetchRequest()
        request.predicate = NSPredicate(format: "guid == %@", guid)
        request.fetchLimit = 1
        return try context.count(for: request) > 0
    }

    private func cacheReadability(html: String, link: URL?, for article: Article) {
        let result = readability.parse(html: html, url: link)
        let content = ArticleContent(context: article.managedObjectContext!)
        content.article = article
        content.readabilityHTML = sanitizer.sanitize(result.html)
        content.textPlain = result.text
        content.wordCount = Int32(result.wordCount)
        content.readingTimeSec = Int32(result.readingTime)
        article.content = content
        article.contentCached = true
    }

    func translateTitleIfNeeded(articleID: NSManagedObjectID, autoTranslate: Bool) async {
        guard autoTranslate else { return }
        let context = persistence.viewContext
        guard let article = try? context.existingObject(with: articleID) as? Article else { return }
        guard article.languageCode == "en", article.translatedTitle == nil,
              let title = article.title else { return }
        do {
            let translated = try await translation.translate(title, from: Locale(identifier: "en"), to: Locale(identifier: "ja"))
            article.translatedTitle = translated
            persistence.save(context: context)
        } catch {
            print("翻訳失敗", error)
        }
    }

    func compactIfNeeded(retentionDays: Int) async {
        let context = persistence.viewContext
        let request: NSFetchRequest<Article> = Article.fetchRequest()
        let cutoff = Date().addingTimeInterval(Double(-retentionDays) * 24 * 60 * 60)
        request.predicate = NSPredicate(format: "publishedAt < %@ AND isStarred == NO", cutoff as NSDate)
        if let stale = try? context.fetch(request) {
            stale.forEach { context.delete($0) }
            persistence.save(context: context)
        }
    }

    private func parser() -> FeedParserService { FeedParserService() }
}
