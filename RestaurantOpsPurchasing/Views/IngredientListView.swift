import SwiftUI
import SwiftData

public struct IngredientListView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var viewModel: IngredientListViewModel
    @State private var showAdd = false
    let restaurantID: UUID
    let onSelect: (Ingredient) -> Void

    public init(restaurantID: UUID, viewModel: IngredientListViewModel, onSelect: @escaping (Ingredient) -> Void) {
        self.restaurantID = restaurantID
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onSelect = onSelect
    }

    public var body: some View {
        Group {
            if viewModel.ingredients.isEmpty {
                if viewModel.searchText.isEmpty {
                    EmptyStateView(title: "尚未建立常用食材", systemImage: "leaf")
                } else {
                    EmptyStateView(title: "找不到符合的食材", systemImage: "magnifyingglass")
                }
            } else {
                List {
                    ForEach(viewModel.ingredients, id: \.id) { ing in
                        Button { onSelect(ing) } label: {
                            row(for: ing)
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete { idx in
                        for i in idx { viewModel.delete(viewModel.ingredients[i]) }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "搜尋食材")
        .onChange(of: viewModel.searchText) { _, _ in viewModel.reload() }
        .navigationTitle("常用食材")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showAdd = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showAdd) {
            AddIngredientSheet { name, category, unit in
                viewModel.addIngredient(name: name, category: category, unit: unit)
                showAdd = false
            }
        }
        .onAppear { viewModel.reload() }
    }

    @ViewBuilder
    private func row(for ing: Ingredient) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(ing.name).font(.headline)
                Spacer()
                Text(ing.unit.displayName).font(.caption).foregroundStyle(PurchasingTheme.muted)
            }
            HStack(spacing: 8) {
                Text(ing.category.displayName).font(.caption).foregroundStyle(PurchasingTheme.muted)
                if let linked = ing.linkedMarketItemName {
                    StatusBadge(title: "已對應行情：\(linked)", tint: PurchasingTheme.success)
                } else {
                    StatusBadge(title: "尚未對應行情", tint: PurchasingTheme.warning)
                }
            }
        }
        .padding(12)
        .premiumCard()
        .padding(.vertical, 4)
    }
}

private struct AddIngredientSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var category: IngredientCategory = .vegetable
    @State private var unit: UnitType = .kg
    let onSave: (String, IngredientCategory, UnitType) -> Void

    var body: some View {
        NavigationStack {
            Form {
                TextField("食材名稱", text: $name)
                Picker("分類", selection: $category) {
                    ForEach(IngredientCategory.allCases) { c in
                        Text(c.displayName).tag(c)
                    }
                }
                Picker("預設單位", selection: $unit) {
                    ForEach(UnitType.allCases) { u in
                        Text(u.displayName).tag(u)
                    }
                }
            }
            .navigationTitle("新增食材")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") {
                        let trimmed = name.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        onSave(trimmed, category, unit)
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
