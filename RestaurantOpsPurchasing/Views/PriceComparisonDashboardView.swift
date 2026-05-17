import SwiftUI
import SwiftData

public struct PriceComparisonDashboardView: View {
    @EnvironmentObject private var premium: PremiumAccessManager
    @StateObject private var viewModel: PriceComparisonDashboardViewModel
    @State private var showPaywall: Bool = false
    let onNegotiate: (SupplierPriceComparison) -> Void

    public init(
        viewModel: PriceComparisonDashboardViewModel,
        onNegotiate: @escaping (SupplierPriceComparison) -> Void
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onNegotiate = onNegotiate
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                BrandHeroCard(
                    title: "採購比價戰情",
                    subtitle: "行情、報價、議價三合一判讀，快速決策。"
                )
                marketSummary
                proIntelligenceSection
                comparisonsList
                DisclaimerFooter()
            }
            .padding()
        }
        .background(PurchasingTheme.appBackground.ignoresSafeArea())
        .navigationTitle("\(viewModel.ingredient.name) 比價")
        .onAppear { viewModel.reload() }
        .sheet(isPresented: $showPaywall) {
            ProPaywallView()
                .environmentObject(premium)
        }
    }

    @ViewBuilder
    private var marketSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("市場行情").font(.headline)
            if let r = viewModel.result {
                HStack(spacing: 16) {
                    metric(title: "市場最新均價", value: PurchasingFormatters.price(r.latestMarketAverage))
                    metric(title: "7 日均價", value: PurchasingFormatters.price(r.marketAverage7Days))
                    metric(title: "30 日均價", value: PurchasingFormatters.price(r.marketAverage30Days))
                }
                if let log = viewModel.lastFetchLog {
                    Text("資料來源：\(log.sourceName) ・ 最後更新：\(PurchasingFormatters.dateTime(log.startedAt))")
                        .font(.caption2).foregroundStyle(PurchasingTheme.muted)
                }
                ForEach(r.warnings, id: \.self) { w in
                    Text(w).font(.caption).foregroundStyle(PurchasingTheme.warning)
                }
            } else if let err = viewModel.errorMessage {
                Text(err).foregroundStyle(.red)
            } else {
                ProgressView()
            }
        }
        .padding()
        .premiumCard()
    }

    @ViewBuilder
    private var proIntelligenceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("PRO 採購戰情").font(.headline)
                Spacer()
                StatusBadge(
                    title: premium.isProUnlocked ? "已解鎖 PRO" : "PRO 進階",
                    tint: premium.isProUnlocked ? PurchasingTheme.success : PurchasingTheme.accent
                )
            }
            if premium.isProUnlocked, let intel = viewModel.result?.intelligence {
                metric(title: "建議目標價", value: PurchasingFormatters.price(intel.suggestedTargetPrice))
                metric(title: "年化節省預估", value: PurchasingFormatters.price(intel.annualSavingsEstimate))
                metric(title: "風險分數", value: "\(intel.riskScore) / 100")
                Text(intel.negotiationLeverage)
                    .font(.caption)
                    .foregroundStyle(PurchasingTheme.muted)
            } else {
                Text("解鎖後可獲得目標價、年化節省預估、風險評分與高勝率議價策略。")
                    .font(.subheadline)
                    .foregroundStyle(PurchasingTheme.muted)
                Button {
                    showPaywall = true
                } label: {
                    Label("查看 PRO 方案", systemImage: "crown.fill")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .premiumCard()
    }

    @ViewBuilder
    private var comparisonsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("供應商比價").font(.headline)
            if let comparisons = viewModel.result?.supplierComparisons, !comparisons.isEmpty {
                ForEach(comparisons) { c in
                    comparisonCard(c)
                }
            } else {
                EmptyStateView(title: "尚未有供應商報價，請先建立報價。", systemImage: "tag")
            }
        }
    }

    private func metric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption).foregroundStyle(PurchasingTheme.muted)
            Text(value).font(.title3.weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func comparisonCard(_ c: SupplierPriceComparison) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(c.supplierName).font(.headline)
                if let rank = c.rank {
                    StatusBadge(title: "排名 #\(rank)", tint: rank == 1 ? PurchasingTheme.success : PurchasingTheme.primary)
                }
                Spacer()
                StatusBadge(title: c.status.displayName, tint: c.status.tint)
            }
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("報價").font(.caption).foregroundStyle(PurchasingTheme.muted)
                    Text("\(PurchasingFormatters.price(c.quotedPrice)) / \(c.quotedUnit.displayName)")
                        .font(.body.weight(.semibold))
                }
                if let np = c.normalizedQuotedPrice, let nu = c.normalizedUnit {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("換算").font(.caption).foregroundStyle(PurchasingTheme.muted)
                        Text("\(PurchasingFormatters.price(np)) / \(nu.displayName)")
                            .font(.body)
                    }
                }
                if let p = c.differencePercent {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("價差").font(.caption).foregroundStyle(PurchasingTheme.muted)
                        Text(PurchasingFormatters.percent(p))
                            .font(.body.weight(.semibold))
                            .foregroundStyle(c.status.tint)
                    }
                }
                Spacer()
            }
            Text("報價日：\(PurchasingFormatters.date(c.quoteDate))")
                .font(.caption2).foregroundStyle(PurchasingTheme.muted)
            HStack {
                Spacer()
                Button {
                    if premium.isProUnlocked {
                        onNegotiate(c)
                    } else {
                        showPaywall = true
                    }
                } label: {
                    Label(
                        premium.isProUnlocked ? "產生議價訊息" : "PRO 解鎖 AI 議價",
                        systemImage: premium.isProUnlocked ? "text.bubble" : "lock.fill"
                    )
                }
                .buttonStyle(.borderedProminent)
                .disabled(c.status == .unitMismatch)
            }
        }
        .padding()
        .premiumCard()
    }
}
