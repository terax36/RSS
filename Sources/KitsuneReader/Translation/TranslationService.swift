import Foundation
import NaturalLanguage

enum TranslationError: Error {
    case unsupported
    case empty
}

@MainActor
protocol TranslationService {
    func translate(_ text: String, from source: Locale?, to target: Locale) async throws -> String
}

@MainActor
final class TranslationCoordinator: ObservableObject, TranslationService {
    private let cache = NSCache<NSString, NSString>()
    private let splitter = SentenceSplitter()
    private let coreMLTranslator = CoreMLTranslator()

    func translate(_ text: String, from source: Locale?, to target: Locale) async throws -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw TranslationError.empty }
        let key = "\(trimmed)_\(source?.identifier ?? "auto")_\(target.identifier)" as NSString
        if let cached = cache.object(forKey: key) {
            return cached as String
        }
        let sentences = splitter.split(text: trimmed)
        var translated: [String] = []
        for sentence in sentences {
            #if os(iOS)
            if #available(iOS 18.0, *), let apple = AppleTranslator() {
                let result = try await apple.translate(sentence, from: source, to: target)
                translated.append(result)
                continue
            }
            #endif
            let result = try await coreMLTranslator.translate(sentence, from: source, to: target)
            translated.append(result)
        }
        let joined = translated.joined(separator: " ")
        cache.setObject(joined as NSString, forKey: key)
        return joined
    }
}
