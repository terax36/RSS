import CoreData
import SwiftUI

struct SidebarView: View {
    @EnvironmentObject private var feedVM: FeedViewModel
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Folder.sortOrder, ascending: true)])
    private var folders: FetchedResults<Folder>

    var body: some View {
        List {
            smartSection
            folderSection
        }
        .navigationTitle("KitsuneReader")
    }

    private var smartSection: some View {
        Section("スマート") {
            selectionRow(title: "すべて", systemImage: "tray.full", selection: .all)
            selectionRow(title: "未読", systemImage: "envelope.badge", selection: .unread)
            selectionRow(title: "スター", systemImage: "star", selection: .starred)
            selectionRow(title: "今日", systemImage: "sun.max", selection: .today)
        }
    }

    private var folderSection: some View {
        Section("フォルダ") {
            ForEach(folders, id: \.objectID) { folder in
                DisclosureGroup(folder.name ?? "フォルダ") {
                    folderFeeds(folder)
                }
            }
        }
    }

    @ViewBuilder
    private func folderFeeds(_ folder: Folder) -> some View {
        let folderFeeds = folder.feeds?.sorted { lhs, rhs in
            lhs.title ?? "" < rhs.title ?? ""
        } ?? []
        ForEach(folderFeeds, id: \.objectID) { feed in
            selectionRow(title: feed.title ?? "フィード",
                         systemImage: "dot.radiowaves.left.and.right",
                         selection: .feed(feed.objectID))
        }
    }

    @ViewBuilder
    private func selectionRow(title: String, systemImage: String, selection: FeedSelection) -> some View {
        HStack {
            Label(title, systemImage: systemImage)
            Spacer()
            if feedVM.selection == selection {
                Image(systemName: "checkmark")
                    .foregroundColor(.accentColor)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { feedVM.selection = selection }
    }
}
