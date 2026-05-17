import SwiftUI
import SwiftData
import UIKit

public struct AppShellView: View {
    @Environment(\.modelContext) private var context
    @Query private var restaurants: [RestaurantProfile]
    @State private var selectedTab: Tab = .ingredients
    @StateObject private var premium: PremiumAccessManager
    @StateObject private var runtimeSettings = AppRuntimeSettings()
    let store: PurchasingDemoStore
    private let configuration: AppConfiguration

    public init(store: PurchasingDemoStore, configuration: AppConfiguration = .load()) {
        self.store = store
        self.configuration = configuration
        _premium = StateObject(wrappedValue: PremiumAccessManager(productID: configuration.proProductID))
        Self.configureTabBarAppearance()
    }

    public enum Tab: Hashable { case ingredients, suppliers, dashboard, trend, settings }

    public var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack { ingredientsRoot }
                .tabItem { Label("食材庫", systemImage: "leaf") }
                .tag(Tab.ingredients)
            NavigationStack { suppliersRoot }
                .tabItem { Label("廠商", systemImage: "person.2") }
                .tag(Tab.suppliers)
            NavigationStack { dashboardRoot }
                .tabItem { Label("戰情", systemImage: "scalemass") }
                .tag(Tab.dashboard)
            NavigationStack { trendRoot }
                .tabItem { Label("行情", systemImage: "chart.line.uptrend.xyaxis") }
                .tag(Tab.trend)
            NavigationStack { settingsRoot }
                .tabItem { Label("設定", systemImage: "slider.horizontal.3") }
                .tag(Tab.settings)
        }
        .task {
            store.seedIfNeeded(context: context)
            runtimeSettings.load()
            await premium.refresh()
        }
        .tint(PurchasingTheme.primary)
    }

    private var restaurantID: UUID {
        store.activeRestaurantID(in: restaurants)
    }

    private var repository: PurchasingRepository {
        let effective = runtimeSettings.effectiveConfiguration(base: configuration)
        let live = LiveAgriPriceAPIClient(
            endpoint: effective.liveEndpoint,
            maxRetries: runtimeSettings.maxRetries,
            cacheTTLSeconds: runtimeSettings.cacheTTL
        )
        let mock = MockAgriPriceAPIClient()
        let apiClient: AgriPriceAPIClient
        switch effective.marketDataMode {
        case .live:
            apiClient = live
        case .mock:
            apiClient = mock
        case .liveWithMockFallback:
            apiClient = FallbackAgriPriceAPIClient(primary: live, fallback: mock)
        }
        return DefaultPurchasingRepository(
            apiClient: apiClient,
            context: context
        )
    }

    @ViewBuilder
    private var ingredientsRoot: some View {
        VStack(spacing: 12) {
            BrandHeroCard(
                title: "餐採智控",
                subtitle: "餐廳採購戰情中心，掌握行情再下單。"
            )
            IngredientListView(
                restaurantID: restaurantID,
                viewModel: IngredientListViewModel(context: context, restaurantID: restaurantID)
            ) { ingredient in
                // navigation handled by NavigationLink in IngredientDetail flow
            }
        }
        .padding(.horizontal)
        .background(PurchasingTheme.appBackground.ignoresSafeArea())
        .navigationDestination(for: IngredientNav.self) { nav in
            switch nav {
            case .detail(let id):
                if let ing = store.ingredient(by: id, in: context) {
                    IngredientDetailView(viewModel: IngredientDetailViewModel(
                        ingredient: ing,
                        context: context,
                        matcher: SynonymIngredientMarketMatcher(),
                        repository: repository
                    ))
                }
            }
        }
    }

    @ViewBuilder
    private var settingsRoot: some View {
        SettingsDiagnosticsView(baseConfig: configuration, settings: runtimeSettings)
            .environmentObject(premium)
    }

    @ViewBuilder
    private var suppliersRoot: some View {
        VStack(spacing: 12) {
            BrandHeroCard(
                title: "供應商策略管理",
                subtitle: "集中管理聯絡資訊、備註與採購關係。"
            )
            SupplierListView(viewModel: SupplierListViewModel(context: context, restaurantID: restaurantID))
        }
        .padding(.horizontal)
        .background(PurchasingTheme.appBackground.ignoresSafeArea())
    }

    @ViewBuilder
    private var dashboardRoot: some View {
        IngredientPickerView(context: context, restaurantID: restaurantID) { ing in
            PriceComparisonDashboardView(
                viewModel: PriceComparisonDashboardViewModel(
                    ingredient: ing,
                    context: context,
                    repository: repository,
                    intelligenceService: DefaultProcurementIntelligenceService()
                )
            ) { comparison in
                // pushed by NavigationLink in dashboard
            }
            .environmentObject(premium)
        }
    }

    @ViewBuilder
    private var trendRoot: some View {
        IngredientPickerView(context: context, restaurantID: restaurantID) { ing in
            MarketPriceTrendView(viewModel: MarketPriceTrendViewModel(ingredient: ing, repository: repository))
        }
    }
}

extension AppShellView {
    private static func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.96, green: 0.98, blue: 0.99, alpha: 0.96)
        appearance.shadowColor = UIColor.black.withAlphaComponent(0.08)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

public enum IngredientNav: Hashable {
    case detail(UUID)
}

struct IngredientPickerView<Content: View>: View {
    let context: ModelContext
    let restaurantID: UUID
    let content: (Ingredient) -> Content
    @State private var ingredients: [Ingredient] = []
    @State private var selection: Ingredient?

    var body: some View {
        Group {
            if ingredients.isEmpty {
                EmptyStateView(title: "尚未建立常用食材", systemImage: "leaf")
            } else if let s = selection {
                content(s)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    BrandHeroCard(
                        title: "選擇分析食材",
                        subtitle: "挑選食材後可查看比價、行情趨勢與議價建議。"
                    )
                    List {
                        ForEach(ingredients, id: \.id) { ing in
                            Button {
                                selection = ing
                            } label: {
                                HStack {
                                    Text(ing.name)
                                        .font(.headline)
                                    Spacer()
                                    Text(ing.unit.displayName).font(.caption).foregroundStyle(PurchasingTheme.muted)
                                }
                                .padding(12)
                                .premiumCard()
                            }
                            .buttonStyle(.plain)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
                .padding()
                .background(PurchasingTheme.appBackground.ignoresSafeArea())
                .navigationTitle("選擇食材")
            }
        }
        .toolbar {
            if selection != nil {
                ToolbarItem(placement: .cancellationAction) {
                    Button("更換食材") { selection = nil }
                }
            }
        }
        .onAppear(perform: reload)
    }

    private func reload() {
        let rid = restaurantID
        let descriptor = FetchDescriptor<Ingredient>(
            predicate: #Predicate { $0.restaurantID == rid },
            sortBy: [SortDescriptor(\Ingredient.name)]
        )
        ingredients = (try? context.fetch(descriptor)) ?? []
    }
}
