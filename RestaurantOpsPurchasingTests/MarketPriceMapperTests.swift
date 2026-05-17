import XCTest
@testable import RestaurantOpsPurchasingCore

final class MarketPriceMapperTests: XCTestCase {
    let mapper = MarketPriceMapper()

    func test_mapsValidDTO() throws {
        let dto = MarketPriceDTO(
            tradeDateRaw: "2026-05-15",
            categoryCode: "N",
            itemCode: "FN01",
            itemName: "高麗菜",
            marketCode: "MK01",
            marketName: "台北一",
            highPriceRaw: "30",
            midPriceRaw: "25",
            lowPriceRaw: "20",
            averagePriceRaw: "25.5",
            volumeRaw: "1000"
        )
        let input = try mapper.map(dto, sourceName: "test", fetchedAt: Date())
        XCTAssertEqual(input.itemCode, "FN01")
        XCTAssertEqual(input.averagePrice, Decimal(string: "25.5"))
        XCTAssertEqual(input.volume, 1000)
    }

    func test_minguoDate() throws {
        let dto = MarketPriceDTO(
            tradeDateRaw: "115.05.16",
            categoryCode: nil, itemCode: "FN01", itemName: "高麗菜",
            marketCode: nil, marketName: "台北一",
            highPriceRaw: nil, midPriceRaw: nil, lowPriceRaw: nil,
            averagePriceRaw: "25", volumeRaw: nil
        )
        let input = try mapper.map(dto, sourceName: "test", fetchedAt: Date())
        let cal = Calendar(identifier: .gregorian)
        let comps = cal.dateComponents([.year, .month, .day], from: input.tradeDate)
        XCTAssertEqual(comps.year, 2026)
        XCTAssertEqual(comps.month, 5)
        XCTAssertEqual(comps.day, 16)
    }

    func test_emptyStringPrice_doesNotCrash() {
        let dto = MarketPriceDTO(
            tradeDateRaw: "2026-05-15",
            categoryCode: nil, itemCode: "FN01", itemName: "高麗菜",
            marketCode: nil, marketName: "台北一",
            highPriceRaw: "", midPriceRaw: "-", lowPriceRaw: nil,
            averagePriceRaw: "", volumeRaw: ""
        )
        XCTAssertThrowsError(try mapper.map(dto, sourceName: "test", fetchedAt: Date()))
    }

    func test_averagePriceMissing_throws() {
        let dto = MarketPriceDTO(
            tradeDateRaw: "2026-05-15",
            categoryCode: nil, itemCode: "FN01", itemName: "高麗菜",
            marketCode: nil, marketName: "台北一",
            highPriceRaw: nil, midPriceRaw: nil, lowPriceRaw: nil,
            averagePriceRaw: "", volumeRaw: nil
        )
        XCTAssertThrowsError(try mapper.map(dto, sourceName: "test", fetchedAt: Date())) { err in
            XCTAssertEqual(err as? MarketPriceMappingError, .missingAveragePrice)
        }
    }

    func test_sourceKeyDeterministic() throws {
        let dto = MarketPriceDTO(
            tradeDateRaw: "2026-05-15",
            categoryCode: nil, itemCode: "FN01", itemName: "高麗菜",
            marketCode: "MK01", marketName: "台北一",
            highPriceRaw: nil, midPriceRaw: nil, lowPriceRaw: nil,
            averagePriceRaw: "25", volumeRaw: nil
        )
        let a = try mapper.map(dto, sourceName: "test", fetchedAt: Date())
        let b = try mapper.map(dto, sourceName: "test", fetchedAt: Date().addingTimeInterval(60))
        XCTAssertEqual(a.sourceKey, b.sourceKey)
    }

    func test_volumeOptional() throws {
        let dto = MarketPriceDTO(
            tradeDateRaw: "2026-05-15",
            categoryCode: nil, itemCode: "FN01", itemName: "高麗菜",
            marketCode: nil, marketName: "台北一",
            highPriceRaw: nil, midPriceRaw: nil, lowPriceRaw: nil,
            averagePriceRaw: "25", volumeRaw: nil
        )
        let input = try mapper.map(dto, sourceName: "test", fetchedAt: Date())
        XCTAssertNil(input.volume)
    }

    func test_decimalParser_handlesCommaWhitespace() {
        XCTAssertEqual(MarketPriceMapper.parseDecimal(" 1,234.5 "), Decimal(string: "1234.5"))
        XCTAssertNil(MarketPriceMapper.parseDecimal(""))
        XCTAssertNil(MarketPriceMapper.parseDecimal("-"))
        XCTAssertNil(MarketPriceMapper.parseDecimal(nil))
    }

    func test_mockJSON_decodesAndMaps() async throws {
        let client = MockAgriPriceAPIClient()
        let dtos = try await client.fetchMarketPrices(
            from: Date(timeIntervalSince1970: 0),
            to: Date(timeIntervalSinceNow: 86400),
            itemName: nil, itemCode: nil, marketName: nil, marketCode: nil
        )
        XCTAssertGreaterThan(dtos.count, 0)
        var ok = 0
        var thrown = 0
        for dto in dtos {
            do {
                _ = try mapper.map(dto, sourceName: "mock", fetchedAt: Date())
                ok += 1
            } catch {
                thrown += 1
            }
        }
        XCTAssertGreaterThan(ok, 0)
    }
}
