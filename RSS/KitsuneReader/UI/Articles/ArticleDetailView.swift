import CoreData
import SwiftUI

enum ArticleDisplayMode: String, CaseIterable, Identifiable {
    case reader = "リーダー"
    case web = "ウェブ"
    case safari = "Safari"

    var id: String { rawValue }
}

struct ArticleDetailView: View {
    let articleID: NSManagedObjectID
    @EnvironmentObject private var hub: ServiceHub
    @StateObject private var viewModel = ArticleDetailViewModel()

    var body: some View {
        VStack(spacing: 0) {
            header
            switch viewModel.mode {
            case .reader: readerView
            case .web: webView
            case .safari: safariView
            }
            Components.ProgressBar(progress: viewModel.progress)
                .padding(.horizontal)
        }
        #if os(macOS)
        .background(Color(NSColor.windowBackgroundColor))
        #else
        .background(Color(UIColor.systemBackground))
        #endif
        .navigationTitle(viewModel.article?.feed?.title ?? "詳細")
        .toolbar { toolbar }
        .task { await viewModel.bind(hub: hub, articleID: articleID) }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.article?.title ?? "読み込み中...")
                .font(.title3)
                .fontWeight(.semibold)
            HStack {
                if let published = viewModel.article?.publishedAt {
                    Text(published.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Picker("表示", selection: $viewModel.mode) {
                    ForEach(ArticleDisplayMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 240)
            }
        }
        .padding()
    }

    private var readerView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let translated = viewModel.translatedTitle {
                    Text("和訳: \(translated)")
                        .font(.headline)
                        .foregroundStyle(.orange)
                }
                if let html = viewModel.readerHTML {
                    ReaderWebView(html: html,
                                  baseURL: viewModel.articleURL,
                                  css: viewModel.defaultCSS + viewModel.customCSS)
                        .frame(minHeight: 400)
                } else {
                    ProgressView("解析中...")
                }
            }
            .padding()
            .background(GeometryReader { proxy in
                Color.clear.preference(key: ScrollOffsetPreferenceKey.self, value: proxy.frame(in: .named("scroll")).minY)
            })
        }
        .coordinateSpace(name: "scroll")
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
            let normalized = min(1, max(0, 1 - (-value / 600)))
            Task { await viewModel.updateProgress(normalized) }
        }
    }

    private var webView: some View {
        Group {
            if let url = viewModel.articleURL {
                InlineWebView(applyDarkCSS: $viewModel.applyDarkCSS,
                              request: URLRequest(url: url),
                              userCSS: viewModel.defaultCSS + viewModel.customCSS)
            } else {
                Text("URL がありません").foregroundStyle(.secondary)
            }
        }
    }

    private var safariView: some View {
        Group {
            if let url = viewModel.articleURL {
                SafariView(url: url)
            } else {
                Text("URL がありません").foregroundStyle(.secondary)
            }
        }
    }

    private var toolbar: some ToolbarContent {
        #if os(macOS)
        ToolbarItemGroup {
            Button(action: viewModel.toggleRead) {
                Image(systemName: viewModel.article?.isRead == true ? "envelope.open" : "envelope")
            }
            Button(action: viewModel.toggleStar) {
                Image(systemName: viewModel.article?.isStarred == true ? "star.fill" : "star")
            }
            if #available(macOS 13.0, *), let url = viewModel.articleURL {
                ShareLink(item: url) { Image(systemName: "square.and.arrow.up") }
            }
        }
        #else
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            Button(action: viewModel.toggleRead) {
                Image(systemName: viewModel.article?.isRead == true ? "envelope.open" : "envelope")
            }
            Button(action: viewModel.toggleStar) {
                Image(systemName: viewModel.article?.isStarred == true ? "star.fill" : "star")
            }
            if #available(iOS 16.0, *), let url = viewModel.articleURL {
                ShareLink(item: url) { Image(systemName: "square.and.arrow.up") }
            }
        }
        #endif
    }
}

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
