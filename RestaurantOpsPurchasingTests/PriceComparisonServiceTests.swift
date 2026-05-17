import XCTest
@testable import RestaurantOpsPurchasingCore

final class PriceComparisonServiceTests: XCTestCase {
    let svc = DefaultPriceComparisonService()

    func test_higherThanMarket_plus20() throws {
        let ing = TestFactory.ingredient()
        let supplier = TestFactory.supplier()
        let quote = TestFactory.quote(supplier: supplier, ingredient: ing, price: 120)
        let market = (0..<7).map { TestFactory.market(price: 100, daysAgo: $0) }
        let r = try svc.compare(ingredient: ing, suppliers: [supplier], supplierQuotes: [quote], marketRecords: market, asOf: TestFactory.refDate)
        let c = r.supplierComparisons.first!
        XCTAssertEqual(c.status, .higherThanMarket)
        XCTAssertEqual(c.differencePercent, 20)
    }

    func test_nearMarket_minus4() throws {
        let ing = TestFactory.ingredient()
        let supplier = TestFactory.supplier()
        let quote = TestFactory.quote(supplier: supplier, ingredient: ing, price: 96)
        let market = (0..<7).map { TestFactory.market(price: 100, daysAgo: $0) }
        let r = try svc.compare(ingredient: ing, suppliers: [supplier], supplierQuotes: [quote], marketRecords: market, asOf: TestFactory.refDate)
        let c = r.supplierComparisons.first!
        XCTAssertEqual(c.status, .nearMarket)
        XCTAssertEqual(c.differencePercent, -4)
    }

    func test_cheaperThanMarket_minus15() throws {
        let ing = TestFactory.ingredient()
        let supplier = TestFactory.supplier()
        let quote = TestFactory.quote(supplier: supplier, ingredient: ing, price: 85)
        let market = (0..<7).map { TestFactory.market(price: 100, daysAgo: $0) }
        let r = try svc.compare(ingredient: ing, suppliers: [supplier], supplierQuotes: [quote], marketRecords: market, asOf: TestFactory.refDate)
        let c = r.supplierComparisons.first!
        XCTAssertEqual(c.status, .cheaperThanMarket)
        XCTAssertEqual(c.differencePercent, -15)
    }

    func test_missingMarketData_whenUnlinked() throws {
        let ing = TestFactory.ingredient(linked: nil)
        let supplier = TestFactory.supplier()
        let quote = TestFactory.quote(supplier: supplier, ingredient: ing, price: 100)
        let r = try svc.compare(ingredient: ing, suppliers: [supplier], supplierQuotes: [quote], marketRecords: [], asOf: TestFactory.refDate)
        let c = r.supplierComparisons.first!
        XCTAssertEqual(c.status, .missingMarketData)
    }

    func test_unitMismatch_pieceVsKg() throws {
        let ing = TestFactory.ingredient(unit: .kg)
        let supplier = TestFactory.supplier()
        let quote = TestFactory.quote(supplier: supplier, ingredient: ing, price: 30, unit: .piece)
        let market = (0..<7).map { TestFactory.market(price: 100, daysAgo: $0) }
        let r = try svc.compare(ingredient: ing, suppliers: [supplier], supplierQuotes: [quote], marketRecords: market, asOf: TestFactory.refDate)
        let c = r.supplierComparisons.first!
        XCTAssertEqual(c.status, .unitMismatch)
        XCTAssertNil(c.rank)
    }

    func test_multiSupplierRanking() throws {
        let ing = TestFactory.ingredient()
        let s1 = TestFactory.supplier(name: "A")
        let s2 = TestFactory.supplier(name: "B")
        let s3 = TestFactory.supplier(name: "C")
        let q1 = TestFactory.quote(supplier: s1, ingredient: ing, price: 110)
        let q2 = TestFactory.quote(supplier: s2, ingredient: ing, price: 95)
        let q3 = TestFactory.quote(supplier: s3, ingredient: ing, price: 102)
        let market = (0..<7).map { TestFactory.market(price: 100, daysAgo: $0) }
        let r = try svc.compare(ingredient: ing, suppliers: [s1, s2, s3], supplierQuotes: [q1, q2, q3], marketRecords: market, asOf: TestFactory.refDate)
        let byID = Dictionary(uniqueKeysWithValues: r.supplierComparisons.map { ($0.supplierID, $0) })
        XCTAssertEqual(byID[s2.id]?.rank, 1)
        XCTAssertEqual(byID[s3.id]?.rank, 2)
        XCTAssertEqual(byID[s1.id]?.rank, 3)
    }

