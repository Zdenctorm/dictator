import Foundation

/// Nahradí hlasové interpunkční příkazy v češtině za skutečné znaky.
/// Match je word-boundary aware, case- a diakritika-insensitive.
enum PunctuationCommandProcessor {
    static func apply(to text: String) -> String {
        guard !text.isEmpty else { return text }

        var result = text
        for rule in rules {
            result = replacePhrase(rule.phrase, with: rule.replacement, in: result)
        }
        return result
    }

    private struct Rule {
        let phrase: String
        let replacement: String
    }

    /// Delší fráze první — „nový odstavec“ nesmí být rozbitý na „nový“ + zbytek.
    private static let rules: [Rule] = [
        Rule(phrase: "novy odstavec", replacement: "\n\n"),
        Rule(phrase: "novy radek", replacement: "\n"),
        Rule(phrase: "vykricnik", replacement: "!"),
        Rule(phrase: "otaznik", replacement: "?"),
        Rule(phrase: "carka", replacement: ","),
        Rule(phrase: "tecka", replacement: "."),
    ]

    private static func replacePhrase(_ phrase: String, with replacement: String, in source: String) -> String {
        let normalizedPhrase = phrase.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        guard !normalizedPhrase.isEmpty else { return source }

        let escaped = NSRegularExpression.escapedPattern(for: normalizedPhrase)
        let flexibleWhitespace = escaped.replacingOccurrences(of: "\\ ", with: "\\s+")
        let pattern = "(?<![\\p{L}\\p{N}])\(flexibleWhitespace)(?![\\p{L}\\p{N}])"

        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return source
        }

        let normalizedSource = source.folding(options: .diacriticInsensitive, locale: .current)
        guard normalizedSource.utf16.count == source.utf16.count else { return source }

        let nsSource = normalizedSource as NSString
        let matches = regex.matches(in: normalizedSource, options: [], range: NSRange(location: 0, length: nsSource.length))
        guard !matches.isEmpty else { return source }

        let mutable = NSMutableString(string: source)
        for match in matches.reversed() {
            mutable.replaceCharacters(in: match.range, with: replacement)
        }
        return mutable as String
    }
}
