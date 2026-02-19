
import SwiftUI

struct SettlementView: View {
    @ObservedObject var viewModel: GameViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    Text("Settlement")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.top)
                    
                    Text("The game has ended. Here is how to settle debts.")
                        .foregroundStyle(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                    
                    // Transactions List
                    VStack(spacing: 16) {
                        ForEach(viewModel.generateTransactions()) { transaction in
                            GlowCard {
                                HStack {
                                    // Payer
                                    VStack(alignment: .leading) {
                                        Text(transaction.from)
                                            .fontWeight(.bold)
                                            .foregroundStyle(AppTheme.loss)
                                        Text("Pays")
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.textSecondary)
                                    }
                                    
                                    Spacer()
                                    
                                    // Amount with Arrow
                                    VStack {
                                        Text("₪\(transaction.amount, specifier: "%.0f")")
                                            .fontWeight(.bold)
                                            .foregroundStyle(.white)
                                        Image(systemName: "arrow.right")
                                            .foregroundStyle(AppTheme.accent)
                                    }
                                    
                                    Spacer()
                                    
                                    // Receiver
                                    VStack(alignment: .trailing) {
                                        Text(transaction.to)
                                            .fontWeight(.bold)
                                            .foregroundStyle(AppTheme.profit)
                                        Text("Receives")
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.textSecondary)
                                    }
                                }
                                .padding()
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Share Settlement
                    ShareLink(
                        item: settlementText,
                        subject: Text("Poker Settlement"),
                        message: Text("Here's the settlement breakdown:")
                    ) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share Settlement")
                        }
                        .font(.headline)
                        .foregroundStyle(AppTheme.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(AppTheme.accent, lineWidth: 1.5)
                        )
                    }
                    
                    AccentButton(title: "Return to Home") {
                        dismiss()
                    }
                }
                .padding()
            }
        }
    }
    
    // MARK: - Settlement Text for Sharing
    
    private var settlementText: String {
        let transactions = viewModel.generateTransactions()
        var lines: [String] = ["🃏 Poker Settlement"]
        lines.append("---")
        for t in transactions {
            lines.append("\(t.from) → \(t.to): ₪\(String(format: "%.0f", t.amount))")
        }
        return lines.joined(separator: "\n")
    }
}
