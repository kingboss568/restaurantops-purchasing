import SwiftUI

public struct NegotiationAssistantView: View {
    @StateObject private var viewModel: NegotiationAssistantViewModel
    @State private var copied = false

    public init(viewModel: NegotiationAssistantViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                BrandHeroCard(
                    title: "AI 議價助理",
                    subtitle: "用資料說服，而不是靠感覺議價。"
                )
                dataEvidence
                toneSelector
                messageEditor
                actions
                DisclaimerFooter()
            }
            .padding()
        }
        .background(PurchasingTheme.appBackground.ignoresSafeArea())
        .navigationTitle("議價助理")
        .task { await viewModel.generate() }
    }

    private var dataEvidence: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("資料依據").font(.headline)
            Group {
                row("食材", viewModel.ingredientName)
                row("供應商", viewModel.comparison.supplierName)
                row("供應商報價", "\(PurchasingFormatters.price(viewModel.comparison.quotedPrice)) / \(viewModel.comparison.quotedUnit.displayName)")
                row("市場參考價", PurchasingFormatters.price(viewModel.comparison.marketReferencePrice))
                row("價差百分比", PurchasingFormatters.percent(viewModel.comparison.differencePercent))
                row("7 日均價", PurchasingFormatters.price(viewModel.marketAverage7Days))
                row("30 日均價", PurchasingFormatters.price(viewModel.marketAverage30Days))
            }
            .font(.subheadline)
        }
        .padding()
        .premiumCard()
    }

    private func row(_ k: String, _ v: String) -> some View {
        HStack {
            Text(k).foregroundStyle(PurchasingTheme.muted)
            Spacer()
            Text(v).font(.subheadline.weight(.semibold))
        }
    }

    private var toneSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("語氣").font(.headline)
            Picker("語氣", selection: $viewModel.tone) {
                ForEach(NegotiationTone.allCases) { t in
                    Text(t.displayName).tag(t)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: viewModel.tone) { _, _ in
                Task { await viewModel.generate() }
            }
        }
        .padding()
        .premiumCard()
    }

    private var messageEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("議價訊息").font(.headline)
                Spacer()
                if let d = viewModel.draft, d.fallbackUsed {
                    StatusBadge(title: "內建範本", tint: PurchasingTheme.accent)
                }
                if viewModel.isGenerating {
                    ProgressView().controlSize(.small)
                }
            }
            TextEditor(text: $viewModel.editedMessage)
                .frame(minHeight: 160)
                .padding(8)
                .background(PurchasingTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            if let err = viewModel.errorMessage {
                Text(err).font(.caption).foregroundStyle(PurchasingTheme.warning)
            }
        }
        .padding()
        .premiumCard()
    }

    private var actions: some View {
        VStack(spacing: 10) {
            Button {
                PurchasingPasteboard.copy(viewModel.editedMessage)
                copied = true
            } label: {
                Label("複製訊息", systemImage: "doc.on.doc")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            HStack(spacing: 12) {
                ShareLink(item: viewModel.editedMessage) {
                    Label("分享訊息", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                Button {
                    Task { await viewModel.generate() }
                } label: {
                    Label("重新產生", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .premiumCard()
        .alert("已複製", isPresented: $copied) {
            Button("確認") { copied = false }
        } message: {
            Text("議價訊息已複製，可貼到 LINE 或訊息工具。")
        }
    }
}
