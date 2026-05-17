import XCTest
@testable import RestaurantOpsPurchasingCore

final class NegotiationDraftAITests: XCTestCase {
    func makeContext(tone: NegotiationTone = .polite, avg7: Decimal? = 100, avg30: Decimal? = 105, percent: Decimal? = 20) -> NegotiationContext {
        NegotiationContext(
            restaurantName: "示範餐廳",
            supplierName: "阿明蔬果行",
            ingredientName: "高麗菜",
            quotedPrice: 120,
            marketAverage7Days: avg7,
            marketAverage30Days: avg30,
            differencePercent: percent,
            recentTrendSummary: nil,
            tone: tone
        )
    }

    func test_template_returnsMessage() async throws {
        let ai = TemplateNegotiationDraftAI()
        let d = try await ai.generateDraft(context: makeContext())
        XCTAssertFalse(d.message.isEmpty)
        XCTAssertTrue(d.fallbackUsed)
        XCTAssertFalse(d.message.contains("|"))
        XCTAssertFalse(d.message.contains("```"))
    }

    func test_template_noFabrication_whenDataLimited() async throws {
        let ai = TemplateNegotiationDraftAI()
        let d = try await ai.generateDraft(context: makeContext(avg7: nil, avg30: nil, percent: nil))
        XCTAssertTrue(d.message.contains("目前參考資料有限"))
        XCTAssertFalse(d.message.contains("$"))
    }

    func test_differentTones_produceDifferentMessages() async throws {
        let ai = TemplateNegotiationDraftAI()
        let polite = try await ai.generateDraft(context: makeContext(tone: .polite)).message
        let firm = try await ai.generateDraft(context: makeContext(tone: .firm)).message
        let friendly = try await ai.generateDraft(context: makeContext(tone: .friendly)).message
        let longTerm = try await ai.generateDraft(context: makeContext(tone: .longTermPartner)).message
        let set = Set([polite, firm, friendly, longTerm])
        XCTAssertEqual(set.count, 4)
    }

    func test_template_noThreatLanguage() async throws {
        let ai = TemplateNegotiationDraftAI()
        let d = try await ai.generateDraft(context: makeContext(tone: .firm))
        for bad in ["不然", "否則", "終止合作", "馬上", "立刻取消"] {
            XCTAssertFalse(d.message.contains(bad), "should not contain '\(bad)'")
        }
    }

    func test_foundationModelsAdapter_fallsBack() async throws {
        let ai = FoundationModelsNegotiationDraftAI()
        let d = try await ai.generateDraft(context: makeContext())
        // Even if FM is unavailable (compile/runtime), we must get a non-empty draft.
        XCTAssertFalse(d.message.isEmpty)
    }

    func test_template_messageLengthReasonable() async throws {
        let ai = TemplateNegotiationDraftAI()
        let d = try await ai.generateDraft(context: makeContext())
        XCTAssertGreaterThanOrEqual(d.message.count, 40)
        XCTAssertLessThanOrEqual(d.message.count, 240)
    }
}
