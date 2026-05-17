import Foundation

public enum AgriPriceAPIError: Error, Equatable {
    case transportFailed(String)
    case invalidResponse
    case decodingFailed(String)
    case unavailable
}

public protocol AgriPriceAPIClient {
    func fetchMarketPrices(
        from startDate: Date,
        to endDate: Date,
        itemName: String?,
        itemCode: String?,
        marketName: String?,
        marketCode: String?
    ) async throws -> [MarketPriceDTO]
}

/// Live client that talks to 農業部 open-data endpoint. Endpoint is overridable
/// to keep things testable and to allow swapping if the upstream API changes.
public final class LiveAgriPriceAPIClient: AgriPriceAPIClient {
    public static let defaultEndpoint = URL(string: "https://data.moa.gov.tw/Service/OpenData/FromM/FarmTransData.aspx")!

    private let endpoint: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let maxRetries: Int
    private let retryBaseDelayNanoseconds: UInt64
    private let cacheTTLSeconds: TimeInterval
    private let cache = MarketPriceResponseCache()

    public init(
        endpoint: URL = LiveAgriPriceAPIClient.defaultEndpoint,
        session: URLSession = .shared,
        maxRetries: Int = 2,
        retryBaseDelayNanoseconds: UInt64 = 500_000_000,
        cacheTTLSeconds: TimeInterval = 300
    ) {
        self.endpoint = endpoint
        self.session = session
        self.decoder = JSONDecoder()
        self.maxRetries = maxRetries
        self.retryBaseDelayNanoseconds = retryBaseDelayNanoseconds
        self.cacheTTLSeconds = cacheTTLSeconds
    }

    public func fetchMarketPrices(
        from startDate: Date,
        to endDate: Date,
        itemName: String?,
        itemCode: String?,
        marketName: String?,
        marketCode: String?
    ) async throws -> [MarketPriceDTO] {
        let request = URLRequest(url: endpoint)
        let cacheKey = ResponseCacheKey(
            startDate: startDate,
            endDate: endDate,
            itemName: itemName,
            itemCode: itemCode,
            marketName: marketName,
            marketCode: marketCode
        )
        if let cached = await cache.load(key: cacheKey, ttlSeconds: cacheTTLSeconds) {
            return cached
        }

        var lastError: Error?
        for attempt in 0...maxRetries {
            do {
                let (data, response) = try await session.data(for: request)
                guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                    throw AgriPriceAPIError.invalidResponse
                }
                let raw = try decoder.decode([MarketPriceDTO].self, from: data)
                let filtered = LocalDTOFilter.filter(
                    raw,
                    from: startDate,
                    to: endDate,
                    itemName: itemName,
                    itemCode: itemCode,
                    marketName: marketName,
                    marketCode: marketCode
                )
                await cache.save(key: cacheKey, value: filtered)
                return filtered
            } catch {
                lastError = error
                if attempt < maxRetries {
                    let delay = retryBaseDelayNanoseconds * UInt64(attempt + 1)
                    try? await Task.sleep(nanoseconds: delay)
                }
            }
        }
        if let apiError = lastError as? AgriPriceAPIError { throw apiError }
        throw AgriPriceAPIError.transportFailed(lastError?.localizedDescription ?? "Unknown error")
    }
}

public final class MockAgriPriceAPIClient: AgriPriceAPIClient {
    public enum MockError: Error {
        case resourceMissing
    }

    private let bundle: Bundle
    private let resourceName: String

    public init(bundle: Bundle? = nil, resourceName: String = "agri_price_mock") {
        self.bundle = bundle ?? ResourceBundleProvider.current
        self.resourceName = resourceName
    }

    public func fetchMarketPrices(
        from startDate: Date,
        to endDate: Date,
        itemName: String?,
        itemCode: String?,
        marketName: String?,
        marketCode: String?
    ) async throws -> [MarketPriceDTO] {
        guard let url = bundle.url(forResource: resourceName, withExtension: "json") else {
            throw MockError.resourceMissing
        }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let all = try decoder.decode([MarketPriceDTO].self, from: data)
        return LocalDTOFilter.filter(
            all,
            from: startDate,
            to: endDate,
            itemName: itemName,
            itemCode: itemCode,
            marketName: marketName,
            marketCode: marketCode
        )
    }
}

enum LocalDTOFilter {
    static func filter(
        _ dtos: [MarketPriceDTO],
        from startDate: Date,
        to endDate: Date,
        itemName: String?,
        itemCode: String?,
        marketName: String?,
        marketCode: String?
    ) -> [MarketPriceDTO] {
        dtos.filter { dto in
            let itemCodeTrim = dto.itemCode?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let itemNameTrim = dto.itemName.trimmingCharacters(in: .whitespacesAndNewlines)
            if itemCodeTrim == "rest" || itemNameTrim == "休市" { return false }
            if let itemName, !dto.itemName.contains(itemName) { return false }
            if let itemCode, dto.itemCode != itemCode { return false }
            if let marketName, !dto.marketName.contains(marketName) { return false }
            if let marketCode, dto.marketCode != marketCode { return false }
            // Date filter best-effort: if mapper fails we keep the row.
            if let date = try? MarketPriceMapper.parseDate(dto.tradeDateRaw) {
                if date < startDate || date > endDate { return false }
            }
            return true
        }
    }
}

private struct ResponseCacheKey: Hashable {
    let startDate: Date
    let endDate: Date
    let itemName: String?
    let itemCode: String?
    let marketName: String?
    let marketCode: String?
}

private actor MarketPriceResponseCache {
    private var storage: [ResponseCacheKey: (savedAt: Date, value: [MarketPriceDTO])] = [:]

    func load(key: ResponseCacheKey, ttlSeconds: TimeInterval) -> [MarketPriceDTO]? {
        guard let hit = storage[key] else { return nil }
        if Date().timeIntervalSince(hit.savedAt) > ttlSeconds {
            storage.removeValue(forKey: key)
            return nil
        }
        return hit.value
    }

    func save(key: ResponseCacheKey, value: [MarketPriceDTO]) {
        storage[key] = (savedAt: Date(), value: value)
    }
}
