import Foundation

/// Works out who pays whom at the end of a game, using as few transfers as
/// the greedy largest-debtor / largest-creditor match allows.
nonisolated enum SettlementCalculator {

    nonisolated struct Transfer: Equatable {
        let from: String
        let to: String
        let amount: Double
    }

    /// `balances` are each player's profit (+) or loss (-).
    static func transfers(balances: [(name: String, amount: Double)]) -> [Transfer] {
        var debtors: [(name: String, amount: Double)] = []
        var creditors: [(name: String, amount: Double)] = []

        for balance in balances {
            if balance.amount < -0.01 {
                debtors.append((balance.name, abs(balance.amount)))
            } else if balance.amount > 0.01 {
                creditors.append((balance.name, balance.amount))
            }
        }

        debtors.sort { $0.amount > $1.amount }
        creditors.sort { $0.amount > $1.amount }

        var transfers: [Transfer] = []
        var i = 0
        var j = 0

        while i < debtors.count && j < creditors.count {
            let amount = min(debtors[i].amount, creditors[j].amount)
            transfers.append(Transfer(from: debtors[i].name, to: creditors[j].name, amount: amount))
            debtors[i].amount -= amount
            creditors[j].amount -= amount
            if debtors[i].amount < 0.01 { i += 1 }
            if creditors[j].amount < 0.01 { j += 1 }
        }

        return transfers
    }

    static func transfers(for players: [PlayerSnapshot]) -> [Transfer] {
        transfers(balances: players.map { (name: $0.name, amount: $0.profitLoss) })
    }
}
