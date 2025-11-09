import CoreData
import Foundation

@MainActor
final class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    var viewContext: NSManagedObjectContext { container.viewContext }

    init(inMemory: Bool = false) {
        guard let modelURL = Bundle.main.url(forResource: "KitsuneReader", withExtension: "momd"),
              let model = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Core Data モデルを読み込めませんでした")
        }
        container = NSPersistentContainer(name: "KitsuneReader", managedObjectModel: model)
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.persistentStoreDescriptions.forEach { description in
            description.shouldInferMappingModelAutomatically = true
            description.shouldMigrateStoreAutomatically = true
        }
        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Core Data ストアの初期化に失敗: \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
    }

    func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.automaticallyMergesChangesFromParent = true
        context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        return context
    }

    func save(context: NSManagedObjectContext? = nil) {
        let context = context ?? viewContext
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            context.rollback()
            debugPrint("保存失敗", error)
        }
    }
}
