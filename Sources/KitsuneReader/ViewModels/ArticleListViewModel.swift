import CoreData
import Foundation
import SwiftUI

enum ArticleFilter: Hashable {
    case all
    case unread
    case starred
    case today
    case feed(NSManagedObjectID)
}

@MainActor
final class ArticleListViewModel: ObservableObject {
    @Published var articles: [Article] = []
    @Published var searchText: String = ""
    @Published var filter: ArticleFilter = .all
    private weak var hub: ServiceHub?
    private var context: NSManagedObjectContext?
    private var searchTask: Task<Void, Never>?

    func bind(hub: ServiceHub, filter: ArticleFilter) {
        self.hub = hub
        self.filter = filter
        self.context = hub.persistence.viewContext
        Task { await load() }
    }

    func load() async {
        guard let context else { return }
        let request: NSFetchRequest<Article> = Article.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Article.publishedAt, ascending: false)]
        switch filter {
        case .all: request.predicate = nil
        case .unread: request.predicate = NSPredicate(format: "isRead == NO")
        case .starred: request.predicate = NSPredicate(format: "isStarred == YES")
        case .today:
            let start = Calendar.current.startOfDay(for: Date())
            request.predicate = NSPredicate(format: "publishedAt >= %@", start as NSDate)
        case .feed(let objectID):
            if let feed = try? context.existingObject(with: objectID) as? Feed {
                request.predicate = NSPredicate(format: "feed == %@", feed)
            }
        }
        let fetched = (try? context.fetch(request)) ?? []
        articles = fetched
        if hub?.settings.autoTranslateEnglishTitles == true {
            Task { [weak self] in
                await self?.translateArticles(fetched)
            }
        }
    }

    func refresh() async {
        try? await hub?.articleService.refreshAllFeeds()
        await load()
    }

    func toggleStar(_ article: Article) {
        article.isStarred.toggle()
        hub?.persistence.save()
        Task { await load() }
    }

    func toggleRead(_ article: Article) {
        article.isRead.toggle()
        hub?.persistence.save()
        Task { await load() }
    }

    func delete(_ article: Article) {
        context?.delete(article)
        hub?.persistence.save()
        Task { await load() }
    }

    func translatedTitle(for article: Article) -> String? {
        article.translatedTitle
    }

    func search(text: String) {
        searchTask?.cancel()
        if text.isEmpty {
            searchTask = Task { [weak self] in await self?.load() }
            return
        }
        searchTask = Task { [weak self] in
            await self?.performSearch(text: text)
        }
    }

    private func performSearch(text: String) async {
        guard let context else { return }
        guard let hub else { return }
        let results = hub.searchService.search(text: text, context: context)
        articles = results
    }

    private func translateArticles(_ fetched: [Article]) async {
        guard let hub, hub.settings.autoTranslateEnglishTitles else { return }
        for article in fetched where article.languageCode == "en" && article.translatedTitle == nil {
            await hub.articleService.translateTitleIfNeeded(articleID: article.objectID, autoTranslate: true)
        }
    }
}
