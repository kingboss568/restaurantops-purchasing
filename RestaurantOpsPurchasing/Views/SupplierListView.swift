import SwiftUI
import SwiftData

public struct SupplierListView: View {
    @StateObject private var viewModel: SupplierListViewModel
    @State private var showAdd = false

    public init(viewModel: SupplierListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        Group {
            if viewModel.suppliers.isEmpty {
                EmptyStateView(title: viewModel.searchText.isEmpty ? "尚未建立供應商" : "找不到符合的供應商",
                               systemImage: "person.2")
            } else {
                List {
                    ForEach(viewModel.suppliers, id: \.id) { s in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(s.name).font(.headline)
                                Spacer()
                                StatusBadge(title: "供應商", tint: PurchasingTheme.primary)
                            }
                            HStack(spacing: 12) {
                                if let p = s.phone, !p.isEmpty {
                                    Label(p, systemImage: "phone")
                                        .font(.caption).foregroundStyle(PurchasingTheme.muted)
                                }
                                if let l = s.lineID, !l.isEmpty {
                                    Label(l, systemImage: "bubble.left")
                                        .font(.caption).foregroundStyle(PurchasingTheme.muted)
                                }
                            }
                            if let n = s.note, !n.isEmpty {
                                Text(n).font(.caption2).foregroundStyle(PurchasingTheme.muted)
                            }
                        }
                        .padding(12)
                        .premiumCard()
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                    .onDelete { idx in
                        for i in idx { viewModel.delete(viewModel.suppliers[i]) }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "搜尋供應商")
        .onChange(of: viewModel.searchText) { _, _ in viewModel.reload() }
        .navigationTitle("供應商")
        .background(PurchasingTheme.appBackground.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showAdd = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showAdd) {
            AddSupplierSheet { name, phone, line, note in
                _ = viewModel.add(name: name, phone: phone, lineID: line, note: note)
                showAdd = false
            }
        }
        .onAppear { viewModel.reload() }
    }
}

private struct AddSupplierSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var phone = ""
    @State private var line = ""
    @State private var note = ""
    let onSave: (String, String?, String?, String?) -> Void

    var body: some View {
        NavigationStack {
            Form {
                TextField("供應商名稱", text: $name)
                TextField("電話（可選）", text: $phone)
                TextField("LINE ID（可選）", text: $line)
                TextField("備註（可選）", text: $note, axis: .vertical)
            }
            .navigationTitle("新增供應商")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") {
                        onSave(
                            name.trimmingCharacters(in: .whitespaces),
                            phone.isEmpty ? nil : phone,
                            line.isEmpty ? nil : line,
                            note.isEmpty ? nil : note
                        )
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
