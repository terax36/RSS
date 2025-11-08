import Foundation
import SwiftSoup

struct ReadabilityResult {
    let title: String
    let byline: String?
    let html: String
    let text: String
    let wordCount: Int
    let readingTime: Int
}

final class Readability {
    func parse(html: String, url: URL?) -> ReadabilityResult {
        do {
            let document = try SwiftSoup.parse(html, url?.absoluteString ?? "")
            try removeNoise(from: document)
            guard let body = document.body() else {
                return fallback(html: html, title: try? document.title())
            }
            let originalBodyText = (try? body.text()) ?? ""
            let best = pickBestCandidate(in: body)
            let sanitized = try sanitize(best)
            let sanitizedText = try sanitized.text()
            let text = [sanitizedText, originalBodyText]
                .filter { !$0.isEmpty }
                .joined(separator: " ")
            let words = max(6, text.split { $0.isWhitespace }.count)
            let seconds = max(60, Int(Double(words) / 220.0 * 60.0))
            return ReadabilityResult(
                title: (try? document.title()) ?? "記事",
                byline: try? document.select("[rel=author], .byline").first()?.text(),
                html: try sanitized.outerHtml(),
                text: text,
                wordCount: words,
                readingTime: seconds
            )
        } catch {
            return fallback(html: html, title: nil)
        }
    }

    private func removeNoise(from document: Document) throws {
        let selectors = ["nav", "aside", "header", "footer", "script", "noscript", "style", "form", ".advert", ".sponsored", "#sidebar"]
        for selector in selectors {
            try document.select(selector).remove()
        }
    }

    private func pickBestCandidate(in element: Element) -> Element {
        var best = element
        var bestScore = 0.0
        traverse(element: element) { node in
            let score = scoreForCandidate(node)
            if score > bestScore {
                bestScore = score
                best = node
            }
        }
        return best
    }

    private func scoreForCandidate(_ element: Element) -> Double {
        let fullText = (try? element.text()) ?? ""
        let textLength = Double(fullText.count)
        guard textLength > 80 else { return 0 }
        let linkLength = Double((try? element.select("a").text().count) ?? 0)
        let density = max(0.2, (textLength - linkLength) / max(1, textLength))
        let paragraphBonus = Double((try? element.select("p").size()) ?? 0) * 20
        let headingPenalty = Double((try? element.select("h1,h2,h3,h4").size()) ?? 0) * 5
        return textLength * density + paragraphBonus - headingPenalty
    }

    private func traverse(element: Element, action: (Element) -> Void) {
        action(element)
        for child in element.children() {
            traverse(element: child, action: action)
        }
    }

    private func sanitize(_ element: Element) throws -> Element {
        let allowedTags: Set<String> = ["article","section","div","p","h1","h2","h3","h4","ul","ol","li","strong","em","code","pre","blockquote","img","figure","figcaption","a","span"]
        traverse(element: element) { node in
            if !allowedTags.contains(node.tagName()) {
                try? node.unwrap()
            } else {
                sanitizeAttributes(node)
            }
        }
        return element
    }

    private func sanitizeAttributes(_ element: Element) {
        let allowedAttrs = ["href","src","alt","title","rel"]
        let attributes = element.getAttributes()
        attributes?.forEach { attribute in
            if !allowedAttrs.contains(attribute.getKey()) {
                try? element.removeAttr(attribute.getKey())
            }
        }
        if element.tagName() == "a" {
            if let href = try? element.attr("href"), href.lowercased().hasPrefix("javascript") {
                try? element.removeAttr("href")
            } else {
                try? element.attr("rel", "noopener")
                try? element.attr("target", "_blank")
            }
        }
        if element.tagName() == "img" {
            let src = (try? element.attr("src")) ?? ""
            if src.isEmpty { try? element.remove() }
        }
    }

    private func fallback(html: String, title: String?) -> ReadabilityResult {
        let text = html.trimmingCharacters(in: .whitespacesAndNewlines)
        return ReadabilityResult(title: title ?? "記事", byline: nil, html: html, text: text, wordCount: max(1, text.count / 4), readingTime: 60)
    }
}
