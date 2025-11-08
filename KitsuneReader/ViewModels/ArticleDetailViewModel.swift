import Combine
import CoreData
import Foundation
import SwiftUI

@MainActor
final class ArticleDetailViewModel: ObservableObject {
    @Published private(set) var article: Article?
    @Published var readerHTML: String?
    @Published var mode: ArticleDisplayMode = .reader
    @Published var progress: Double = 0
    @Published var translatedTitle: String?
    @Published var applyDarkCSS: Bool = true

    var articleURL: URL? { article?.link.flatMap { URL(string: $0) } }
    var customCSS: String { (article?.feed?.customCSS ?? "") }
    var defaultCSS: String {
        guard let url = Bundle.main.url(forResource: "DarkCSSDefaults", withExtension: "css"),
              let css = try? String(contentsOf: url) else {
            return ""
        }
        return css
    }

    private weak var hub: ServiceHub?
    private var articleID: NSManagedObjectID?

    func bind(hub: ServiceHub, articleID: NSManagedObjectID) async {
        self.hub = hub
        self.articleID = articleID
        let context = hub.persistence.viewContext
        article = try? context.existingObject(with: articleID) as? Article
        readerHTML = article?.content?.readabilityHTML ?? article?.summary
        translatedTitle = article?.translatedTitle
        if hub.settings.autoTranslateEnglishTitles {
            await hub.articleService.translateTitleIfNeeded(articleID: articleID, autoTranslate: true)
            article = try? context.existingObject(with: articleID) as? Article
            translatedTitle = article?.translatedTitle
        }
    }

    func toggleRead() {
        guard let article else { return }
        article.isRead.toggle()
        hub?.persistence.save()
        objectWillChange.send()
    }

    func toggleStar() {
        guard let article else { return }
        article.isStarred.toggle()
        hub?.persistence.save()
        objectWillChange.send()
    }

    func updateProgress(_ value: Double) {
        progress = value
        guard let article, !article.isRead else { return }
        if value >= hub?.settings.markReadThreshold ?? 0.7 {
            article.isRead = true
            hub?.persistence.save()
        }
    }
}
