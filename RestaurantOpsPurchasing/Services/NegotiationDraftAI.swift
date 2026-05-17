import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

public protocol NegotiationDraftAI {
    func generateDraft(context: NegotiationContext) async throws -> NegotiationDraft
}

/// Deterministic template fallback used when Apple Foundation Models is
/// unavailable or fails. Never invents market data.
public struct TemplateNegotiationDraftAI: NegotiationDraftAI {
    public init() {}

    public func generateDraft(context: NegotiationContext) async throws -> NegotiationDraft {
        let message = Self.renderTemplate(context: context)
        return NegotiationDraft(message: message, fallbackUsed: true)
    }

    static func renderTemplate(context: NegotiationContext) -> String {
        let supplier = context.supplierName
        let ingredient = context.ingredientName

        let dataLimited = context.marketAverage7Days == nil && context.marketAverage30Days == nil

        if dataLimited {
            switch context.tone {
            case .polite:
                return "\(supplier) 您好，想跟您確認一下這次 \(ingredient) 的報價。目前參考資料有限，但這次報價對我們的成本影響較明顯。我們一直希望穩定跟您配合，也想請您幫忙看看價格是否還有調整空間，謝謝。"
            case .firm:
                return "\(supplier) 您好，這次 \(ingredient) 的報價我們需要再評估。目前參考資料有限，但對成本影響不小。希望您能協助調整，我們才能維持穩定採購，謝謝。"
            case .friendly:
                return "\(supplier) 您好，最近合作得很愉快。這次 \(ingredient) 的報價我們稍微有點壓力，目前參考資料有限，再麻煩您看看有沒有空間，謝謝您一直以來的配合。"
            case .longTermPartner:
                return "\(supplier) 您好，我們合作已久，這次 \(ingredient) 的報價對我們影響較明顯。目前參考資料有限，希望以長期合作的角度，請您再評估價格，謝謝。"
            }
        }

        let referenceParts = [
            context.marketAverage7Days.map { "7 日均價約 \(formatPrice($0))" },
            context.marketAverage30Days.map { "30 日均價約 \(formatPrice($0))" }
        ].compactMap { $0 }.joined(separator: "、")

        let percentText: String
        if let p = context.differencePercent {
            let sign = p >= 0 ? "高出" : "低於"
            percentText = "這次報價約\(sign) \(formatPercent(abs(p)))%"
        } else {
            percentText = "這次報價與市場行情差異"
        }

        switch context.tone {
        case .polite:
            return "\(supplier) 您好，想跟您確認一下這次 \(ingredient) 的報價。我們看到\(referenceParts)，\(percentText)。我們一直希望穩定跟您配合，也想請您幫忙看看這批價格是否還有調整空間，謝謝。"
        case .firm:
            return "\(supplier) 您好，這次 \(ingredient) 的報價我們需要重新評估。參考\(referenceParts)，\(percentText)，對我們成本壓力較大，希望您能協助調整，我們才能維持穩定下單，謝謝。"
        case .friendly:
            return "\(supplier) 您好，最近合作都很順利。這次 \(ingredient) 的價格我們對照\(referenceParts)，\(percentText)，想跟您聊聊有沒有調整空間，麻煩您幫忙看看，感謝。"
        case .longTermPartner:
            return "\(supplier) 您好，我們合作多年，希望延續穩定關係。這次 \(ingredient) 報價對照\(referenceParts)，\(percentText)。以長期合作的角度，希望您能再協助看看價格，謝謝。"
        }
    }

    private static func formatPrice(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 0
        return "$" + (formatter.string(from: value as NSDecimalNumber) ?? "\(value)")
    }

    private static func formatPercent(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 0
        return formatter.string(from: value as NSDecimalNumber) ?? "\(value)"
    }
}

/// Foundation Models adapter. When the framework is unavailable at compile or
/// runtime, falls back to the deterministic template implementation.
public struct FoundationModelsNegotiationDraftAI: NegotiationDraftAI {
    private let fallback: NegotiationDraftAI

    public init(fallback: NegotiationDraftAI = TemplateNegotiationDraftAI()) {
        self.fallback = fallback
    }

    public func generateDraft(context: NegotiationContext) async throws -> NegotiationDraft {
        #if canImport(FoundationModels)
        if #available(iOS 26, macOS 26, *) {
            do {
                let prompt = Self.buildPrompt(from: context)
                let session = LanguageModelSession()
                let response = try await session.respond(to: prompt)
                let text = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
                if !text.isEmpty {
                    return NegotiationDraft(message: text, fallbackUsed: false)
                }
            } catch {
                // fall through to fallback
            }
        }
        #endif
        return try await fallback.generateDraft(context: context)
    }

    static func buildPrompt(from context: NegotiationContext) -> String {
        var lines: [String] = []
        lines.append("請使用繁體中文撰寫一則 80 至 180 字的議價訊息，給供應商「\(context.supplierName)」。")
        lines.append("食材：\(context.ingredientName)。")
        if let r = context.restaurantName { lines.append("我方餐廳：\(r)。") }
        lines.append("我方目前報價：\(context.quotedPrice)。")
        if let v = context.marketAverage7Days { lines.append("7 日均價：\(v)。") }
        if let v = context.marketAverage30Days { lines.append("30 日均價：\(v)。") }
        if let p = context.differencePercent { lines.append("價差百分比：\(p)%。") }
        if let s = context.recentTrendSummary { lines.append("近期趨勢：\(s)。") }
        lines.append("語氣：\(context.tone.displayName)。")
        lines.append("規則：禮貌但有力，不威脅，不捏造市場資料，不自稱 AI，不輸出 Markdown 與表格。")
        if context.marketAverage7Days == nil && context.marketAverage30Days == nil {
            lines.append("市場資料不足，請在訊息中明確說「目前參考資料有限」。")
        }
        return lines.joined(separator: "\n")
    }
}
