import Foundation
#if canImport(StoreKit)
import StoreKit
#endif

@MainActor
public final class PremiumAccessManager: ObservableObject {
    @Published public private(set) var isProUnlocked: Bool = false
    @Published public private(set) var currentProductID: String?
    @Published public private(set) var lastError: String?
    @Published public private(set) var productDisplayName: String = "RestaurantOps PRO"
    @Published public private(set) var productPriceLabel: String = "每月方案"
    @Published public private(set) var isProcessing: Bool = false

    private let productID: String

    public init(productID: String) {
        self.productID = productID
    }

    public func refresh() async {
        isProcessing = true
        defer { isProcessing = false }
        #if canImport(StoreKit)
        do {
            let products = try await Product.products(for: [productID])
            if let product = products.first {
                productDisplayName = product.displayName
                productPriceLabel = product.displayPrice
            }
            let statuses = try await Product.SubscriptionInfo.status(for: productID)
            isProUnlocked = statuses.contains { $0.state == .subscribed || $0.state == .inGracePeriod || $0.state == .inBillingRetryPeriod }
            currentProductID = isProUnlocked ? productID : nil
        } catch {
            lastError = error.localizedDescription
        }
        #else
        isProUnlocked = ProcessInfo.processInfo.environment["UNLOCK_PRO_LOCALLY"] == "1"
        currentProductID = isProUnlocked ? productID : nil
        #endif
    }

    public func purchase() async -> Bool {
        isProcessing = true
        defer { isProcessing = false }
        #if canImport(StoreKit)
        do {
            let products = try await Product.products(for: [productID])
            guard let product = products.first else {
                lastError = "找不到可購買商品：\(productID)"
                return false
            }
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified:
                    await refresh()
                    return isProUnlocked
                case .unverified:
                    lastError = "購買驗證失敗"
                }
            case .pending:
                lastError = "交易待處理"
            case .userCancelled:
                lastError = "使用者取消購買"
            @unknown default:
                lastError = "未知購買狀態"
            }
        } catch {
            lastError = error.localizedDescription
        }
        return false
        #else
        isProUnlocked = true
        currentProductID = productID
        return true
        #endif
    }

    public func restorePurchases() async -> Bool {
        isProcessing = true
        defer { isProcessing = false }
        #if canImport(StoreKit)
        do {
            try await AppStore.sync()
            await refresh()
            return isProUnlocked
        } catch {
            lastError = error.localizedDescription
            return false
        }
        #else
        return isProUnlocked
        #endif
    }
}
