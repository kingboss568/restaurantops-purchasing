import Foundation
import SwiftData

public protocol PurchasingRepository {
    func importMarketPrices(
        from startDate: Date,
        to endDate: Date,
        itemName: String?,
        itemCode: String?,
        marketName: String?,
        marketCode: String?
    ) async throws -> MarketPriceImportResult

    func latestMarketRecords(
        itemCode: String,
        marketCode: String?,
        asOf date: Date,
        days: Int
    ) throws -> [MarketPriceRecord]

    func latestFetchLog(sourceName: String) throws -> MarketPriceFetchLog?

    func availableMarketItems() throws -> [MarketItem]
}

public enum PurchasingRepositoryError: Error {
    case unavailable
}

public final class DefaultPurchasingRepository: PurchasingRepository {
    private let apiClient: AgriPriceAPIClient
    private let mapper: MarketPriceMapper
    private let context: ModelContext
    private let sourceName: String

    public init(
        apiClient: AgriPriceAPIClient,
        context: ModelContext,
        mapper: MarketPriceMapper = MarketPriceMapper(),
        sourceName: String = "農業部農產品交易行情"
    ) {
        self.apiClient = apiClient
        self.context = context
        self.mapper = mapper
        self.sourceName = sourceName
    }

    public func importMarketPrices(
        from startDate: Date,
        to endDate: Date,
        itemName: String?,
        itemCode: String?,
        marketName: String?,
        marketCode: String?
    ) async throws -> MarketPriceImportResult {
        let startedAt = Date()
        let log = MarketPriceFetchLog(sourceName: sourceName, startedAt: startedAt, status: .partial, recordCount: 0)
        context.insert(log)

        var inserted = 0
        var updated = 0
        var skipped = 0
        var errors = 0
        var errorMessage: String?

        do {
            let dtos = try await apiClient.fetchMarketPrices(
                from: startDate,
                to: endDate,
                itemName: itemName,
                itemCode: itemCode,
                marketName: marketName,
                marketCode: marketCode
            )
            let now = Date()
            for dto in dtos {
                do {
                    let input = try mapper.map(dto, sourceName: sourceName, fetchedAt: now)
                    let key = input.sourceKey
                    let descriptor = FetchDescriptor<MarketPriceRecord>(predicate: #Predicate { $0.sourceKey == key })
                    if let existing = try context.fetch(descriptor).first {
                        existing.categoryCode = input.categoryCode
                        existing.itemCode = input.itemCode
                        existing.itemName = input.itemName
                        existing.marketCode = input.marketCode
                        existing.marketName = input.marketName
                        existing.tradeDate = input.tradeDate
                        existing.highPrice = input.highPrice
                        existing.midPrice = input.midPrice
                        existing.lowPrice = input.lowPrice
                        existing.averagePrice = input.averagePrice
                        existing.volume = input.volume
                        existing.unit = input.unit
                        existing.sourceName = input.sourceName
                        existing.fetchedAt = input.fetchedAt
                        updated += 1
                    } else {
                        let record = MarketPriceRecord(
                            categoryCode: input.categoryCode,
                            itemCode: input.itemCode,
                            itemName: input.itemName,
                            marketCode: input.marketCode,
                            marketName: input.marketName,
                            tradeDate: input.tradeDate,
                            highPrice: input.highPrice,
                            midPrice: input.midPrice,
                            lowPrice: input.lowPrice,
                            averagePrice: input.averagePrice,
                            volume: input.volume,
                            unit: input.unit,
                            sourceName: input.sourceName,
                            fetchedAt: input.fetchedAt,
                            sourceKey: input.sourceKey
                        )
                        context.insert(record)
                        inserted += 1
                    }
                } catch MarketPriceMappingError.missingAveragePrice,
                        MarketPriceMappingError.unparseableAveragePrice {
                    skipped += 1
                } catch {
                    errors += 1
                }
            }
            try context.save()
            log.finishedAt = Date()
            log.recordCount = inserted + updated
            log.status = (errors == 0 && skipped == 0) ? .success : .partial
        } catch {
            errors += 1
            errorMessage = String(describing: error)
            log.finishedAt = Date()
            log.status = .failed
            log.errorMessage = errorMessage
            try? context.save()
        }

        return MarketPriceImportResult(
            insertedCount: inserted,
            updatedCount: updated,
            skippedCount: skipped,
            errorCount: errors,
            startedAt: startedAt,
            finishedAt: log.finishedAt ?? Date()
        )
    }

    public func latestMarketRecords(
        itemCode: String,
        marketCode: String?,
        asOf date: Date,
        days: Int
    ) throws -> [MarketPriceRecord] {
        var descriptor = FetchDescriptor<MarketPriceRecord>(
            predicate: #Predicate { $0.itemCode == itemCode },
            sortBy: [SortDescriptor(\MarketPriceRecord.tradeDate, order: .reverse)]
        )
        descriptor.fetchLimit = max(days * 5, 30)
        let all = try context.fetch(descriptor)
        let calendar = Calendar(identifier: .gregorian)
        let start = calendar.date(byAdding: .day, value: -(days - 1), to: date) ?? date
        return all.filter { record in
            record.tradeDate >= start && record.tradeDate <= date &&
            (marketCode == nil || record.marketCode == marketCode)
        }
    }

    public func latestFetchLog(sourceName: String) throws -> MarketPriceFetchLog? {
        var descriptor = FetchDescriptor<MarketPriceFetchLog>(
            predicate: #Predicate { $0.sourceName == sourceName },
            sortBy: [SortDescriptor(\MarketPriceFetchLog.startedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    public func availableMarketItems() throws -> [MarketItem] {
        let descriptor = FetchDescriptor<MarketPriceRecord>(sortBy: [SortDescriptor(\MarketPriceRecord.itemName)])
        let records = try context.fetch(descriptor)
        var seen: Set<String> = []
        var items: [MarketItem] = []
        for r in records {
            if seen.contains(r.itemCode) { continue }
            seen.insert(r.itemCode)
            items.append(MarketItem(itemCode: r.itemCode, itemName: r.itemName))
        }
        return items
    }
}
