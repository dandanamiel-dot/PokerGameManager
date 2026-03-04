
import SwiftUI
import SwiftData

struct AddBuyInSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: GameViewModel
    let currencySymbol: String
    
    @State private var selectedPlayer: Player?
    @State private var amount: String = ""
    @FocusState private var isInputFocused: Bool
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    Text("Add Buy-In")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.top)
                    
                    // Player Selection
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(viewModel.availablePlayers) { player in
                            Button {
                                selectedPlayer = player
                            } label: {
                                VStack {
                                    Image(systemName: player.avatar)
                                        .font(.largeTitle)
                                        .foregroundStyle(selectedPlayer == player ? AppTheme.accent : .gray)
                                    Text(player.name)
                                        .font(.caption)
                                        .foregroundStyle(.white)
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedPlayer == player ? AppTheme.accent.opacity(0.1) : AppTheme.cardBackground)
                                        .stroke(selectedPlayer == player ? AppTheme.accent : Color.clear, lineWidth: 2)
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Amount Input
                    VStack(spacing: 8) {
                    Text("Amount")
                        .foregroundStyle(AppTheme.textSecondary)
                    
                    HStack {
                        Text(currencySymbol)
                            .foregroundStyle(AppTheme.accent)
                            .font(.title)
                        TextField("0", text: $amount)
                            .keyboardType(.numberPad)
                            .foregroundStyle(.white)
                            .font(.system(size: 40, weight: .bold))
                            .multilineTextAlignment(.center)
                            .focused($isInputFocused)
                        }
                        
                        if let player = selectedPlayer {
                            let currentInvestment = viewModel.activeSession.playerSessions.first(where: { $0.player?.id == player.id })?.totalBuyIn ?? 0
                            
                            HStack {
                                Text("Current Investment: \(currencySymbol)\(String(format: "%.0f", currentInvestment))")
                                Spacer()
                                if let value = Double(amount), value > 0 {
                                    let newTotal = currentInvestment + value
                                    Text("New Total: \(currencySymbol)\(String(format: "%.0f", newTotal))")
                                        .foregroundStyle(AppTheme.accent)
                                        .bold()
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(.gray)
                            .padding(.top, 4)
                        }
                    }
                    .padding()
                
                    AccentButton(title: "Confirm Buy-In") {
                        if let player = selectedPlayer, let value = Double(amount) {
                            viewModel.addBuyIn(player: player, amount: value)
                            dismiss()
                        }
                    }
                    .disabled(selectedPlayer == nil || amount.isEmpty)
                    .opacity((selectedPlayer == nil || amount.isEmpty) ? 0.5 : 1)
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
            }
        }
        .onAppear {
            isInputFocused = true
        }
    }
}
