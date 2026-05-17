import Foundation
import SwiftData

@Model
public final class RestaurantProfile {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var createdAt: Date

    public init(id: UUID = UUID(), name: String, createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
    }
}

@Model
public final class Ingredient {
    @Attribute(.unique) public var id: UUID
    public var restaurantID: UUID
    public var name: String
    public var category: IngredientCategory
    public var unit: UnitType
    public var defaultWasteRate: Decimal
    public var linkedMarketItemCode: String?
    public var linkedMarketItemName: String?
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        restaurantID: UUID,
        name: String,
        category: IngredientCategory,
        unit: UnitType,
        defaultWasteRate: Decimal = 0,
        linkedMarketItemCode: String? = nil,
        linkedMarketItemName: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.restaurantID = restaurantID
        self.name = name
        self.category = category
        self.unit = unit
        self.defaultWasteRate = defaultWasteRate
        self.linkedMarketItemCode = linkedMarketItemCode
        self.linkedMarketItemName = linkedMarketItemName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

@Model
public final class MarketPriceRecord {
    @Attribute(.unique) public var id: UUID
    public var categoryCode: String?
    public var itemCode: String
    public var itemName: String
    public var marketCode: String?
    public var marketName: String
    public var tradeDate: Date
    public var highPrice: Decimal?
    public var midPrice: Decimal?
    public var lowPrice: Decimal?
    public var averagePrice: Decimal
    public var volume: Decimal?
    public var unit: String
    public var sourceName: String
    public var fetchedAt: Date
    public var sourceKey: String

    public init(
        id: UUID = UUID(),
        categoryCode: String? = nil,
        itemCode: String,
        itemName: String,
        marketCode: String? = nil,
        marketName: String,
        tradeDate: Date,
        highPrice: Decimal? = nil,
        midPrice: Decimal? = nil,
        lowPrice: Decimal? = nil,
        averagePrice: Decimal,
        volume: Decimal? = nil,
        unit: String = "kg",
        sourceName: String,
        fetchedAt: Date = .now,
        sourceKey: String
    ) {
        self.id = id
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

@Model
public final class Supplier {
    @Attribute(.unique) public var id: UUID
    public var restaurantID: UUID
    public var name: String
    public var phone: String?
    public var lineID: String?
    public var note: String?
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        restaurantID: UUID,
        name: String,
        phone: String? = nil,
        lineID: String? = nil,
        note: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.restaurantID = restaurantID
        self.name = name
        self.phone = phone
        self.lineID = lineID
        self.note = note
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

@Model
public final class SupplierQuote {
    @Attribute(.unique) public var id: UUID
    public var supplierID: UUID
    public var ingredientID: UUID
    public var quoteDate: Date
    public var quotedPrice: Decimal
    public var unit: UnitType
    public var minOrderQuantity: Decimal?
    public var note: String?
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        supplierID: UUID,
        ingredientID: UUID,
        quoteDate: Date,
        quotedPrice: Decimal,
        unit: UnitType,
        minOrderQuantity: Decimal? = nil,
        note: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.supplierID = supplierID
        self.ingredientID = ingredientID
        self.quoteDate = quoteDate
        self.quotedPrice = quotedPrice
        self.unit = unit
        self.minOrderQuantity = minOrderQuantity
        self.note = note
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

@Model
public final class IngredientMarketMapping {
    @Attribute(.unique) public var id: UUID
    public var restaurantID: UUID
    public var ingredientID: UUID
    public var marketItemCode: String
    public var marketItemName: String
    public var confidence: Decimal
    public var source: MappingSource
    public var isUserConfirmed: Bool
    public var confirmedAt: Date?
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        restaurantID: UUID,
        ingredientID: UUID,
        marketItemCode: String,
        marketItemName: String,
        confidence: Decimal,
        source: MappingSource,
        isUserConfirmed: Bool = false,
        confirmedAt: Date? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.restaurantID = restaurantID
        self.ingredientID = ingredientID
        self.marketItemCode = marketItemCode
        self.marketItemName = marketItemName
        self.confidence = confidence
        self.source = source
        self.isUserConfirmed = isUserConfirmed
        self.confirmedAt = confirmedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

@Model
public final class MarketPriceFetchLog {
    @Attribute(.unique) public var id: UUID
    public var sourceName: String
    public var startedAt: Date
    public var finishedAt: Date?
    public var status: FetchStatus
    public var recordCount: Int
    public var errorMessage: String?

    public init(
        id: UUID = UUID(),
        sourceName: String,
        startedAt: Date = .now,
        finishedAt: Date? = nil,
        status: FetchStatus,
        recordCount: Int = 0,
        errorMessage: String? = nil
    ) {
        self.id = id
        self.sourceName = sourceName
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        self.status = status
        self.recordCount = recordCount
        self.errorMessage = errorMessage
    }
}
