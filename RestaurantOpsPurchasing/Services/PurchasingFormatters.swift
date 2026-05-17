import Foundation

public enum PurchasingFormatters {
    public static let disclaimer = "本內容為輔助資訊，不構成專業意見，請依實際情況自行確認。"

    public static func price(_ value: Decimal?) -> String {
        guard let value else { return "—" }
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.maximumFractionDigits = 2
        nf.minimumFractionDigits = 0
        let s = nf.string(from: value as NSDecimalNumber) ?? "\(value)"
        return "$" + s
    }

    public static func percent(_ value: Decimal?) -> String {
        guard let value else { return "—" }
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.maximumFractionDigits = 1
        nf.minimumFractionDigits = 0
        let signed: Decimal = value
        let formatted = nf.string(from: signed as NSDecimalNumber) ?? "\(value)"
        if signed > 0 { return "+\(formatted)%" }
        return "\(formatted)%"
    }

    public static func date(_ value: Date) -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "zh_TW")
        f.dateFormat = "yyyy/MM/dd"
        return f.string(from: value)
    }

    public static func dateTime(_ value: Date) -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "zh_TW")
        f.dateFormat = "yyyy/MM/dd HH:mm"
        return f.string(from: value)
    }
}
