import SwiftUI

@available(macOS 13.0, *)
struct TabRootView: View {
    @EnvironmentObject private var hub: ServiceHub
    @StateObject private var feedVM = FeedViewModel()
    
    var body: some View {
        GeometryReader { proxy in
            if proxy.size.width > 700 {
                NavigationSplitView {
                    SidebarView()
                } content: {
                    ArticleListView(filter: feedVM.selection)
                } detail: {
                    Text("記事を選択してください").foregroundStyle(.secondary)
                }
            } else {
                TabView {
                    NavigationStack {
                        ArticleListView(filter: .all)
                    }
                    .tabItem { Label("記事", systemImage: "list.bullet.rectangle") }
                    
                    NavigationStack {
                        SubscriptionsView()
                    }
                    .tabItem { Label("購読", systemImage: "text.badge.plus") }
                    
                    NavigationStack {
                        ArticleListView(filter: .starred)
                    }
                    .tabItem { Label("スター", systemImage: "star.fill") }
                    
                    NavigationStack {
                        SettingsView()
                    }
                    .tabItem { Label("設定", systemImage: "gear") }
                }
            }
        }
        .environmentObject(feedVM)
        .task {
            feedVM.bind(hub: hub)
        }
    }
}

// macOS 12.0 以前のバージョン用のフォールバック実装
struct TabRootViewMac12: View {
    @EnvironmentObject private var hub: ServiceHub
    @StateObject private var feedVM = FeedViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ArticleListView(filter: .all)
                .tabItem { Label("記事", systemImage: "list.bullet.rectangle") }
                .tag(0)
            
            SubscriptionsView()
                .tabItem { Label("購読", systemImage: "text.badge.plus") }
                .tag(1)
            
            ArticleListView(filter: .starred)
                .tabItem { Label("スター", systemImage: "star.fill") }
                .tag(2)
            
            SettingsView()
                .tabItem { Label("設定", systemImage: "gear") }
                .tag(3)
        }
        .environmentObject(feedVM)
        .task {
            feedVM.bind(hub: hub)
        }
    }
}
