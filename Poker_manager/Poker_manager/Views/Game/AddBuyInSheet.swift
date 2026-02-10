
import SwiftUI
import SwiftData

struct AddBuyInSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: GameViewModel
    
    @State private var selectedPlayer: Player?
    @State private var amount: String = ""
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            VStack(spacing: 24) {
               Text("Add Buy-In")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.top)
                
                // Player Selection
                ScrollView {
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
                    .padding()
                }
                
                // Amount Input
                VStack(spacing: 8) {
                    Text("Amount")
                        .foregroundStyle(AppTheme.textSecondary)
                    
                    HStack {
                        Text("₪")
                            .foregroundStyle(AppTheme.accent)
                            .font(.title)
                        
                        TextField("0", text: $amount)
                            .keyboardType(.numberPad)
                            .foregroundStyle(.white)
                            .font(.system(size: 40, weight: .bold))
                            .multilineTextAlignment(.center)
                    }
                }
                .padding()
                
                Spacer()
                
                AccentButton(title: "Confirm Buy-In") {
                    if let player = selectedPlayer, let value = Double(amount) {
                        viewModel.addBuyIn(player: player, amount: value)
                        dismiss()
                    }
                }
                .disabled(selectedPlayer == nil || amount.isEmpty)
                .opacity((selectedPlayer == nil || amount.isEmpty) ? 0.5 : 1)
                
            }
            .padding()
        }
    }
}
