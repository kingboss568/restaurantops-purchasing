import SwiftUI

@MainActor
public final class AppRuntimeSettings: ObservableObject {
    @AppStorage("runtime.marketDataMode") private var marketDataModeRaw: String = ""
    @AppStorage("runtime.endpoint") private var endpointRaw: String = ""
    @AppStorage("runtime.maxRetries") private var maxRetriesRaw: Int = 2
    @AppStorage("runtime.cacheTTL") private var cacheTTLRaw: Double = 300

    @Published public var marketDataMode: MarketDataMode = .liveWithMockFallback
    @Published public var endpoint: String = LiveAgriPriceAPIClient.defaultEndpoint.absoluteString
    @Published public var maxRetries: Int = 2
    @Published public var cacheTTL: Double = 300

    public init() {
        load()
    }

    public func load() {
        if let mode = MarketDataMode(rawValue: marketDataModeRaw), !marketDataModeRaw.isEmpty {
            marketDataMode = mode
        }
        if !endpointRaw.isEmpty {
            endpoint = endpointRaw
        }
        maxRetries = max(0, min(5, maxRetriesRaw))
        cacheTTL = max(0, min(3600, cacheTTLRaw))
    }

    public func save() {
        marketDataModeRaw = marketDataMode.rawValue
        endpointRaw = endpoint
        maxRetriesRaw = maxRetries
        cacheTTLRaw = cacheTTL
    }

    public func effectiveConfiguration(base: AppConfiguration) -> AppConfiguration {
        AppConfiguration(
            marketDataMode: marketDataMode,
            liveEndpoint: URL(string: endpoint) ?? base.liveEndpoint,
            proProductID: base.proProductID
        )
    }
}

public extension MarketDataMode {
    var displayName: String {
        switch self {
        case .live:
            return "正式 API"
        case .mock:
            return "Mock 資料"
        case .liveWithMockFallback:
            return "正式 + fallback"
        }
    }
}
