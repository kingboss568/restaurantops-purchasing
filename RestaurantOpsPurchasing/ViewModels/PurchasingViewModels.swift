import Foundation
import SwiftData

@MainActor
public final class IngredientListViewModel: ObservableObject {
    @Published public var searchText: String = ""
    @Published public var ingredients: [Ingredient] = []
    @Published public var errorMessage: String?

    private let context: ModelContext
    private let restaurantID: UUID

    public init(context: ModelContext, restaurantID: UUID) {
        self.context = context
        self.restaurantID = restaurantID
    }

    public func reload() {
        do {
            let rid = restaurantID
            let descriptor = FetchDescriptor<Ingredient>(
                predicate: #Predicate { $0.restaurantID == rid },
                sortBy: [SortDescriptor(\Ingredient.name)]
            )
            let all = try context.fetch(descriptor)
            let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            ingredients = q.isEmpty ? all : all.filter { $0.name.contains(q) }
        } catch {
            errorMessage = "載入食材失敗：\(error.localizedDescription)"
            ingredients = []
        }
    }

    public func addIngredient(name: String, category: IngredientCategory, unit: UnitType) {
        let ing = Ingredient(restaurantID: restaurantID, name: name, category: category, unit: unit)
        context.insert(ing)
        try? context.save()
        reload()
    }

    public func delete(_ ingredient: Ingredient) {
        context.delete(ingredient)
        try? context.save()
        reload()
    }
}

@MainActor
public final class IngredientDetailViewModel: ObservableObject {
    @Published public var candidates: [IngredientMarketCandidate] = []
    @Published public var loading: Bool = false
    @Published public var errorMessage: String?

    public let ingredient: Ingredient
    private let context: ModelContext
    private let matcher: IngredientMarketMatcher
    private let repository: PurchasingRepository

    public init(ingredient: Ingredient, context: ModelContext, matcher: IngredientMarketMatcher, repository: PurchasingRepository) {
        self.ingredient = ingredient
        self.context = context
        self.matcher = matcher
        self.repository = repository
    }

    public func loadCandidates() async {
        loading = true
        defer { loading = false }
        do {
            let items = try repository.availableMarketItems()
            candidates = await matcher.candidates(for: ingredient.name, availableMarketItems: items)
        } catch {
            errorMessage = "載入候選失敗：\(error.localizedDescription)"
            candidates = []
        }
    }

    /// User-confirmed mapping. Only this method may mutate ingredient.linkedMarketItem*.
    public func confirm(candidate: IngredientMarketCandidate) {
        ingredient.linkedMarketItemCode = candidate.itemCode
        ingredient.linkedMarketItemName = candidate.itemName
        ingredient.updatedAt = .now
        let mapping = IngredientMarketMapping(
            restaurantID: ingredient.restaurantID,
            ingredientID: ingredient.id,
            marketItemCode: candidate.itemCode,
            marketItemName: candidate.itemName,
            confidence: candidate.confidence,
            source: .userConfirmed,
            isUserConfirmed: true,
            confirmedAt: .now
        )
        context.insert(mapping)
        try? context.save()
    }

    public func clearMapping() {
        ingredient.linkedMarketItemCode = nil
        ingredient.linkedMarketItemName = nil
        ingredient.updatedAt = .now
        try? context.save()
    }
}

@MainActor
public final class MarketPriceTrendViewModel: ObservableObject {
    @Published public var records: [MarketPriceRecord] = []
    @Published public var lastFetchLog: MarketPriceFetchLog?
    @Published public var isUsingCache: Bool = false
    @Published public var errorMessage: String?

    public let ingredient: Ingredient
    private let repository: PurchasingRepository

    public init(ingredient: Ingredient, repository: PurchasingRepository) {
        self.ingredient = ingredient
        self.repository = repository
    }

    public func reload(asOf date: Date = .now) {
        guard let code = ingredient.linkedMarketItemCode else {
            records = []
            return
        }
        do {
            records = try repository.latestMarketRecords(itemCode: code, marketCode: nil, asOf: date, days: 30)
            lastFetchLog = try repository.latestFetchLog(sourceName: "農業部農產品交易行情")
        } catch {
            errorMessage = "載入行情失敗：\(error.localizedDescription)"
        }
    }

