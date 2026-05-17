import Foundation
@testable import RestaurantOpsPurchasingCore

enum TestFactory {
    static let restaurantID = UUID()

    static func ingredient(name: String = "高麗菜", unit: UnitType = .kg, linked: String? = "FN01") -> Ingredient {
        Ingredient(
            restaurantID: restaurantID,
            name: name,
            category: .vegetable,
            unit: unit,
            linkedMarketItemCode: linked,
            linkedMarketItemName: linked == nil ? nil : "高麗菜"
        )
    }

    static func supplier(name: String = "阿明蔬果行") -> Supplier {
        Supplier(restaurantID: restaurantID, name: name)
    }

    static func quote(supplier: Supplier, ingredient: Ingredient, price: Decimal, unit: UnitType = .kg, daysAgo: Int = 0) -> SupplierQuote {
        let cal = Calendar(identifier: .gregorian)
        let date = cal.date(byAdding: .day, value: -daysAgo, to: refDate) ?? refDate
        return SupplierQuote(
            supplierID: supplier.id,
            ingredientID: ingredient.id,
            quoteDate: date,
            quotedPrice: price,
            unit: unit
        )
    }

    static func market(itemCode: String = "FN01", price: Decimal = 100, volume: Decimal? = nil, daysAgo: Int = 0, marketCode: String = "MK01") -> MarketPriceRecord {
        let cal = Calendar(identifier: .gregorian)
        let date = cal.date(byAdding: .day, value: -daysAgo, to: refDate) ?? refDate
        return MarketPriceRecord(
            itemCode: itemCode,
            itemName: "高麗菜",
            marketCode: marketCode,
            marketName: "台北一",
            tradeDate: date,
            averagePrice: price,
            volume: volume,
            sourceName: "test",
            sourceKey: "test|\(date.timeIntervalSince1970)|\(marketCode)|\(itemCode)|kg"
        )
    }

    static let refDate: Date = {
        var c = DateComponents()
        c.year = 2026; c.month = 5; c.day = 17
        return Calendar(identifier: .gregorian).date(from: c)!
    }()
}
