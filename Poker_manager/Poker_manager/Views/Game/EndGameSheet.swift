
import SwiftUI

struct EndGameSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        Text("Cash Out")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                        
                        Text("Enter the final chip value for each player.")
                            .foregroundStyle(AppTheme.textSecondary)
                            .multilineTextAlignment(.center)
                        
                        ForEach($viewModel.activeSession.playerSessions) { $session in
                            GlowCard {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(session.player?.name ?? "Unknown")
                                            .foregroundStyle(.white)
                                            .fontWeight(.bold)
                                        Text("In: ₪\(session.totalBuyIn, specifier: "%.0f")")
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.textSecondary)
                                    }
                                    
                                    Spacer()
                                    
                                    TextField("0", value: Binding(
                                        get: { session.cashOut ?? 0 },
                                        set: { session.cashOut = $0 }
                                    ), format: .number)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .foregroundStyle(AppTheme.accent)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .frame(width: 100)
                                    .padding(8)
                                    .background(Color.black.opacity(0.3))
                                    .cornerRadius(8)
                                }
                                .padding()
                            }
                        }
                        
                        // Validation summary
                        let totalBuyIn = viewModel.activeSession.totalPot
                        let totalCashOut = viewModel.activeSession.playerSessions.reduce(0) { $0 + ($1.cashOut ?? 0) }
                        let diff = totalCashOut - totalBuyIn
                        
                        if abs(diff) > 1 {
                             Text("⚠️ Mismatch: ₪\(diff, specifier: "%.0f")")
                                .foregroundStyle(AppTheme.loss)
                                .fontWeight(.bold)
                        } else {
                            Text("✅ Balanced")
                                .foregroundStyle(AppTheme.profit)
                                .fontWeight(.bold)
                        }

                        Spacer().frame(height: 40)
                        
                        AccentButton(title: "Calculate Settlement") {
                            viewModel.calculateSettlements()
                            viewModel.showSettlementView = true
                        }
                        .disabled(abs(diff) > 1)
                        .opacity(abs(diff) > 1 ? 0.5 : 1)
                    }
                    .padding()
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
        }
    }
}
