import CoreData
import Foundation
import SwiftUI

enum FeedSelection: Hashable {
    case all
    case unread
    case starred
    case today
    case feed(NSManagedObjectID)
}

@MainActor
final class FeedViewModel: ObservableObject {
    @Published var selection: FeedSelection = .all
    @Published private(set) var feeds: [Feed] = []
    private var context: NSManagedObjectContext?
    private weak var hub: ServiceHub?

    func bind(hub: ServiceHub) {
        self.hub = hub
        self.context = hub.persistence.viewContext
        Task { await reload() }
    }

    func reload() async {
        guard let context else { return }
        let request: NSFetchRequest<Feed> = Feed.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Feed.title, ascending: true)]
        feeds = (try? context.fetch(request)) ?? []
    }

    func addFeed(url: URL) async throws {
        guard let hub else { return }
        _ = try await hub.subscriptionService.addFeed(from: url)
        await reload()
    }

    func toggleMute(feed: Feed) {
        feed.isMuted.toggle()
        hub?.persistence.save()
        Task { await reload() }
    }

    func delete(feed: Feed) {
        context?.delete(feed)
        hub?.persistence.save()
        Task { await reload() }
    }

    func move(feed: Feed, to folder: Folder) {
        feed.folders = Set([folder])
        hub?.persistence.save()
    }

    func exportOPML() {
        Task { await hub?.subscriptionService.exportOPML() }
    }
}
