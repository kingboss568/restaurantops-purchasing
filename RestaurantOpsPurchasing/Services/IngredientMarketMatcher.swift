import Foundation

public protocol IngredientMarketMatcher {
    func candidates(
        for ingredientName: String,
        availableMarketItems: [MarketItem]
    ) async -> [IngredientMarketCandidate]
}

public final class SynonymIngredientMarketMatcher: IngredientMarketMatcher {
    public typealias SynonymTable = [String: [String]]

    private let synonyms: SynonymTable

    public init(synonyms: SynonymTable) {
        self.synonyms = synonyms
    }

    public convenience init(bundle: Bundle? = nil, resourceName: String = "ingredient_synonyms_zh_TW") {
        let resolvedBundle = bundle ?? ResourceBundleProvider.current
        let table: SynonymTable
        if let url = resolvedBundle.url(forResource: resourceName, withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode(SynonymTable.self, from: data) {
            table = decoded
        } else {
            table = [:]
        }
        self.init(synonyms: table)
    }

    public func candidates(
        for ingredientName: String,
        availableMarketItems: [MarketItem]
    ) async -> [IngredientMarketCandidate] {
        let normalizedIngredient = Self.normalize(ingredientName)
        guard !normalizedIngredient.isEmpty else { return [] }

        var results: [IngredientMarketCandidate] = []
        var seenCodes = Set<String>()

        func add(_ candidate: IngredientMarketCandidate) {
            guard !seenCodes.contains(candidate.itemCode) else { return }
            seenCodes.insert(candidate.itemCode)
            results.append(candidate)
        }

        // 1. Exact match
        for item in availableMarketItems {
            if Self.normalize(item.itemName) == normalizedIngredient {
                add(IngredientMarketCandidate(
                    itemCode: item.itemCode,
                    itemName: item.itemName,
                    confidence: Decimal(1),
                    source: .exact,
                    reason: "名稱完全相符"
                ))
            }
        }

        // 2. Synonym match
        let candidateNames = synonymCandidates(for: normalizedIngredient)
        for synonym in candidateNames {
            for item in availableMarketItems {
                if Self.normalize(item.itemName) == synonym {
                    add(IngredientMarketCandidate(
                        itemCode: item.itemCode,
                        itemName: item.itemName,
                        confidence: Decimal(string: "0.9")!,
                        source: .synonym,
                        reason: "同義詞對應：\(synonym)"
                    ))
                }
            }
        }

        // 3. Contains match
        for item in availableMarketItems {
            let n = Self.normalize(item.itemName)
            if n.contains(normalizedIngredient) || normalizedIngredient.contains(n) {
                add(IngredientMarketCandidate(
                    itemCode: item.itemCode,
                    itemName: item.itemName,
                    confidence: Decimal(string: "0.75")!,
                    source: .fuzzy,
                    reason: "名稱部分相符"
                ))
            }
        }

        // 4. Simple fuzzy (Levenshtein) — best 3
        let fuzzy = availableMarketItems.compactMap { item -> (MarketItem, Int)? in
            let n = Self.normalize(item.itemName)
            let d = Self.levenshtein(normalizedIngredient, n)
            let maxLen = max(normalizedIngredient.count, n.count)
            if maxLen == 0 { return nil }
            let ratio = Double(d) / Double(maxLen)
            if ratio < 0.5 {
                return (item, d)
            }
            return nil
        }
        .sorted { $0.1 < $1.1 }
        .prefix(3)
        for (item, _) in fuzzy {
            add(IngredientMarketCandidate(
                itemCode: item.itemCode,
                itemName: item.itemName,
                confidence: Decimal(string: "0.6")!,
                source: .fuzzy,
                reason: "模糊比對"
            ))
        }

        return results
    }

    private func synonymCandidates(for normalized: String) -> [String] {
        var out: Set<String> = []
        for (key, values) in synonyms {
            let nk = Self.normalize(key)
            if nk == normalized {
                values.forEach { out.insert(Self.normalize($0)) }
            }
            for v in values where Self.normalize(v) == normalized {
                out.insert(nk)
                values.forEach { out.insert(Self.normalize($0)) }
            }
        }
        return Array(out)
    }

    static func normalize(_ s: String) -> String {
        let stripped = s
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "\u{3000}", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        // collapse full-width digits / punctuation could be added; minimal MVP
        return stripped
    }

    static func levenshtein(_ a: String, _ b: String) -> Int {
        let arr1 = Array(a)
        let arr2 = Array(b)
        let m = arr1.count
        let n = arr2.count
        if m == 0 { return n }
        if n == 0 { return m }
        var prev = Array(0...n)
        var curr = Array(repeating: 0, count: n + 1)
        for i in 1...m {
            curr[0] = i
            for j in 1...n {
                let cost = arr1[i - 1] == arr2[j - 1] ? 0 : 1
                curr[j] = min(
                    prev[j] + 1,
                    curr[j - 1] + 1,
                    prev[j - 1] + cost
                )
            }
            swap(&prev, &curr)
        }
        return prev[n]
    }
}
