import Foundation

public struct NormalizedPrice: Equatable {
    public let price: Decimal
    public let unit: UnitType

    public init(price: Decimal, unit: UnitType) {
        self.price = price
        self.unit = unit
    }
}

public struct MarketItem: Identifiable, Equatable, Hashable {
    public var id: String { itemCode }
    public let itemCode: String
    public let itemName: String

    public init(itemCode: String, itemName: String) {
        self.itemCode = itemCode
        self.itemName = itemName
    }
}

public struct IngredientMarketCandidate: Identifiable, Equatable {
    public let id: UUID
    public let itemCode: String
    public let itemName: String
    public let confidence: Decimal
    public let source: MappingSource
    public let reason: String

    public init(
        id: UUID = UUID(),
        itemCode: String,
        itemName: String,
        confidence: Decimal,
        source: MappingSource,
        reason: String
    ) {
        self.id = id
        self.itemCode = itemCode
        self.itemName = itemName
        self.confidence = confidence
        self.source = source
        self.reason = reason
    }
}

public struct MarketPriceRecordInput: Equatable {
    public let categoryCode: String?
    public let itemCode: String
    public let itemName: String
    public let marketCode: String?
    public let marketName: String
    public let tradeDate: Date
    public let highPrice: Decimal?
    public let midPrice: Decimal?
    public let lowPrice: Decimal?
    public let averagePrice: Decimal
    public let volume: Decimal?
    public let unit: String
    public let sourceName: String
    public let fetchedAt: Date
    public let sourceKey: String

    public init(
        categoryCode: String?,
        itemCode: String,
        itemName: String,
        marketCode: String?,
        marketName: String,
        tradeDate: Date,
        highPrice: Decimal?,
        midPrice: Decimal?,
        lowPrice: Decimal?,
        averagePrice: Decimal,
        volume: Decimal?,
        unit: String,
        sourceName: String,
        fetchedAt: Date,
        sourceKey: String
    ) {
        self.categoryCode = categoryCode
        self.itemCode = itemCode
        self.itemName = itemName
        self.marketCode = marketCode
        self.marketName = marketName
        self.tradeDate = tradeDate
        self.highPrice = highPrice
        self.midPrice = midPrice
        self.lowPrice = lowPrice
        self.averagePrice = averagePrice
        self.volume = volume
        self.unit = unit
        self.sourceName = sourceName
        self.fetchedAt = fetchedAt
        self.sourceKey = sourceKey
    }
}

public struct MarketPriceImportResult: Equatable {
    public let insertedCount: Int
    public let updatedCount: Int
    public let skippedCount: Int
    public let errorCount: Int
    public let startedAt: Date
    public let finishedAt: Date

    public init(
        insertedCount: Int,
        updatedCount: Int,
        skippedCount: Int,
        errorCount: Int,
        startedAt: Date,
        finishedAt: Date
    ) {
        self.insertedCount = insertedCount
        self.updatedCount = updatedCount
        self.skippedCount = skippedCount
        self.errorCount = errorCount
        self.startedAt = startedAt
        self.finishedAt = finishedAt
    }
}

public struct SupplierPriceComparison: Identifiable, Equatable {
    public let id: UUID
    public let supplierID: UUID
    public let supplierName: String
    public let quoteID: UUID
    public let quoteDate: Date
    public let quotedPrice: Decimal
    public let quotedUnit: UnitType
    public let normalizedQuotedPrice: Decimal?
    public let normalizedUnit: UnitType?
    public let marketReferencePrice: Decimal?
    public let differenceAmount: Decimal?
    public let differencePercent: Decimal?
    public let rank: Int?
    public let status: PriceComparisonStatus

