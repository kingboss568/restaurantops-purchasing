import SwiftUI

public enum PurchasingTheme {
    public static let primary = Color(red: 0.06, green: 0.28, blue: 0.33)
    public static let accent = Color(red: 0.88, green: 0.52, blue: 0.15)
    public static let brandInk = Color(red: 0.08, green: 0.11, blue: 0.14)
    public static let warning = Color(red: 0.76, green: 0.28, blue: 0.16)
    public static let success = Color(red: 0.09, green: 0.54, blue: 0.34)
    public static let muted = Color.secondary
    public static let cardBackground = Color(.sRGB, white: 0.99, opacity: 0.9)
    public static let line = Color.black.opacity(0.08)
    public static let glass = LinearGradient(
        colors: [
            Color.white.opacity(0.85),
            Color.white.opacity(0.62)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    public static let appBackground = LinearGradient(
        colors: [
            Color(red: 0.95, green: 0.98, blue: 0.99),
            Color(red: 0.93, green: 0.96, blue: 0.99),
            Color(red: 0.98, green: 0.95, blue: 0.90)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

public struct StatusBadge: View {
    let title: String
    let tint: Color

    public init(title: String, tint: Color) {
        self.title = title
        self.tint = tint
    }

    public var body: some View {
        Text(title)
            .font(.caption.weight(.bold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(tint.opacity(0.15))
            .foregroundStyle(tint)
            .clipShape(Capsule())
    }
}

public struct BrandHeroCard: View {
    let title: String
    let subtitle: String

    public init(title: String, subtitle: String) {
        self.title = title
        self.subtitle = subtitle
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [PurchasingTheme.primary, PurchasingTheme.accent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Image(systemName: "fork.knife.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                    )
                    .frame(width: 42, height: 42)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.title3.weight(.black))
                        .foregroundStyle(PurchasingTheme.brandInk)
                    Text("Restaurant Purchasing Intelligence")
                        .font(.caption2)
                        .foregroundStyle(PurchasingTheme.muted)
                }
            }
            Text(subtitle)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(PurchasingTheme.muted)
            HStack(spacing: 8) {
                StatusBadge(title: "農業部行情 API", tint: PurchasingTheme.primary)
                StatusBadge(title: "AI 議價", tint: PurchasingTheme.accent)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [
                    Color.white.opacity(0.98),
                    Color(red: 0.89, green: 0.95, blue: 0.97),
                    Color(red: 0.99, green: 0.95, blue: 0.89)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(PurchasingTheme.line)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(0.10), radius: 16, x: 0, y: 8)
    }
}

public extension PriceComparisonStatus {
    var tint: Color {
        switch self {
        case .cheaperThanMarket: return PurchasingTheme.success
        case .nearMarket: return PurchasingTheme.muted
        case .higherThanMarket: return PurchasingTheme.warning
        case .missingMarketData: return .gray
        case .unitMismatch: return .orange
        }
    }
}

public extension View {
    func premiumCard() -> some View {
        self
            .background(PurchasingTheme.glass)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(PurchasingTheme.line)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 8)
    }
}

public struct EmptyStateView: View {
    let title: String
    let systemImage: String

    public init(title: String, systemImage: String = "tray") {
        self.title = title
        self.systemImage = systemImage
    }

    public var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 40))
                .foregroundStyle(PurchasingTheme.muted)
            Text(title)
                .font(.body)
                .foregroundStyle(PurchasingTheme.muted)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
    }
}

public struct DisclaimerFooter: View {
    public init() {}
    public var body: some View {
        Text(PurchasingFormatters.disclaimer)
            .font(.caption2)
            .foregroundStyle(PurchasingTheme.muted)
            .multilineTextAlignment(.leading)
            .padding(.top, 8)
    }
}