    func test_sevenDayAverage_correct() throws {
        let ing = TestFactory.ingredient()
        let supplier = TestFactory.supplier()
        let quote = TestFactory.quote(supplier: supplier, ingredient: ing, price: 100)
        // 7 days: 90, 92, 94, 96, 98, 100, 102 -> avg 96.857...
        let prices: [Decimal] = [90, 92, 94, 96, 98, 100, 102]
        let market = prices.enumerated().map { TestFactory.market(price: $0.element, daysAgo: $0.offset) }
        let r = try svc.compare(ingredient: ing, suppliers: [supplier], supplierQuotes: [quote], marketRecords: market, asOf: TestFactory.refDate)
        let total: Decimal = prices.reduce(0, +)
        let expected = total / Decimal(prices.count)
        XCTAssertEqual(r.marketAverage7Days, expected)
    }

    func test_thirtyDayAverage_correct() throws {
        let ing = TestFactory.ingredient()
        let supplier = TestFactory.supplier()
        let quote = TestFactory.quote(supplier: supplier, ingredient: ing, price: 100)
        let market = (0..<30).map { TestFactory.market(price: Decimal(100 + $0), daysAgo: $0) }
        let r = try svc.compare(ingredient: ing, suppliers: [supplier], supplierQuotes: [quote], marketRecords: market, asOf: TestFactory.refDate)
        XCTAssertNotNil(r.marketAverage30Days)
        // sum 100..129 = 30 * 100 + (0+29)*30/2 = 3000 + 435 = 3435, avg = 114.5
        XCTAssertEqual(r.marketAverage30Days, Decimal(string: "114.5"))
    }

    func test_volumeWeightedAverage() throws {
        let ing = TestFactory.ingredient()
        let supplier = TestFactory.supplier()
        let quote = TestFactory.quote(supplier: supplier, ingredient: ing, price: 100)
        // 2 records same day: price 100 volume 100, price 200 volume 0 (excluded), price 150 volume 300
        // Latest day records: weighted = (100*100 + 150*300)/(100+300) = (10000+45000)/400 = 137.5
        let m1 = TestFactory.market(price: 100, volume: 100, daysAgo: 0, marketCode: "M1")
        let m2 = TestFactory.market(price: 150, volume: 300, daysAgo: 0, marketCode: "M2")
        let r = try svc.compare(ingredient: ing, suppliers: [supplier], supplierQuotes: [quote], marketRecords: [m1, m2], asOf: TestFactory.refDate)
        XCTAssertEqual(r.latestMarketAverage, Decimal(string: "137.5"))
    }

    func test_arithmeticFallback_whenAllVolumeMissing() throws {
        let ing = TestFactory.ingredient()
        let supplier = TestFactory.supplier()
        let quote = TestFactory.quote(supplier: supplier, ingredient: ing, price: 100)
        let m1 = TestFactory.market(price: 100, volume: nil, daysAgo: 0, marketCode: "M1")
        let m2 = TestFactory.market(price: 150, volume: nil, daysAgo: 0, marketCode: "M2")
        let r = try svc.compare(ingredient: ing, suppliers: [supplier], supplierQuotes: [quote], marketRecords: [m1, m2], asOf: TestFactory.refDate)
        XCTAssertEqual(r.latestMarketAverage, 125)
    }

    func test_unitMismatch_rankNil() throws {
        let ing = TestFactory.ingredient(unit: .kg)
        let s1 = TestFactory.supplier(name: "A")
        let s2 = TestFactory.supplier(name: "B")
        let q1 = TestFactory.quote(supplier: s1, ingredient: ing, price: 100, unit: .kg)
        let q2 = TestFactory.quote(supplier: s2, ingredient: ing, price: 5, unit: .box)
        let market = (0..<7).map { TestFactory.market(price: 100, daysAgo: $0) }
        let r = try svc.compare(ingredient: ing, suppliers: [s1, s2], supplierQuotes: [q1, q2], marketRecords: market, asOf: TestFactory.refDate)
        let byID = Dictionary(uniqueKeysWithValues: r.supplierComparisons.map { ($0.supplierID, $0) })
        XCTAssertEqual(byID[s1.id]?.rank, 1)
        XCTAssertNil(byID[s2.id]?.rank)
    }

    func test_noDivisionByZero_whenMarketReferenceZero() throws {
        let ing = TestFactory.ingredient()
        let supplier = TestFactory.supplier()
        let quote = TestFactory.quote(supplier: supplier, ingredient: ing, price: 100)
        let market = [TestFactory.market(price: 0, daysAgo: 0)]
        let r = try svc.compare(ingredient: ing, suppliers: [supplier], supplierQuotes: [quote], marketRecords: market, asOf: TestFactory.refDate)
        let c = r.supplierComparisons.first!
        XCTAssertEqual(c.status, .missingMarketData)
        XCTAssertNil(c.differencePercent)
    }
}
