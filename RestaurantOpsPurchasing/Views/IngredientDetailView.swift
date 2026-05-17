import SwiftUI
import SwiftData

public struct IngredientDetailView: View {
    @StateObject private var viewModel: IngredientDetailViewModel

    public init(viewModel: IngredientDetailViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        List {
            Section("食材資料") {
                LabeledContent("名稱", value: viewModel.ingredient.name)
                LabeledContent("分類", value: viewModel.ingredient.category.displayName)
                LabeledContent("預設單位", value: viewModel.ingredient.unit.displayName)
            }
            Section("目前市場對應") {
                if let name = viewModel.ingredient.linkedMarketItemName,
                   let code = viewModel.ingredient.linkedMarketItemCode {
                    LabeledContent("市場品項", value: name)
                    LabeledContent("代號", value: code)
                    Button("取消對應", role: .destructive) { viewModel.clearMapping() }
                } else {
                    Text("尚未對應行情")
                        .foregroundStyle(PurchasingTheme.muted)
                }
            }
            Section {
                Button {
                    Task { await viewModel.loadCandidates() }
                } label: {
                    HStack {
                        Image(systemName: "wand.and.stars")
                        Text(viewModel.loading ? "比對中…" : "重新尋找候選")
                    }
                }
                .disabled(viewModel.loading)
            } header: {
                Text("候選市場品項")
            } footer: {
                Text("AI 候選會標示「AI 建議，請確認」，需手動確認後才會儲存對應。")
                    .font(.caption2)
            }
            if !viewModel.candidates.isEmpty {
                Section("建議") {
                    ForEach(viewModel.candidates) { c in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(c.itemName).font(.headline)
                                Spacer()
                                StatusBadge(title: c.source.displayName, tint: badgeTint(for: c.source))
                            }
                            Text(c.reason).font(.caption).foregroundStyle(PurchasingTheme.muted)
                            HStack {
                                Text("信心：\(PurchasingFormatters.percent(c.confidence * 100))")
                                    .font(.caption2)
                                    .foregroundStyle(PurchasingTheme.muted)
                                Spacer()
                                Button("確認對應") { viewModel.confirm(candidate: c) }
                                    .buttonStyle(.borderedProminent)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            } else if !viewModel.loading {
                Section {
                    Text("找不到相近市場品項，請稍後更新行情或手動搜尋。")
                        .foregroundStyle(PurchasingTheme.muted)
                        .font(.callout)
                }
            }
            if let err = viewModel.errorMessage {
                Section { Text(err).foregroundStyle(.red) }
            }
            Section { DisclaimerFooter() }
        }
        .navigationTitle(viewModel.ingredient.name)
    }

    private func badgeTint(for source: MappingSource) -> Color {
        switch source {
        case .exact: return PurchasingTheme.success
        case .synonym: return PurchasingTheme.primary
        case .fuzzy: return PurchasingTheme.accent
        case .aiSuggested: return .purple
        case .userConfirmed: return PurchasingTheme.success
        }
    }
}
