import CoreData
import Foundation

@MainActor
final class RuleService {
    private let persistence: PersistenceController

    init(persistence: PersistenceController) {
        self.persistence = persistence
    }

    func ensureDefaults() async {
        let context = persistence.viewContext
        let request: NSFetchRequest<Rule> = Rule.fetchRequest()
        if ((try? context.count(for: request)) ?? 0) == 0 {
            let rule = Rule(context: context)
            rule.id = UUID()
            rule.pattern = "Sponsored"
            rule.isRegex = false
            rule.actionHide = true
            persistence.save()
        }
    }

    func shouldHide(article: Article) -> Bool {
        guard let title = article.title else { return false }
        let context = persistence.viewContext
        let request: NSFetchRequest<Rule> = Rule.fetchRequest()
        guard let rules = try? context.fetch(request) else { return false }
        for rule in rules {
            let pattern = rule.pattern
            if rule.isRegex {
                if let regex = try? NSRegularExpression(pattern: pattern),
                   regex.firstMatch(in: title, range: NSRange(location: 0, length: title.utf16.count)) != nil {
                    return true
                }
            } else if title.localizedCaseInsensitiveContains(pattern) {
                return true
            }
        }
        return false
    }
}
