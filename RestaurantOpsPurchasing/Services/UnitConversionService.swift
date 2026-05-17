import Foundation

public enum UnitConversionError: Error, Equatable {
    case incompatibleUnits(from: UnitType, to: UnitType)
    case missingPackSize(unit: UnitType)
}

public protocol UnitConversionService {
    func normalizePrice(
        price: Decimal,
        from unit: UnitType,
        ingredient: Ingredient
    ) throws -> NormalizedPrice
}

public struct DefaultUnitConversionService: UnitConversionService {
    /// 1 台斤 = 0.6 kg (precise: 600 g). Source: CNS.
    public static let cattyToKg: Decimal = Decimal(string: "0.6")!

    public init() {}

    public func normalizePrice(
        price: Decimal,
        from unit: UnitType,
        ingredient: Ingredient
    ) throws -> NormalizedPrice {
        let target = ingredient.unit

        // identity
        if unit == target {
            return NormalizedPrice(price: price, unit: unit)
        }

        // mass conversions to kg
        if target == .kg {
            switch unit {
            case .kg:
                return NormalizedPrice(price: price, unit: .kg)
            case .g:
                // price per g -> price per kg
                return NormalizedPrice(price: price * 1000, unit: .kg)
            case .catty:
                return NormalizedPrice(price: price / Self.cattyToKg, unit: .kg)
            case .piece, .box:
                throw UnitConversionError.missingPackSize(unit: unit)
            case .liter, .ml:
                throw UnitConversionError.incompatibleUnits(from: unit, to: target)
            }
        }

        // volume conversions
        if target == .liter {
            switch unit {
            case .liter:
                return NormalizedPrice(price: price, unit: .liter)
            case .ml:
                return NormalizedPrice(price: price * 1000, unit: .liter)
            default:
                throw UnitConversionError.incompatibleUnits(from: unit, to: target)
            }
        }

        if target == .g, unit == .kg {
            return NormalizedPrice(price: price / 1000, unit: .g)
        }
        if target == .ml, unit == .liter {
            return NormalizedPrice(price: price / 1000, unit: .ml)
        }

        // piece / box / catty cross-unit comparison not supported
        if target == .piece || target == .box || unit == .piece || unit == .box {
            throw UnitConversionError.missingPackSize(unit: unit)
        }
        throw UnitConversionError.incompatibleUnits(from: unit, to: target)
    }
}
