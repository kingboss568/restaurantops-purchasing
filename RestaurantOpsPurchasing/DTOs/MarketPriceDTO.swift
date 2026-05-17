import Foundation

public struct MarketPriceDTO: Codable, Equatable {
    public let tradeDateRaw: String
    public let categoryCode: String?
    public let itemCode: String?
    public let itemName: String
    public let marketCode: String?
    public let marketName: String
    public let highPriceRaw: String?
    public let midPriceRaw: String?
    public let lowPriceRaw: String?
    public let averagePriceRaw: String
    public let volumeRaw: String?

    public init(
        tradeDateRaw: String,
        categoryCode: String?,
        itemCode: String?,
        itemName: String,
        marketCode: String?,
        marketName: String,
        highPriceRaw: String?,
        midPriceRaw: String?,
        lowPriceRaw: String?,
        averagePriceRaw: String,
        volumeRaw: String?
    ) {
        self.tradeDateRaw = tradeDateRaw
        self.categoryCode = categoryCode
        self.itemCode = itemCode
        self.itemName = itemName
        self.marketCode = marketCode
        self.marketName = marketName
        self.highPriceRaw = highPriceRaw
        self.midPriceRaw = midPriceRaw
        self.lowPriceRaw = lowPriceRaw
        self.averagePriceRaw = averagePriceRaw
        self.volumeRaw = volumeRaw
    }

    enum CodingKeys: String, CodingKey {
        case tradeDateRaw = "交易日期"
        case categoryCode = "種類代碼"
        case itemCode = "作物代號"
        case itemName = "作物名稱"
        case marketCode = "市場代號"
        case marketName = "市場名稱"
        case highPriceRaw = "上價"
        case midPriceRaw = "中價"
        case lowPriceRaw = "下價"
        case averagePriceRaw = "平均價"
        case volumeRaw = "交易量"
    }
}

public enum MarketPriceMappingError: Error, Equatable {
    case missingAveragePrice
    case unparseableAveragePrice(String)
    case unparseableDate(String)
    case missingItemIdentifier
}

public struct MarketPriceMapper {
    public init() {}

    public func map(_ dto: MarketPriceDTO, sourceName: String, fetchedAt: Date) throws -> MarketPriceRecordInput {
        let tradeDate = try Self.parseDate(dto.tradeDateRaw)

        guard let averagePrice = Self.parseDecimal(dto.averagePriceRaw) else {
            if dto.averagePriceRaw.trimmingCharacters(in: .whitespaces).isEmpty {
                throw MarketPriceMappingError.missingAveragePrice
            }
            throw MarketPriceMappingError.unparseableAveragePrice(dto.averagePriceRaw)
        }

        let itemCode: String
        if let code = dto.itemCode?.trimmingCharacters(in: .whitespaces), !code.isEmpty {
            itemCode = code
        } else {
            let nameTrimmed = dto.itemName.trimmingCharacters(in: .whitespaces)
            guard !nameTrimmed.isEmpty else {
                throw MarketPriceMappingError.missingItemIdentifier
            }
            itemCode = "NAME:\(nameTrimmed)"
        }

        let marketCode = dto.marketCode?.trimmingCharacters(in: .whitespaces)
        let unit = "kg"
        let sourceKey = Self.makeSourceKey(
            sourceName: sourceName,
            tradeDate: tradeDate,
            marketCode: marketCode,
            itemCode: itemCode,
            unit: unit
        )

        return MarketPriceRecordInput(
            categoryCode: dto.categoryCode,
            itemCode: itemCode,
            itemName: dto.itemName,
            marketCode: marketCode,
            marketName: dto.marketName,
            tradeDate: tradeDate,
            highPrice: Self.parseDecimal(dto.highPriceRaw),
            midPrice: Self.parseDecimal(dto.midPriceRaw),
            lowPrice: Self.parseDecimal(dto.lowPriceRaw),
            averagePrice: averagePrice,
            volume: Self.parseDecimal(dto.volumeRaw),
            unit: unit,
            sourceName: sourceName,
            fetchedAt: fetchedAt,
            sourceKey: sourceKey
        )
    }

    public static func parseDecimal(_ raw: String?) -> Decimal? {
        guard let raw else { return nil }
        let trimmed = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: "")
        if trimmed.isEmpty || trimmed == "-" || trimmed == "—" { return nil }
        return Decimal(string: trimmed)
    }

    public static func parseDate(_ raw: String) throws -> Date {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw MarketPriceMappingError.unparseableDate(raw) }

        // 民國 date check FIRST (e.g. "113.05.16", "113/05/16", "1130516").
        // Must run before gregorian "yyyy.MM.dd" because "115.05.16" otherwise
        // parses as gregorian year 115.
        let separators = CharacterSet(charactersIn: "./-")
        let parts = trimmed.components(separatedBy: separators).filter { !$0.isEmpty }
        if parts.count == 3,
           let y = Int(parts[0]),
           let m = Int(parts[1]),
           let d = Int(parts[2]),
           y > 0 && y < 200 {
            let westernYear = y + 1911
            var comps = DateComponents()
            comps.year = westernYear
            comps.month = m
            comps.day = d
            var cal = Calendar(identifier: .gregorian)
            cal.timeZone = TimeZone(identifier: "Asia/Taipei") ?? .current
            if let d = cal.date(from: comps) { return d }
        }

        // Try ISO 8601
        let iso = ISO8601DateFormatter()
        if let d = iso.date(from: trimmed) { return d }

        // Common gregorian formats
        let formats = [
            "yyyy-MM-dd",
            "yyyy/MM/dd",
            "yyyy.MM.dd",
            "yyyy-MM-dd HH:mm:ss",
            "yyyy/MM/dd HH:mm:ss"
        ]
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Taipei")
        for f in formats {
            formatter.dateFormat = f
            if let d = formatter.date(from: trimmed) { return d }
        }

        // Compact 7-digit: yyyMMdd (民國)
        if trimmed.count == 7, let n = Int(trimmed) {
            let y = n / 10000
            let m = (n / 100) % 100
            let d = n % 100
            let westernYear = y + 1911
            var comps = DateComponents()
            comps.year = westernYear
            comps.month = m
            comps.day = d
            var cal = Calendar(identifier: .gregorian)
            cal.timeZone = TimeZone(identifier: "Asia/Taipei") ?? .current
            if let date = cal.date(from: comps) { return date }
        }

        throw MarketPriceMappingError.unparseableDate(raw)
    }

    public static func makeSourceKey(
        sourceName: String,
        tradeDate: Date,
        marketCode: String?,
        itemCode: String,
        unit: String
    ) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Taipei")
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: tradeDate)
        let mkt = marketCode?.trimmingCharacters(in: .whitespaces) ?? ""
        return "\(sourceName)|\(dateStr)|\(mkt)|\(itemCode)|\(unit)"
    }
}
