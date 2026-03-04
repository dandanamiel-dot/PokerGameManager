
import SwiftUI
import SwiftData
import Combine

class GameViewModel: ObservableObject {
    @Published var activeSession: GameSession
    @Published var availablePlayers: [Player] = []
    @Published var showSettlementView = false
    @Published var saveError: String?        // Issue 6: surfaced to views for alert

    private var modelContext: ModelContext
    private let groupId: String
    
    init(modelContext: ModelContext, session: GameSession) {
        self.modelContext = modelContext
        self.activeSession = session
        self.groupId = session.groupId
        fetchPlayers()
    }
    
    func fetchPlayers() {
        let gId = groupId
        do {
            let descriptor = FetchDescriptor<Player>(
                predicate: #Predicate { $0.groupId == gId }
            )
            availablePlayers = try modelContext.fetch(descriptor)
        } catch {
            print("Failed to fetch players: \(error)")
        }
    }
    
    func addBuyIn(player: Player, amount: Double) {
        if let existingSession = activeSession.playerSessions.first(where: { $0.player?.id == player.id }) {
            existingSession.addBuyIn(amount: amount)
        } else {
            let newSession = PlayerSession(player: player)
            newSession.addBuyIn(amount: amount)
            activeSession.playerSessions.append(newSession)
            modelContext.insert(newSession)
        }
        saveContext()
        objectWillChange.send()
    }
    
    func calculateSettlements() {
        activeSession.status = .completed
        activeSession.endedAt = Date()
        saveContext()
    }
    
    /// Cash out a player mid-game
    func cashOutPlayer(session: PlayerSession, amount: Double) {
        session.cashOut = amount
        session.cashOutTime = Date()
        saveContext()
        objectWillChange.send()
    }

    // MARK: - Issue 6: Safe save helper
    /// Saves the model context, logging errors and surfacing them via `saveError`.
    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            let msg = "Failed to save game data: \(error.localizedDescription)"
            print("⚠️ SwiftData save error: \(error)")
            DispatchQueue.main.async { [weak self] in
                self?.saveError = msg
            }
        }
    }

    struct SettlementTransaction: Identifiable {
        let id = UUID()
        let from: String
        let to: String
        let amount: Double
    }
    
    func generateTransactions() -> [SettlementTransaction] {
        var debtors: [(name: String, amount: Double)] = []
        var creditors: [(name: String, amount: Double)] = []
        
        for pSession in activeSession.playerSessions {
            let pl = pSession.profitLoss
            if pl < -0.01 {
                debtors.append((pSession.player?.name ?? "Unknown", abs(pl)))
            } else if pl > 0.01 {
                creditors.append((pSession.player?.name ?? "Unknown", pl))
            }
        }
        
        debtors.sort { $0.amount > $1.amount }
        creditors.sort { $0.amount > $1.amount }
        
        var transactions: [SettlementTransaction] = []
        var i = 0
        var j = 0
        
        while i < debtors.count && j < creditors.count {
            let debt = debtors[i].amount
            let credit = creditors[j].amount
            let amount = min(debt, credit)
            transactions.append(SettlementTransaction(from: debtors[i].name, to: creditors[j].name, amount: amount))
            debtors[i].amount -= amount
            creditors[j].amount -= amount
            if debtors[i].amount < 0.01 { i += 1 }
            if creditors[j].amount < 0.01 { j += 1 }
        }
        
        return transactions
    }
}
