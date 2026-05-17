import SwiftUI
import SwiftData

public struct SupplierQuoteEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: SupplierQuoteEntryViewModel
    let suppliers: [Supplier]
    let ingredients: [Ingredient]
    let onSaved: (SupplierQuote) -> Void

    @State private var alertMessage: String?

    public init(
        viewModel: SupplierQuoteEntryViewModel,
        suppliers: [Supplier],
        ingredients: [Ingredient],
        onSaved: @escaping (SupplierQuote) -> Void
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.suppliers = suppliers
        self.ingredients = ingredients
        self.onSaved = onSaved
    }

    public var body: some View {
        Form {
            Section("選擇") {
                Picker("供應商", selection: $viewModel.supplierID) {
                    Text("請選擇").tag(UUID?.none)
                    ForEach(suppliers, id: \.id) { s in
                        Text(s.name).tag(UUID?.some(s.id))
                    }
                }
                Picker("食材", selection: $viewModel.ingredientID) {
                    Text("請選擇").tag(UUID?.none)
                    ForEach(ingredients, id: \.id) { i in
                        Text("\(i.name)（預設 \(i.unit.displayName)）").tag(UUID?.some(i.id))
                    }
                }
            }
            Section("報價") {
                TextField("報價（每單位）", text: $viewModel.priceText)
                Picker("單位", selection: $viewModel.unit) {
                    ForEach(UnitType.allCases) { u in Text(u.displayName).tag(u) }
                }
                .onChange(of: viewModel.unit) { _, _ in checkUnitMismatch() }
                DatePicker("報價日期", selection: $viewModel.quoteDate, in: ...Date(), displayedComponents: .date)
                TextField("最低訂購量（可選）", text: $viewModel.minOrderQuantityText)
                TextField("備註", text: $viewModel.note, axis: .vertical)
                if let warn = viewModel.unitMismatchWarning {
                    Text(warn).font(.caption).foregroundStyle(PurchasingTheme.warning)
                }
            }
            Section { DisclaimerFooter() }
        }
        .navigationTitle("新增報價")
        .onChange(of: viewModel.ingredientID) { _, _ in checkUnitMismatch() }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("儲存") { save() }
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") { dismiss() }
            }
        }
        .alert("儲存失敗", isPresented: .constant(alertMessage != nil), presenting: alertMessage) { _ in
            Button("確認") { alertMessage = nil }
        } message: { msg in
            Text(msg)
        }
    }

    private func checkUnitMismatch() {
        guard let iid = viewModel.ingredientID,
              let ing = ingredients.first(where: { $0.id == iid }) else {
            viewModel.unitMismatchWarning = nil
            return
        }
        if ing.unit != viewModel.unit {
            viewModel.unitMismatchWarning = "單位不同，儲存後比價時可能需要確認"
        } else {
            viewModel.unitMismatchWarning = nil
        }
    }

    private func save() {
        switch viewModel.save() {
        case .success(let quote):
            onSaved(quote)
            dismiss()
        case .failure(let err):
            alertMessage = err.errorDescription
        }
    }
}
