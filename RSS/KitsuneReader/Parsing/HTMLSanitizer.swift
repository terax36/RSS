import Foundation
import SwiftSoup

struct HTMLSanitizer {
    func sanitize(_ html: String) -> String {
        do {
            let fragment = try SwiftSoup.parseBodyFragment(html)
            let whitelist: Set<String> = ["p","a","img","strong","em","ul","ol","li","pre","code","blockquote","span","div"]
            try fragment.select("*").forEach { element in
                if !whitelist.contains(element.tagName()) {
                    try element.unwrap()
                } else {
                    sanitiseAttributes(element)
                }
            }
            return try fragment.body()?.html() ?? html
        } catch {
            return html
        }
    }

    private func sanitiseAttributes(_ element: Element) {
        let allow = ["href","src","alt","title","rel","target"]
        element.getAttributes()?.forEach { attribute in
            if !allow.contains(attribute.getKey()) {
                try? element.removeAttr(attribute.getKey())
            }
        }
        if element.tagName() == "a" {
            try? element.attr("rel", "noopener")
        }
    }
}
