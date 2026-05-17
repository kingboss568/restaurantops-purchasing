import XCTest
@testable import RestaurantOpsPurchasingCore

final class UnitConversionServiceTests: XCTestCase {
    let svc = DefaultUnitConversionService()

    func test_kgToKg_identity() throws {
        let ing = TestFactory.ingredient(unit: .kg)
        let r = try svc.normalizePrice(price: 100, from: .kg, ingredient: ing)
        XCTAssertEqual(r, NormalizedPrice(price: 100, unit: .kg))
    }

    func test_gToKg() throws {
        let ing = TestFactory.ingredient(unit: .kg)
        let r = try svc.normalizePrice(price: Decimal(string: "0.5")!, from: .g, ingredient: ing)
        XCTAssertEqual(r, NormalizedPrice(price: 500, unit: .kg))
    }

    func test_cattyToKg() throws {
        let ing = TestFactory.ingredient(unit: .kg)
        // price per catty 60 -> per kg = 60 / 0.6 = 100
        let r = try svc.normalizePrice(price: 60, from: .catty, ingredient: ing)
        XCTAssertEqual(r.unit, .kg)
        XCTAssertEqual(r.price, 100)
    }

    func test_literIdentity() throws {
        let ing = TestFactory.ingredient(unit: .liter)
        let r = try svc.normalizePrice(price: 80, from: .liter, ingredient: ing)
        XCTAssertEqual(r, NormalizedPrice(price: 80, unit: .liter))
    }

    func test_mlToLiter() throws {
        let ing = TestFactory.ingredient(unit: .liter)
        let r = try svc.normalizePrice(price: Decimal(string: "0.1")!, from: .ml, ingredient: ing)
        XCTAssertEqual(r.unit, .liter)
        XCTAssertEqual(r.price, 100)
    }

    func test_pieceNoPackSize_throws() {
        let ing = TestFactory.ingredient(unit: .kg)
        XCTAssertThrowsError(try svc.normalizePrice(price: 30, from: .piece, ingredient: ing)) { err in
            XCTAssertEqual(err as? UnitConversionError, .missingPackSize(unit: .piece))
        }
    }

    func test_boxNoConversion_throws() {
        let ing = TestFactory.ingredient(unit: .kg)
        XCTAssertThrowsError(try svc.normalizePrice(price: 200, from: .box, ingredient: ing)) { err in
            XCTAssertEqual(err as? UnitConversionError, .missingPackSize(unit: .box))
        }
    }

    func test_decimalNotDoublePrecision() throws {
        let ing = TestFactory.ingredient(unit: .kg)
        let r = try svc.normalizePrice(price: Decimal(string: "0.1")!, from: .g, ingredient: ing)
        XCTAssertEqual(r.price, 100)
    }
}
