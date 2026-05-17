import SwiftUI

public struct ProPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var premium: PremiumAccessManager

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("餐採智控 PRO")
                        .font(.largeTitle.bold())
                    Text("解鎖高勝率採購策略，把每次進貨都變成可量化的利潤。")
                        .foregroundStyle(PurchasingTheme.muted)

                    feature("目標價建議", "依市場行情與報價落差，給出可談判的目標價格。")
                    feature("年化節省預估", "以月採購量推估全年成本優化空間。")
                    feature("風險分數", "快速辨識高風險食材與供應商價格異常。")
                    feature("AI 議價助理", "一鍵產生可直接貼到 LINE 的談判訊息。")

                    VStack(alignment: .leading, spacing: 8) {
                        Text(premium.productDisplayName).font(.headline)
                        Text(premium.productPriceLabel).font(.title3.weight(.semibold))
                        Text("可隨時於 Apple 帳號取消，訂閱到期前不會中斷已購服務。")
                            .font(.caption)
                            .foregroundStyle(PurchasingTheme.muted)
                    }
                    .padding()
                    .premiumCard()
                }
                .padding()
            }
            .background(PurchasingTheme.appBackground.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("關閉") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 10) {
                    Button {
                        Task {
                            if await premium.purchase() {
                                dismiss()
                            }
                        }
                    } label: {
                        if premium.isProcessing {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("立即解鎖 PRO")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(premium.isProcessing)

                    Button("還原購買") {
                        Task { _ = await premium.restorePurchases() }
                    }
                    .disabled(premium.isProcessing)
                    .font(.subheadline)
                }
                .padding()
                .background(.ultraThinMaterial)
            }
        }
    }

    private func feature(_ title: String, _ subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: "checkmark.seal.fill")
                .font(.headline)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(PurchasingTheme.muted)
        }
        .padding()
        .premiumCard()
    }
}
