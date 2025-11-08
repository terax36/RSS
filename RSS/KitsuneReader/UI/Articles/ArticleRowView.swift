import SwiftUI
import Nuke

#if os(iOS)
import UIKit
#endif

struct ArticleRowView: View {
    @ObservedObject var article: Article
    let translatedTitle: String?

    var body: some View {
        HStack(spacing: 12) {
            RemoteImageView(url: article.thumbnailURL.flatMap { URL(string: $0) })
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 4) {
                Text(article.title ?? "無題")
                    .fontWeight(article.isRead ? .regular : .semibold)
                if let translatedTitle {
                    Text(translatedTitle)
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
                Text(article.summary ?? "")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                HStack(spacing: 8) {
                    Text(article.feed?.title ?? "フィード")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    if let published = article.publishedAt {
                        Text(published, style: .relative)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    if article.isStarred {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption2)
                    }
                }
            }
        }
        .padding(.vertical, 6)
    }
}

struct RemoteImageView: View {
    let url: URL?
    #if os(macOS)
    @State private var image: NSImage?
    #else
    @State private var image: UIImage?
    #endif
    private let pipeline = ImagePipeline.shared

    var body: some View {
        ZStack {
            if let image {
                #if os(macOS)
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                #else
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                #endif
            } else {
                RoundedRectangle(cornerRadius: 8).fill(.secondary.opacity(0.2))
                    .overlay(Image(systemName: "photo").foregroundStyle(.secondary))
            }
        }
        .task(id: url) {
            guard let url else { return }
            if let (data, _) = try? await pipeline.data(for: ImageRequest(url: url)) {
                await MainActor.run {
                    #if os(macOS)
                    image = NSImage(data: data)
                    #else
                    image = UIImage(data: data)
                    #endif
                }
            }
        }
    }
}
