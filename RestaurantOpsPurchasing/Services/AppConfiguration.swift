import Foundation

public enum MarketDataMode: String {
    case live
    case mock
    case liveWithMockFallback
}

public struct AppConfiguration {
    public let marketDataMode: MarketDataMode
    public let liveEndpoint: URL
    public let proProductID: String

    public init(
        marketDataMode: MarketDataMode,
        liveEndpoint: URL,
        proProductID: String
    ) {
        self.marketDataMode = marketDataMode
        self.liveEndpoint = liveEndpoint
        self.proProductID = proProductID
    }

    public static func load() -> AppConfiguration {
        let env = ProcessInfo.processInfo.environment
        let mode = MarketDataMode(rawValue: env["MARKET_DATA_MODE"] ?? "") ?? .liveWithMockFallback
        let endpointString = env["AGRI_PRICE_ENDPOINT"] ?? LiveAgriPriceAPIClient.defaultEndpoint.absoluteString
        let endpoint = URL(string: endpointString) ?? LiveAgriPriceAPIClient.defaultEndpoint
        let productID = env["PRO_PRODUCT_ID"] ?? "com.restaurantops.purchasing.pro.monthly"
        return AppConfiguration(
            marketDataMode: mode,
            liveEndpoint: endpoint,
            proProductID: productID
        )
    }
}

public final class FallbackAgriPriceAPIClient: AgriPriceAPIClient {
    private let primary: AgriPriceAPIClient
    private let fallback: AgriPriceAPIClient

    public init(primary: AgriPriceAPIClient, fallback: AgriPriceAPIClient) {
        self.primary = primary
        self.fallback = fallback
    }

    public func fetchMarketPrices(
        from startDate: Date,
        to endDate: Date,
        itemName: String?,
        itemCode: String?,
        marketName: String?,
        marketCode: String?
    ) async throws -> [MarketPriceDTO] {
        do {
            return try await primary.fetchMarketPrices(
                from: startDate,
                to: endDate,
                itemName: itemName,
                itemCode: itemCode,
                marketName: marketName,
                marketCode: marketCode
            )
        } catch {
            return try await fallback.fetchMarketPrices(
                from: startDate,
                to: endDate,
                itemName: itemName,
                itemCode: itemCode,
                marketName: marketName,
                marketCode: marketCode
            )
        }
    }
}
