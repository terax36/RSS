import CoreData
import SwiftUI

struct ArticleListView: View {
    @EnvironmentObject private var hub: ServiceHub
    @EnvironmentObject private var feedVM: FeedViewModel
    @StateObject private var viewModel = ArticleListViewModel()
    let filter: FeedSelection

    var body: some View {
        List {
            ForEach(viewModel.articles) { article in
                NavigationLink {
                    ArticleDetailView(articleID: article.objectID)
                } label: {
                    ArticleRowView(article: article,
                                   translatedTitle: viewModel.translatedTitle(for: article))
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button {
                        viewModel.toggleStar(article)
                    } label: {
                        Label("スター", systemImage: article.isStarred ? "star.slash" : "star.fill")
                    }.tint(.yellow)
                }
                .swipeActions(edge: .trailing) {
                    Button {
                        viewModel.toggleRead(article)
                    } label: {
                        Label(article.isRead ? "未読" : "既読", systemImage: "envelope")
                    }.tint(.blue)
                }
                .contextMenu {
                    Button("削除", role: .destructive) { viewModel.delete(article) }
                    if let link = article.link.flatMap({ URL(string: $0) }) {
                        if #available(iOS 16.0, macOS 13.0, *) {
                            ShareLink(item: link) { Text("共有") }
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle(title)
        #if os(iOS)
        .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer)
        #else
        .searchable(text: $viewModel.searchText)
        #endif
        .onChange(of: viewModel.searchText) { text in
            viewModel.search(text: text)
        }
        .refreshable { await viewModel.refresh() }
        .task { viewModel.bind(hub: hub, filter: articleFilter) }
    }

    private var title: String {
        switch filter {
        case .all: return "すべての記事"
        case .unread: return "未読"
        case .starred: return "スター"
        case .today: return "今日"
        case .feed(let objectID):
            if let feed = try? hub.persistence.viewContext.existingObject(with: objectID) as? Feed {
                return feed.title ?? "フィード"
            }
            return "フィード"
        }
    }

    private var articleFilter: ArticleFilter {
        switch filter {
        case .all: return .all
        case .unread: return .unread
        case .starred: return .starred
        case .today: return .today
        case .feed(let objectID): return .feed(objectID)
        }
    }
}
