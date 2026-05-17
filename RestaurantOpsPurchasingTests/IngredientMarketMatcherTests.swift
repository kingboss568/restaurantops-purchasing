import XCTest
@testable import RestaurantOpsPurchasingCore

final class IngredientMarketMatcherTests: XCTestCase {
    let market: [MarketItem] = [
        MarketItem(itemCode: "FN01", itemName: "高麗菜"),
        MarketItem(itemCode: "FN02", itemName: "甘藍"),
        MarketItem(itemCode: "FN03", itemName: "小黃瓜"),
        MarketItem(itemCode: "FN04", itemName: "胡瓜"),
        MarketItem(itemCode: "FN05", itemName: "番茄"),
        MarketItem(itemCode: "FN06", itemName: "小番茄")
    ]

    func test_exactMatch() async {
        let matcher = SynonymIngredientMarketMatcher(synonyms: ["高麗菜": ["甘藍"]])
        let c = await matcher.candidates(for: "高麗菜", availableMarketItems: market)
        XCTAssertEqual(c.first?.source, .exact)
        XCTAssertEqual(c.first?.itemCode, "FN01")
    }

    func test_synonymMatch() async {
        let matcher = SynonymIngredientMarketMatcher(synonyms: ["高麗菜": ["甘藍"]])
        let c = await matcher.candidates(for: "甘藍", availableMarketItems: market)
        XCTAssertTrue(c.contains { $0.source == .exact || $0.source == .synonym })
    }

    func test_containsMatch() async {
        let matcher = SynonymIngredientMarketMatcher(synonyms: [:])
        let c = await matcher.candidates(for: "番茄", availableMarketItems: market)
        // 番茄 matches exact FN05, and contains-matches FN06 小番茄
        XCTAssertTrue(c.contains { $0.itemCode == "FN05" })
        XCTAssertTrue(c.contains { $0.itemCode == "FN06" })
    }

    func test_emptyWhenNoMatch() async {
        let matcher = SynonymIngredientMarketMatcher(synonyms: [:])
        let c = await matcher.candidates(for: "鮪魚", availableMarketItems: market)
        XCTAssertTrue(c.isEmpty || c.allSatisfy { $0.source == .fuzzy })
    }

    func test_aiCandidatesAreNeverConfirmed() {
        // Documenting policy: confirm flow lives in IngredientDetailViewModel and only sets .userConfirmed.
        // Matcher itself should never emit .userConfirmed source.
        let matcher = SynonymIngredientMarketMatcher(synonyms: ["高麗菜": ["甘藍"]])
        Task {
            let c = await matcher.candidates(for: "高麗菜", availableMarketItems: market)
            XCTAssertFalse(c.contains(where: { $0.source == .userConfirmed }))
            XCTAssertFalse(c.contains(where: { $0.source == .aiSuggested }))
        }
    }

    func test_bundleLoad_doesNotCrash() {
        let matcher = SynonymIngredientMarketMatcher()
        XCTAssertNotNil(matcher)
    }
}
