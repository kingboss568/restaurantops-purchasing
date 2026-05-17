import XCTest
import SwiftData
@testable import RestaurantOpsPurchasingCore

final class PurchasingRepositoryTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!

    override func setUp() async throws {
        let schema = Schema([
            RestaurantProfile.self, Ingredient.self, MarketPriceRecord.self,
            Supplier.self, SupplierQuote.self, IngredientMarketMapping.self,
            MarketPriceFetchLog.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        context = ModelContext(container)
    }

    func test_importMarketPrices_insertsAndUpserts() async throws {
        let client = MockAgriPriceAPIClient()
        let repo = DefaultPurchasingRepository(apiClient: client, context: context, sourceName: "test-source")

        let result1 = try await repo.importMarketPrices(
            from: Date(timeIntervalSince1970: 0),
            to: Date(timeIntervalSinceNow: 86400),
            itemName: nil, itemCode: nil, marketName: nil, marketCode: nil
        )
        XCTAssertGreaterThan(result1.insertedCount, 0)

        let result2 = try await repo.importMarketPrices(
            from: Date(timeIntervalSince1970: 0),
            to: Date(timeIntervalSinceNow: 86400),
            itemName: nil, itemCode: nil, marketName: nil, marketCode: nil
        )
        // Second import should update existing rows, not insert.
        XCTAssertEqual(result2.insertedCount, 0)
        XCTAssertGreaterThan(result2.updatedCount, 0)
    }

    func test_latestFetchLog_returnsLatest() async throws {
        let client = MockAgriPriceAPIClient()
        let repo = DefaultPurchasingRepository(apiClient: client, context: context, sourceName: "test-source")
        _ = try await repo.importMarketPrices(
            from: Date(timeIntervalSince1970: 0),
            to: Date(timeIntervalSinceNow: 86400),
            itemName: nil, itemCode: nil, marketName: nil, marketCode: nil
        )
        let log = try repo.latestFetchLog(sourceName: "test-source")
        XCTAssertNotNil(log)
    }

    func test_availableMarketItems_returnsDistinct() async throws {
        let client = MockAgriPriceAPIClient()
        let repo = DefaultPurchasingRepository(apiClient: client, context: context, sourceName: "test-source")
        _ = try await repo.importMarketPrices(
            from: Date(timeIntervalSince1970: 0),
            to: Date(timeIntervalSinceNow: 86400),
            itemName: nil, itemCode: nil, marketName: nil, marketCode: nil
        )
        let items = try repo.availableMarketItems()
        XCTAssertGreaterThan(items.count, 0)
        XCTAssertEqual(items.count, Set(items.map { $0.itemCode }).count)
    }
}
