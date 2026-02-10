
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
                    
                    AccentButton(title: "Return to Home") {
                        dismiss()
                    }
                }
                .padding()
            }
        }
    }
}
