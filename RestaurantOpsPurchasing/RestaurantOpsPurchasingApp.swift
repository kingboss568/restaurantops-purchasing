import SwiftData
import SwiftUI

@main
struct RestaurantOpsPurchasingApp: App {
    @State private var store = PurchasingDemoStore.preview
    private let configuration = AppConfiguration.load()

    var body: some Scene {
        WindowGroup {
            AppShellView(store: store, configuration: configuration)
        }
        .modelContainer(for: [
            RestaurantProfile.self,
            Ingredient.self,
            MarketPriceRecord.self,
            Supplier.self,
            SupplierQuote.self,
            IngredientMarketMapping.self,
            MarketPriceFetchLog.self
        ])
    }
}
