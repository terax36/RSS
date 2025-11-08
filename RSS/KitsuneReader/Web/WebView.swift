import SwiftUI

#if os(iOS)
import UIKit
import WebKit
#endif

struct ReaderWebView: View {
    let html: String
    let baseURL: URL?
    let css: String
    
    var body: some View {
        #if os(iOS)
        ReaderWebView_iOS(html: html, baseURL: baseURL, css: css)
        #else
        Text("Webコンテンツはこのプラットフォームでは利用できません")
        #endif
    }
}

struct InlineWebView: View {
    @Binding var applyDarkCSS: Bool
    let request: URLRequest
    let userCSS: String
    
    var body: some View {
        #if os(iOS)
        InlineWebView_iOS(applyDarkCSS: $applyDarkCSS, request: request, userCSS: userCSS)
        #else
        Text("Webコンテンツはこのプラットフォームでは利用できません")
        #endif
    }
}

#if os(iOS)
@MainActor
struct ReaderWebView_iOS: UIViewRepresentable {
    final class Coordinator: NSObject, WKNavigationDelegate {}

    let html: String
    let baseURL: URL?
    let css: String

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.preferences.javaScriptCanOpenWindowsAutomatically = false
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        let view = WKWebView(frame: .zero, configuration: config)
        view.navigationDelegate = context.coordinator
        view.isOpaque = false
        view.scrollView.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        let wrapped = """
        <html><head><meta name='viewport' content='width=device-width, initial-scale=1'>
        <style>body{font-family:-apple-system;}\(css)</style></head>
        <body>\(html)</body></html>
        """
        uiView.loadHTMLString(wrapped, baseURL: baseURL)
    }
}

@MainActor
struct InlineWebView_iOS: UIViewRepresentable {
    final class Coordinator: NSObject, WKNavigationDelegate {}

    @Binding var applyDarkCSS: Bool
    let request: URLRequest
    let userCSS: String

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let controller = WKUserContentController()
        if applyDarkCSS {
            let scriptSource = """
            const style=document.createElement('style');
            style.innerHTML=`\(userCSS)`;
            document.documentElement.appendChild(style);
            """
            controller.addUserScript(WKUserScript(source: scriptSource, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
        }
        config.userContentController = controller
        return WKWebView(frame: .zero, configuration: config)
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.load(request)
    }
}
#endif
