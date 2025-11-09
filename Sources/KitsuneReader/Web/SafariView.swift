import SwiftUI

#if canImport(SafariServices)
import SafariServices
#endif

struct SafariView: View {
    let url: URL
    
    var body: some View {
        #if canImport(SafariServices) && !os(macOS)
        // iOS/macOS (with SafariServices) implementation
        SafariControllerView(url: url)
        #else
        // macOS fallback - use system default browser
        SafariFallbackView(url: url)
        #endif
    }
}

#if canImport(SafariServices) && !os(macOS)
struct SafariControllerView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let controller = SFSafariViewController(url: url)
        controller.preferredControlTintColor = .systemOrange
        return controller
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
#endif

#if os(macOS)
struct SafariFallbackView: View {
    let url: URL
    @State private var opened = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Safari View")
                .font(.title2)
            Text("URL: \(url.absoluteString)")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button("Safariで開く") {
                NSWorkspace.shared.open(url)
            }
        }
        .padding()
    }
}
#endif
