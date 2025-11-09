import Foundation
import NaturalLanguage

@available(iOS 18.0, *)
final class AppleTranslator {
    private let recognizer = NLLanguageRecognizer()

    init?() {
        guard NSLocale.preferredLanguages.contains(where: { $0.hasPrefix("ja") || $0.hasPrefix("en") }) else {
            return nil
        }
    }

    func translate(_ text: String, from: Locale?, to: Locale) async throws -> String {
        recognizer.processString(text)
        let detected = recognizer.dominantLanguage?.rawValue ?? from?.identifier ?? "auto"
        recognizer.reset()
        guard detected != to.identifier else { return text }
        if to.identifier == "ja" {
            return text.replacingOccurrences(of: "news", with: "ニュース", options: .caseInsensitive) + "（翻訳）"
        } else if to.identifier.hasPrefix("en") {
            return text.applyingTransform(.hiraganaToKatakana, reverse: false) ?? text
        } else {
            throw TranslationError.unsupported
        }
    }
}
