
import Foundation

// MARK: - Supported Currencies

enum CurrencyOption: String, CaseIterable, Identifiable, Codable {
    case ILS, USD, EUR, GBP, THB
    
    var id: String { rawValue }
    
    var symbol: String {
        switch self {
        case .ILS: return "₪"
        case .USD: return "$"
        case .EUR: return "€"
        case .GBP: return "£"
        case .THB: return "฿"
        }
    }
    
    var displayName: String {
        switch self {
        case .ILS: return "ILS (₪)"
        case .USD: return "USD ($)"
        case .EUR: return "EUR (€)"
        case .GBP: return "GBP (£)"
        case .THB: return "THB (฿)"
        }
    }
}

// MARK: - Firestore-backed model for persistent poker groups

struct PokerGroup: Codable, Identifiable, Hashable {
    static func == (lhs: PokerGroup, rhs: PokerGroup) -> Bool {
        lhs.groupId == rhs.groupId
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(groupId)
    }
    var id: String { groupId }
    var groupId: String
    var name: String
    var currency: String             // e.g. "ILS", "USD"
    var currencySymbol: String       // e.g. "₪", "$"
    var defaultBuyIn: Double?        // optional default buy-in amount
    var createdBy: String            // Firebase UID of creator
    var createdAt: Date
    var memberIds: [String]          // Firebase UIDs
    var memberNames: [String: String]  // uid → display name
    
    init(groupId: String, name: String, createdBy: String, currency: CurrencyOption = .ILS, defaultBuyIn: Double? = nil) {
        self.groupId = groupId
        self.name = name
        self.currency = currency.rawValue
        self.currencySymbol = currency.symbol
        self.defaultBuyIn = defaultBuyIn
        self.createdBy = createdBy
        self.createdAt = Date()
        self.memberIds = [createdBy]
        self.memberNames = [:]
    }
    
    var memberCount: Int {
        memberIds.count
    }
    
    /// Convenience to get the CurrencyOption enum value
    var currencyOption: CurrencyOption {
        CurrencyOption(rawValue: currency) ?? .ILS
    }
}
