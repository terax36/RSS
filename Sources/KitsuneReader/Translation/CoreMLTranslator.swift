import CoreML
import Foundation
import NaturalLanguage

@MainActor
final class CoreMLTranslator {
    private let tokenizer = NLTokenizer(unit: .word)
    private lazy var dictionaryEnJa: [String: String] = [
        "hello": "こんにちは",
        "world": "世界",
        "update": "アップデート",
        "breaking": "速報",
        "news": "ニュース",
        "today": "今日"
    ]
    private lazy var dictionaryJaEn: [String: String] = [
        "こんにちは": "hello",
        "世界": "world",
        "速報": "breaking",
        "ニュース": "news",
        "今日": "today"
    ]

    func translate(_ text: String, from source: Locale?, to target: Locale) async throws -> String {
        tokenizer.string = text
        var tokens: [String] = []
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            tokens.append(String(text[range]))
            return true
        }
        guard !tokens.isEmpty else { throw TranslationError.empty }
        if (source?.identifier ?? "auto").hasPrefix("en") && target.identifier == "ja" {
            return map(tokens, using: dictionaryEnJa)
        } else if (source?.identifier ?? "auto").hasPrefix("ja") && target.identifier.hasPrefix("en") {
            return map(tokens, using: dictionaryJaEn)
        } else {
            return text
        }
    }

    private func map(_ tokens: [String], using dict: [String: String]) -> String {
        tokens.map { token in
            let key = token.lowercased()
            return dict[key] ?? token
        }.joined(separator: " ")
    }
}
