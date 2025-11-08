import SwiftUI

struct SubscriptionsView: View {
    @EnvironmentObject private var hub: ServiceHub
    @EnvironmentObject private var feedVM: FeedViewModel
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Feed.title, ascending: true)])
    private var feeds: FetchedResults<Feed>
    @State private var showAdd = false

    var body: some View {
        List {
            feedSection
        }
        .navigationTitle("購読")
        .toolbar {
            ToolbarItem {
                Button(action: { showAdd = true }) {
                    Label("追加", systemImage: "plus")
                }
            }
            ToolbarItem {
                Button("OPML") { feedVM.exportOPML() }
            }
        }
        .sheet(isPresented: $showAdd) {
            #if os(iOS)
            NavigationStack { AddFeedView().environmentObject(feedVM) }
            #else
            AddFeedView().environmentObject(feedVM)
            #endif
        }
        .task { feedVM.bind(hub: hub) }
    }

    @ViewBuilder
    private var feedSection: some View {
        Section("購読中") {
            ForEach(feeds, id: \.objectID) { feed in
                feedRow(feed)
            }
        }
    }

    @ViewBuilder
    private func feedRow(_ feed: Feed) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(feed.title ?? feed.feedURL ?? "フィード")
                Text(feed.feedURL ?? "")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if feed.isMuted {
                Components.Badge(text: "ミュート", color: .gray)
            }
        }
        .contextMenu {
            Button(feed.isMuted ? "ミュート解除" : "ミュート") { feedVM.toggleMute(feed: feed) }
            Button("削除", role: .destructive) { feedVM.delete(feed: feed) }
        }
    }
}
