import Foundation

public protocol PriceComparisonService {
    func compare(
        ingredient: Ingredient,
        suppliers: [Supplier],
        supplierQuotes: [SupplierQuote],
        marketRecords: [MarketPriceRecord],
        asOf date: Date
    ) throws -> PriceComparisonResult
}

public struct DefaultPriceComparisonService: PriceComparisonService {
    private let unitConverter: UnitConversionService
    private let calendar: Calendar

    public init(unitConverter: UnitConversionService = DefaultUnitConversionService(), calendar: Calendar = Calendar(identifier: .gregorian)) {
        self.unitConverter = unitConverter
        self.calendar = calendar
    }

    public func compare(
        ingredient: Ingredient,
        suppliers: [Supplier],
        supplierQuotes: [SupplierQuote],
        marketRecords: [MarketPriceRecord],
        asOf date: Date
    ) throws -> PriceComparisonResult {
        let supplierByID = Dictionary(uniqueKeysWithValues: suppliers.map { ($0.id, $0) })
        let relevant = supplierQuotes.filter { $0.ingredientID == ingredient.id }

        // Restrict to mapped market records for this ingredient if linked.
        let scopedMarket: [MarketPriceRecord]
        if let code = ingredient.linkedMarketItemCode {
            scopedMarket = marketRecords.filter { $0.itemCode == code }
        } else {
            scopedMarket = []
        }

        var warnings: [String] = []
        if ingredient.linkedMarketItemCode == nil {
            warnings.append("尚未對應市場品項，無法計算市場參考價。")
        }
        if scopedMarket.isEmpty && ingredient.linkedMarketItemCode != nil {
            warnings.append("找不到對應市場行情資料。")
        }

        let avg7 = average(records: scopedMarket, daysBack: 7, asOf: date)
        let avg30 = average(records: scopedMarket, daysBack: 30, asOf: date)
        let latest = latestAverage(records: scopedMarket, asOf: date)

        let marketReference: Decimal? = latest ?? avg7 ?? avg30

        // Build comparisons
        var prelim: [(comp: SupplierPriceComparison, sortable: Decimal?)] = []
        for quote in relevant {
            let supplier = supplierByID[quote.supplierID]
            let supplierName = supplier?.name ?? "未知供應商"

            var normalized: NormalizedPrice?
            var status: PriceComparisonStatus = .nearMarket
            var unitMismatch = false
            do {
                normalized = try unitConverter.normalizePrice(price: quote.quotedPrice, from: quote.unit, ingredient: ingredient)
            } catch {
                unitMismatch = true
            }

            let normalizedPrice = normalized?.price
            let normalizedUnit = normalized?.unit

            let diffAmount: Decimal?
            let diffPercent: Decimal?
            if unitMismatch {
                status = .unitMismatch
                diffAmount = nil
                diffPercent = nil
            } else if let np = normalizedPrice, let ref = marketReference, ref != 0 {
                let amount = np - ref
                let percent = (amount / ref) * 100
                diffAmount = amount
                diffPercent = percent
                if percent > 5 {
                    status = .higherThanMarket
                } else if percent < -5 {
                    status = .cheaperThanMarket
                } else {
                    status = .nearMarket
                }
            } else {
                status = .missingMarketData
                diffAmount = nil
                diffPercent = nil
            }

            let comp = SupplierPriceComparison(
                supplierID: quote.supplierID,
                supplierName: supplierName,
                quoteID: quote.id,
                quoteDate: quote.quoteDate,
                quotedPrice: quote.quotedPrice,
                quotedUnit: quote.unit,
                normalizedQuotedPrice: normalizedPrice,
                normalizedUnit: normalizedUnit,
                marketReferencePrice: marketReference,
                differenceAmount: diffAmount,
                differencePercent: diffPercent,
                rank: nil,
                status: status
            )
            let sortable: Decimal?
            if status == .missingMarketData {
                // still rank by normalized price if exists; spec says rank only comparable & unit consistent
                sortable = nil
            } else if status == .unitMismatch {
                sortable = nil
            } else {
                sortable = normalizedPrice
            }
            prelim.append((comp, sortable))
        }

        // Rank: lower normalized price -> better rank. Stable by quoteDate desc on tie.
        let rankable = prelim.enumerated()
            .filter { $0.element.sortable != nil }
            .sorted { lhs, rhs in
                let lp = lhs.element.sortable!
                let rp = rhs.element.sortable!
                if lp == rp {
                    return lhs.element.comp.quoteDate > rhs.element.comp.quoteDate
                }
                return lp < rp
            }

        var rankByIndex: [Int: Int] = [:]
        for (rank, item) in rankable.enumerated() {
            rankByIndex[item.offset] = rank + 1
        }

        let finalComparisons = prelim.enumerated().map { idx, item -> SupplierPriceComparison in
            let r = rankByIndex[idx]
            let c = item.comp
            return SupplierPriceComparison(
                id: c.id,
                supplierID: c.supplierID,
                supplierName: c.supplierName,
                quoteID: c.quoteID,
                quoteDate: c.quoteDate,
                quotedPrice: c.quotedPrice,
                quotedUnit: c.quotedUnit,
                normalizedQuotedPrice: c.normalizedQuotedPrice,
                normalizedUnit: c.normalizedUnit,
                marketReferencePrice: c.marketReferencePrice,
                differenceAmount: c.differenceAmount,
                differencePercent: c.differencePercent,
                rank: r,
                status: c.status
            )
        }

        return PriceComparisonResult(
            ingredientID: ingredient.id,
            ingredientName: ingredient.name,
            marketAverage7Days: avg7,
            marketAverage30Days: avg30,
            latestMarketAverage: latest,
            supplierComparisons: finalComparisons,
            generatedAt: date,
            warnings: warnings
        )
    }

    private func average(records: [MarketPriceRecord], daysBack: Int, asOf: Date) -> Decimal? {
        guard let start = calendar.date(byAdding: .day, value: -(daysBack - 1), to: asOf) else { return nil }
        let scoped = records.filter { $0.tradeDate >= start && $0.tradeDate <= asOf }
        guard !scoped.isEmpty else { return nil }

        // volume-weighted average among those with volume > 0
        let withVolume = scoped.filter { ($0.volume ?? 0) > 0 }
        if !withVolume.isEmpty {
            var num = Decimal.zero
            var den = Decimal.zero
            for r in withVolume {
                let v = r.volume!
                num += r.averagePrice * v
                den += v
            }
            if den != 0 {
                return num / den
            }
        }

        let total = scoped.reduce(Decimal.zero) { $0 + $1.averagePrice }
        return total / Decimal(scoped.count)
    }

    private func latestAverage(records: [MarketPriceRecord], asOf: Date) -> Decimal? {
        let scoped = records.filter { $0.tradeDate <= asOf }
        guard let latestDate = scoped.map(\.tradeDate).max() else { return nil }
        let sameDay = scoped.filter { calendar.isDate($0.tradeDate, inSameDayAs: latestDate) }
        guard !sameDay.isEmpty else { return nil }

        let withVolume = sameDay.filter { ($0.volume ?? 0) > 0 }
        if !withVolume.isEmpty {
            var num = Decimal.zero
            var den = Decimal.zero
            for r in withVolume {
                let v = r.volume!
                num += r.averagePrice * v
                den += v
            }
            if den != 0 { return num / den }
        }
        let total = sameDay.reduce(Decimal.zero) { $0 + $1.averagePrice }
        return total / Decimal(sameDay.count)
    }
}
