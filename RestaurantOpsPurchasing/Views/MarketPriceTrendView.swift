import SwiftUI
import SwiftData
#if canImport(Charts)
import Charts
#endif

public struct MarketPriceTrendView: View {
    @StateObject private var viewModel: MarketPriceTrendViewModel

    public init(viewModel: MarketPriceTrendViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                BrandHeroCard(
                    title: "行情趨勢洞察",
                    subtitle: "追蹤波動、辨識高點與低點，調整採購時機。"
                )
                header
                if viewModel.records.isEmpty {
                    EmptyStateView(title: emptyMessage, systemImage: "chart.line.uptrend.xyaxis")
                } else {
                    chartSection
                    listSection
                }
                DisclaimerFooter()
            }
            .padding()
        }
        .background(PurchasingTheme.appBackground.ignoresSafeArea())
        .navigationTitle("行情趨勢")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { Task { await viewModel.refresh() } } label: {
                    Label("更新行情", systemImage: "arrow.clockwise")
                }
            }
        }
        .onAppear { viewModel.reload() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(viewModel.ingredient.name).font(.title2.bold())
            if let mapped = viewModel.ingredient.linkedMarketItemName {
                Text("市場品項：\(mapped)").font(.subheadline).foregroundStyle(PurchasingTheme.muted)
            } else {
                StatusBadge(title: "尚未對應行情", tint: PurchasingTheme.warning)
            }
            if let log = viewModel.lastFetchLog {
                HStack(spacing: 8) {
                    Text("最後更新：\(PurchasingFormatters.dateTime(log.startedAt))")
                        .font(.caption).foregroundStyle(PurchasingTheme.muted)
                    if viewModel.isUsingCache {
                        StatusBadge(title: "使用快取行情", tint: PurchasingTheme.accent)
                    }
                }
            }
            if let err = viewModel.errorMessage {
                Text(err).font(.caption).foregroundStyle(.red)
            }
        }
        .padding()
        .premiumCard()
    }

    private var emptyMessage: String {
        viewModel.ingredient.linkedMarketItemCode == nil
            ? "尚未對應行情，請先回到食材詳情完成對應。"
            : "目前沒有行情資料，請稍後連線更新。"
    }

    private var chartSection: some View {
        #if canImport(Charts)
        return Chart {
            ForEach(viewModel.records.sorted(by: { $0.tradeDate < $1.tradeDate }), id: \.id) { (r: MarketPriceRecord) in
                LineMark(
                    x: .value("日期", r.tradeDate),
                    y: .value("均價", NSDecimalNumber(decimal: r.averagePrice).doubleValue)
                )
                .interpolationMethod(.monotone)
                .foregroundStyle(PurchasingTheme.primary)
            }
        }
        .frame(height: 220)
        .padding()
        .premiumCard()
        #else
        return EmptyView()
        #endif
    }

    private var listSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("最近交易").font(.headline)
            ForEach(viewModel.records.sorted(by: { $0.tradeDate > $1.tradeDate }), id: \.id) { r in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(PurchasingFormatters.date(r.tradeDate)).font(.subheadline.weight(.semibold))
                        Spacer()
                        Text("均價 \(PurchasingFormatters.price(r.averagePrice))")
                            .font(.subheadline)
                    }
                    HStack(spacing: 12) {
                        if let h = r.highPrice { Text("高 \(PurchasingFormatters.price(h))").font(.caption) }
                        if let m = r.midPrice { Text("中 \(PurchasingFormatters.price(m))").font(.caption) }
                        if let l = r.lowPrice { Text("低 \(PurchasingFormatters.price(l))").font(.caption) }
                        if let v = r.volume { Text("量 \(NSDecimalNumber(decimal: v))").font(.caption) }
                    }
                    .foregroundStyle(PurchasingTheme.muted)
                    HStack(spacing: 6) {
                        Text(r.marketName).font(.caption2).foregroundStyle(PurchasingTheme.muted)
                        Text("•").font(.caption2).foregroundStyle(PurchasingTheme.muted)
                        Text(r.sourceName).font(.caption2).foregroundStyle(PurchasingTheme.muted)
                    }
                }
                .padding(10)
                .premiumCard()
            }
        }
        .padding()
        .premiumCard()
    }
}
