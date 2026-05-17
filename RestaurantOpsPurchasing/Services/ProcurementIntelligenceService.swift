import Foundation

public protocol ProcurementIntelligenceService {
    func buildIntelligence(result: PriceComparisonResult) -> ProcurementIntelligence
}

public struct DefaultProcurementIntelligenceService: ProcurementIntelligenceService {
    public init() {}

    public func buildIntelligence(result: PriceComparisonResult) -> ProcurementIntelligence {
        let comparable = result.supplierComparisons.compactMap { $0.normalizedQuotedPrice }
        let minPrice = comparable.min()
        let market = result.marketAverage7Days ?? result.latestMarketAverage
        let target = minPrice.flatMap { low in
            guard let market else { return low }
            let blended = (low * Decimal(7) + market * Decimal(3)) / Decimal(10)
            return blended
        }

        let diffPercents = result.supplierComparisons.compactMap { $0.differencePercent }
        let overMarketCount = diffPercents.filter { $0 > 8 }.count
        let riskScore = min(100, overMarketCount * 20 + (result.warnings.count * 10))
        let annualSavingsEstimate = estimateAnnualSaving(
            targetPrice: target,
            comparisons: result.supplierComparisons
        )
        let leverage = leverageText(riskScore: riskScore, warnings: result.warnings)
        return ProcurementIntelligence(
            suggestedTargetPrice: target,
            annualSavingsEstimate: annualSavingsEstimate,
            riskScore: riskScore,
            negotiationLeverage: leverage
        )
    }

    private func estimateAnnualSaving(targetPrice: Decimal?, comparisons: [SupplierPriceComparison]) -> Decimal? {
        guard let targetPrice else { return nil }
        guard let currentAvg = average(comparisons.compactMap { $0.normalizedQuotedPrice }) else { return nil }
        let savingPerUnit = max(0, currentAvg - targetPrice)
        let baselineMonthlyUnits = Decimal(120)
        return savingPerUnit * baselineMonthlyUnits * Decimal(12)
    }

    private func average(_ values: [Decimal]) -> Decimal? {
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Decimal(values.count)
    }

    private func leverageText(riskScore: Int, warnings: [String]) -> String {
        if riskScore >= 70 {
            return "價格波動高，建議採用分批下單與雙供應商策略。"
        }
        if !warnings.isEmpty {
            return "行情資料有缺口，先鎖短週期議價條款再談長約。"
        }
        return "市場訊號穩定，可用近 30 日均價作為年度議價基準。"
    }
}