    public func refresh() async {
        do {
            _ = try await repository.importMarketPrices(
                from: Calendar.current.date(byAdding: .day, value: -30, to: .now) ?? .now,
                to: .now,
                itemName: ingredient.linkedMarketItemName,
                itemCode: ingredient.linkedMarketItemCode,
                marketName: nil,
                marketCode: nil
            )
            isUsingCache = false
            reload()
        } catch {
            isUsingCache = true
            errorMessage = "更新行情失敗，已使用快取資料：\(error.localizedDescription)"
            reload()
        }
    }
}

@MainActor
public final class SupplierListViewModel: ObservableObject {
    @Published public var searchText: String = ""
    @Published public var suppliers: [Supplier] = []
    @Published public var errorMessage: String?

    private let context: ModelContext
    private let restaurantID: UUID

    public init(context: ModelContext, restaurantID: UUID) {
        self.context = context
        self.restaurantID = restaurantID
    }

    public func reload() {
        do {
            let rid = restaurantID
            let descriptor = FetchDescriptor<Supplier>(
                predicate: #Predicate { $0.restaurantID == rid },
                sortBy: [SortDescriptor(\Supplier.name)]
            )
            let all = try context.fetch(descriptor)
            let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            suppliers = q.isEmpty ? all : all.filter { $0.name.contains(q) }
        } catch {
            errorMessage = "載入供應商失敗：\(error.localizedDescription)"
            suppliers = []
        }
    }

    public func add(name: String, phone: String?, lineID: String?, note: String?) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return false }
        let supplier = Supplier(restaurantID: restaurantID, name: trimmed, phone: phone, lineID: lineID, note: note)
        context.insert(supplier)
        try? context.save()
        reload()
        return true
    }

    public func delete(_ supplier: Supplier) {
        context.delete(supplier)
        try? context.save()
        reload()
    }
}

@MainActor
public final class SupplierQuoteEntryViewModel: ObservableObject {
    public enum ValidationError: LocalizedError, Equatable {
        case invalidPrice
        case futureDate
        case missingSupplier
        case missingIngredient

        public var errorDescription: String? {
            switch self {
            case .invalidPrice: return "請輸入有效報價"
            case .futureDate: return "報價日期不可晚於今天"
            case .missingSupplier: return "請選擇供應商"
            case .missingIngredient: return "請選擇食材"
            }
        }
    }

    @Published public var supplierID: UUID?
    @Published public var ingredientID: UUID?
    @Published public var quoteDate: Date = .now
    @Published public var priceText: String = ""
    @Published public var unit: UnitType = .kg
    @Published public var minOrderQuantityText: String = ""
    @Published public var note: String = ""
    @Published public var unitMismatchWarning: String?

    private let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    public func validate() -> ValidationError? {
        guard supplierID != nil else { return .missingSupplier }
        guard ingredientID != nil else { return .missingIngredient }
        let trimmed = priceText.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: "")
        guard let p = Decimal(string: trimmed), p > 0 else { return .invalidPrice }
        if quoteDate > .now { return .futureDate }
        _ = p
        return nil
    }

    public func save() -> Result<SupplierQuote, ValidationError> {
        if let err = validate() { return .failure(err) }
        let priceTrim = priceText.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: "")
        let price = Decimal(string: priceTrim)!
        let moq: Decimal? = {
            let t = minOrderQuantityText.trimmingCharacters(in: .whitespaces)
            guard !t.isEmpty else { return nil }
            return Decimal(string: t)
        }()
        let quote = SupplierQuote(
            supplierID: supplierID!,
            ingredientID: ingredientID!,
            quoteDate: quoteDate,
            quotedPrice: price,
            unit: unit,
            minOrderQuantity: moq,
            note: note.isEmpty ? nil : note
        )
        context.insert(quote)
        try? context.save()
        return .success(quote)
    }
}

@MainActor
public final class PriceComparisonDashboardViewModel: ObservableObject {
    @Published public var result: PriceComparisonResult?
    @Published public var errorMessage: String?
    @Published public var lastFetchLog: MarketPriceFetchLog?

