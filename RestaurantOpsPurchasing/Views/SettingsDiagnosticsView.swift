import SwiftUI

public struct SettingsDiagnosticsView: View {
    @EnvironmentObject private var premium: PremiumAccessManager
    @StateObject private var settings: AppRuntimeSettings
    private let baseConfig: AppConfiguration

    @State private var testResult: String?
    @State private var testing = false

    public init(baseConfig: AppConfiguration, settings: AppRuntimeSettings) {
        self.baseConfig = baseConfig
        _settings = StateObject(wrappedValue: settings)
    }

    public var body: some View {
        Form {
            Section("資料來源設定") {
                Picker("模式", selection: $settings.marketDataMode) {
                    ForEach([MarketDataMode.live, .liveWithMockFallback, .mock], id: \.rawValue) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                TextField("Endpoint", text: $settings.endpoint)
                Stepper("重試次數：\(settings.maxRetries)", value: $settings.maxRetries, in: 0...5)
                Stepper("快取秒數：\(Int(settings.cacheTTL))", value: $settings.cacheTTL, in: 0...3600, step: 30)
                Button("儲存設定") {
                    settings.save()
                    testResult = "設定已儲存"
                }
            }

            Section("連線診斷") {
                Button(testing ? "測試中..." : "測試行情 API") {
                    Task { await runConnectivityTest() }
                }
                .disabled(testing)
                if let testResult {
                    Text(testResult).font(.caption).foregroundStyle(PurchasingTheme.muted)
                }
            }

            Section("PRO 狀態") {
                LabeledContent("目前狀態", value: premium.isProUnlocked ? "已解鎖" : "未解鎖")
                Button("重新檢查訂閱") {
                    Task { await premium.refresh() }
                }
            }
        }
        .navigationTitle("設定與診斷")
    }

    private func runConnectivityTest() async {
        testing = true
        defer { testing = false }

        let config = settings.effectiveConfiguration(base: baseConfig)
        let live = LiveAgriPriceAPIClient(
            endpoint: config.liveEndpoint,
            maxRetries: settings.maxRetries,
            cacheTTLSeconds: settings.cacheTTL
        )
        let client: AgriPriceAPIClient
        switch config.marketDataMode {
        case .live:
            client = live
        case .mock:
            client = MockAgriPriceAPIClient()
        case .liveWithMockFallback:
            client = FallbackAgriPriceAPIClient(primary: live, fallback: MockAgriPriceAPIClient())
        }

        do {
            let start = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
            let rows = try await client.fetchMarketPrices(
                from: start,
                to: .now,
                itemName: nil,
                itemCode: nil,
                marketName: nil,
                marketCode: nil
            )
            testResult = "連線成功，取得 \(rows.count) 筆資料。"
        } catch {
            testResult = "連線失敗：\(error.localizedDescription)"
        }
    }
}