    public init(
        id: UUID = UUID(),
        supplierID: UUID,
        supplierName: String,
        quoteID: UUID,
        quoteDate: Date,
        quotedPrice: Decimal,
        quotedUnit: UnitType,
        normalizedQuotedPrice: Decimal?,
        normalizedUnit: UnitType?,
        marketReferencePrice: Decimal?,
        differenceAmount: Decimal?,
        differencePercent: Decimal?,
        rank: Int?,
        status: PriceComparisonStatus
    ) {
        self.id = id
        self.supplierID = supplierID
        self.supplierName = supplierName
        self.quoteID = quoteID
        self.quoteDate = quoteDate
        self.quotedPrice = quotedPrice
        self.quotedUnit = quotedUnit
        self.normalizedQuotedPrice = normalizedQuotedPrice
        self.normalizedUnit = normalizedUnit
        self.marketReferencePrice = marketReferencePrice
        self.differenceAmount = differenceAmount
        self.differencePercent = differencePercent
        self.rank = rank
        self.status = status
    }
}

public struct PriceComparisonResult: Equatable {
    public let ingredientID: UUID
    public let ingredientName: String
    public let marketAverage7Days: Decimal?
    public let marketAverage30Days: Decimal?
    public let latestMarketAverage: Decimal?
    public let supplierComparisons: [SupplierPriceComparison]
    public let generatedAt: Date
    public let warnings: [String]
    public let intelligence: ProcurementIntelligence?

    public init(
        ingredientID: UUID,
        ingredientName: String,
        marketAverage7Days: Decimal?,
        marketAverage30Days: Decimal?,
        latestMarketAverage: Decimal?,
        supplierComparisons: [SupplierPriceComparison],
        generatedAt: Date,
        warnings: [String],
        intelligence: ProcurementIntelligence? = nil
    ) {
        self.ingredientID = ingredientID
        self.ingredientName = ingredientName
        self.marketAverage7Days = marketAverage7Days
        self.marketAverage30Days = marketAverage30Days
        self.latestMarketAverage = latestMarketAverage
        self.supplierComparisons = supplierComparisons
        self.generatedAt = generatedAt
        self.warnings = warnings
        self.intelligence = intelligence
    }
}

public struct ProcurementIntelligence: Equatable {
    public let suggestedTargetPrice: Decimal?
    public let annualSavingsEstimate: Decimal?
    public let riskScore: Int
    public let negotiationLeverage: String

    public init(
        suggestedTargetPrice: Decimal?,
        annualSavingsEstimate: Decimal?,
        riskScore: Int,
        negotiationLeverage: String
    ) {
        self.suggestedTargetPrice = suggestedTargetPrice
        self.annualSavingsEstimate = annualSavingsEstimate
        self.riskScore = riskScore
        self.negotiationLeverage = negotiationLeverage
    }
}

public struct NegotiationContext: Equatable {
    public let restaurantName: String?
    public let supplierName: String
    public let ingredientName: String
    public let quotedPrice: Decimal
    public let marketAverage7Days: Decimal?
    public let marketAverage30Days: Decimal?
    public let differencePercent: Decimal?
    public let recentTrendSummary: String?
    public let tone: NegotiationTone

    public init(
        restaurantName: String?,
        supplierName: String,
        ingredientName: String,
        quotedPrice: Decimal,
        marketAverage7Days: Decimal?,
        marketAverage30Days: Decimal?,
        differencePercent: Decimal?,
        recentTrendSummary: String?,
        tone: NegotiationTone
    ) {
        self.restaurantName = restaurantName
        self.supplierName = supplierName
        self.ingredientName = ingredientName
        self.quotedPrice = quotedPrice
        self.marketAverage7Days = marketAverage7Days
        self.marketAverage30Days = marketAverage30Days
        self.differencePercent = differencePercent
        self.recentTrendSummary = recentTrendSummary
        self.tone = tone
    }
}

public struct NegotiationDraft: Equatable {
    public let message: String
    public let fallbackUsed: Bool
    public let disclaimer: String

    public init(message: String, fallbackUsed: Bool, disclaimer: String = "本訊息為輔助資訊，不構成專業意見，請依實際洽談情況調整。") {
        self.message = message
        self.fallbackUsed = fallbackUsed
        self.disclaimer = disclaimer
    }
}
