import Foundation
import SwiftData

/// Demo seed store. On first launch, inserts a sample restaurant, ingredients,
/// suppliers, and quotes so the app is usable offline.
public final class PurchasingDemoStore: ObservableObject {
    public static let preview = PurchasingDemoStore()
    private var seeded = false

    public init() {}

    public func seedIfNeeded(context: ModelContext) {
        guard !seeded else { return }
        seeded = true
        do {
            let existing = try context.fetch(FetchDescriptor<RestaurantProfile>())
            if !existing.isEmpty { return }

            let restaurant = RestaurantProfile(name: "示範餐廳")
            context.insert(restaurant)

            let ingSeeds: [(String, IngredientCategory, UnitType)] = [
                ("高麗菜", .vegetable, .kg),
                ("小黃瓜", .vegetable, .kg),
                ("番茄", .vegetable, .kg),
                ("青蔥", .vegetable, .kg),
                ("馬鈴薯", .vegetable, .kg),
                ("空心菜", .vegetable, .kg),
                ("地瓜葉", .vegetable, .kg),
                ("白蘿蔔", .vegetable, .kg),
                ("紅蘿蔔", .vegetable, .kg),
                ("洋蔥", .vegetable, .kg)
            ]
            var ingredients: [Ingredient] = []
            for (n, c, u) in ingSeeds {
                let ing = Ingredient(restaurantID: restaurant.id, name: n, category: c, unit: u)
                context.insert(ing)
                ingredients.append(ing)
            }

            let supplierSeeds: [(String, String?, String?)] = [
                ("阿明蔬果行", "0912-345-678", "aming_veg"),
                ("吉祥批發", "02-1234-5678", nil),
                ("惠民農場", nil, "huimin_farm")
            ]
            var suppliers: [Supplier] = []
            for (n, p, l) in supplierSeeds {
                let s = Supplier(restaurantID: restaurant.id, name: n, phone: p, lineID: l)
                context.insert(s)
                suppliers.append(s)
            }

            // a few sample quotes for first 3 ingredients
            let cal = Calendar(identifier: .gregorian)
            let today = Date()
            for (idx, ing) in ingredients.prefix(3).enumerated() {
                for (sIdx, supplier) in suppliers.enumerated() {
                    let basePrice: Decimal = [42, 38, 28][idx]
                    let bump: Decimal = Decimal(sIdx * 3)
                    let q = SupplierQuote(
                        supplierID: supplier.id,
                        ingredientID: ing.id,
                        quoteDate: cal.date(byAdding: .day, value: -sIdx, to: today) ?? today,
                        quotedPrice: basePrice + bump,
                        unit: .kg
                    )
                    context.insert(q)
                }
            }

            try context.save()
        } catch {
            // swallow; demo seeding failure should not crash app
        }
    }

    public func activeRestaurantID(in restaurants: [RestaurantProfile]) -> UUID {
        restaurants.first?.id ?? UUID()
    }

    public func ingredient(by id: UUID, in context: ModelContext) -> Ingredient? {
        let descriptor = FetchDescriptor<Ingredient>(predicate: #Predicate { $0.id == id })
        return try? context.fetch(descriptor).first
    }
}
