import Foundation

public enum UnitType: String, Codable, CaseIterable, Identifiable, Equatable {
    case kg
    case g
    case liter
    case ml
    case piece
    case box
    case catty

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .kg: return "公斤"
        case .g: return "公克"
        case .liter: return "公升"
        case .ml: return "毫升"
        case .piece: return "個"
        case .box: return "箱"
        case .catty: return "台斤"
        }
    }
}

public enum IngredientCategory: String, Codable, CaseIterable, Identifiable, Equatable {
    case vegetable
    case fruit
    case meat
    case seafood
    case dairy
    case dryGoods
    case seasoning
    case beverage
    case other

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .vegetable: return "蔬菜"
        case .fruit: return "水果"
        case .meat: return "肉品"
        case .seafood: return "海鮮"
        case .dairy: return "乳品"
        case .dryGoods: return "乾貨"
        case .seasoning: return "調味"
        case .beverage: return "飲品"
        case .other: return "其他"
        }
    }
}

public enum MappingSource: String, Codable, CaseIterable, Equatable {
    case exact
    case synonym
    case fuzzy
    case aiSuggested
    case userConfirmed

    public var displayName: String {
        switch self {
        case .exact: return "完全相符"
        case .synonym: return "同義詞"
        case .fuzzy: return "模糊比對"
        case .aiSuggested: return "AI 建議"
        case .userConfirmed: return "使用者確認"
        }
    }
}

public enum FetchStatus: String, Codable, CaseIterable, Equatable {
    case success
    case failed
    case partial

    public var displayName: String {
        switch self {
        case .success: return "成功"
        case .failed: return "失敗"
        case .partial: return "部分成功"
        }
    }
}

public enum PriceComparisonStatus: String, Codable, CaseIterable, Equatable {
    case cheaperThanMarket
    case nearMarket
    case higherThanMarket
    case missingMarketData
    case unitMismatch

    public var displayName: String {
        switch self {
        case .cheaperThanMarket: return "低於市場"
        case .nearMarket: return "接近市場"
        case .higherThanMarket: return "偏高"
        case .missingMarketData: return "缺少行情"
        case .unitMismatch: return "單位需確認"
        }
    }
}

public enum NegotiationTone: String, Codable, CaseIterable, Identifiable, Equatable {
    case polite
    case firm
    case friendly
    case longTermPartner

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .polite: return "禮貌"
        case .firm: return "堅定"
        case .friendly: return "親切"
        case .longTermPartner: return "長期合作"
        }
    }
}
