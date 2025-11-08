import CoreData
import Foundation

@MainActor
final class SearchService {
    private let persistence: PersistenceController

    init(persistence: PersistenceController) {
        self.persistence = persistence
    }

    func search(text: String, context: NSManagedObjectContext) -> [Article] {
        let request: NSFetchRequest<Article> = Article.fetchRequest()
        request.predicate = NSPredicate(format: "title CONTAINS[cd] %@ OR summary CONTAINS[cd] %@", text, text)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Article.publishedAt, ascending: false)]
        request.fetchLimit = 200
        return (try? context.fetch(request)) ?? []
    }
}