    public let ingredient: Ingredient
    private let context: ModelContext
    private let comparisonService: PriceComparisonService
    private let repository: PurchasingRepository
    private let intelligenceService: ProcurementIntelligenceService

    public init(
        ingredient: Ingredient,
        context: ModelContext,
        comparisonService: PriceComparisonService = DefaultPriceComparisonService(),
        repository: PurchasingRepository,
        intelligenceService: ProcurementIntelligenceService = DefaultProcurementIntelligenceService()
    ) {
        self.ingredient = ingredient
        self.context = context
        self.comparisonService = comparisonService
        self.repository = repository
        self.intelligenceService = intelligenceService
    }

    public func reload(asOf date: Date = .now) {
        do {
            let ingID = ingredient.id
            let quotes = try context.fetch(FetchDescriptor<SupplierQuote>(
                predicate: #Predicate { $0.ingredientID == ingID }
            ))
            let supplierIDs = Set(quotes.map { $0.supplierID })
            let allSuppliers = try context.fetch(FetchDescriptor<Supplier>())
            let suppliers = allSuppliers.filter { supplierIDs.contains($0.id) }

            let market: [MarketPriceRecord]
            if let code = ingredient.linkedMarketItemCode {
                market = try repository.latestMarketRecords(itemCode: code, marketCode: nil, asOf: date, days: 30)
            } else {
                market = []
            }
            let base = try comparisonService.compare(
                ingredient: ingredient,
                suppliers: suppliers,
                supplierQuotes: quotes,
                marketRecords: market,
                asOf: date
            )
            result = PriceComparisonResult(
                ingredientID: base.ingredientID,
                ingredientName: base.ingredientName,
                marketAverage7Days: base.marketAverage7Days,
                marketAverage30Days: base.marketAverage30Days,
                latestMarketAverage: base.latestMarketAverage,
                supplierComparisons: base.supplierComparisons,
                generatedAt: base.generatedAt,
                warnings: base.warnings,
                intelligence: intelligenceService.buildIntelligence(result: base)
            )
            lastFetchLog = try repository.latestFetchLog(sourceName: "農業部農產品交易行情")
        } catch {
            errorMessage = "載入比較失敗：\(error.localizedDescription)"
        }
    }
}

@MainActor
public final class NegotiationAssistantViewModel: ObservableObject {
    @Published public var tone: NegotiationTone = .polite
    @Published public var editedMessage: String = ""
    @Published public var draft: NegotiationDraft?
    @Published public var isGenerating: Bool = false
    @Published public var errorMessage: String?

    public let comparison: SupplierPriceComparison
    public let ingredientName: String
    public let restaurantName: String?
    public let marketAverage7Days: Decimal?
    public let marketAverage30Days: Decimal?

    private let ai: NegotiationDraftAI

    public init(
        comparison: SupplierPriceComparison,
        ingredientName: String,
        restaurantName: String?,
        marketAverage7Days: Decimal?,
        marketAverage30Days: Decimal?,
        ai: NegotiationDraftAI = FoundationModelsNegotiationDraftAI()
    ) {
        self.comparison = comparison
        self.ingredientName = ingredientName
        self.restaurantName = restaurantName
        self.marketAverage7Days = marketAverage7Days
        self.marketAverage30Days = marketAverage30Days
        self.ai = ai
    }

    public func generate() async {
        isGenerating = true
        defer { isGenerating = false }
        let ctx = NegotiationContext(
            restaurantName: restaurantName,
            supplierName: comparison.supplierName,
            ingredientName: ingredientName,
            quotedPrice: comparison.quotedPrice,
            marketAverage7Days: marketAverage7Days,
            marketAverage30Days: marketAverage30Days,
            differencePercent: comparison.differencePercent,
            recentTrendSummary: nil,
            tone: tone
        )
        do {
            let d = try await ai.generateDraft(context: ctx)
            draft = d
            editedMessage = d.message
        } catch {
            // Fallback path - explicitly route through template
            let d = try? await TemplateNegotiationDraftAI().generateDraft(context: ctx)
            draft = d
            editedMessage = d?.message ?? ""
            errorMessage = "AI 暫時無法使用，已改用內建範本。"
        }
    }
}
