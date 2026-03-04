
import SwiftUI
import SwiftData

struct CashOutSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: GameViewModel
    let currencySymbol: String
    
    @State private var selectedSession: PlayerSession?
    @State private var amount: String = ""
    @FocusState private var isInputFocused: Bool
    
    /// Only players who haven't cashed out yet
    var activeSessions: [PlayerSession] {
        viewModel.activeSession.playerSessions.filter { !$0.hasCashedOut }
    }
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    Text("Cash Out")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.top)
                
                Text("Select a player leaving the table\nand enter their chip count")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
                
                // Player Selection (only active players)
                LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(activeSessions) { session in
                            let player = session.player
                            Button {
                                selectedSession = session
                            } label: {
                                VStack(spacing: 6) {
                                    Image(systemName: player?.avatar ?? "person.circle")
                                        .font(.largeTitle)
                                        .foregroundStyle(selectedSession?.id == session.id ? AppTheme.accent : .gray)
                                    Text(player?.name ?? "Unknown")
                                        .font(.caption)
                                        .foregroundStyle(.white)
                                    Text("In: \(currencySymbol)\(String(format: "%.0f", session.totalBuyIn))")
                                        .font(.caption2)
                                        .foregroundStyle(.gray)
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedSession?.id == session.id ? AppTheme.accent.opacity(0.1) : AppTheme.cardBackground)
                                        .stroke(selectedSession?.id == session.id ? AppTheme.accent : Color.clear, lineWidth: 2)
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Chip Count Input
                VStack(spacing: 8) {
                    Text("Chip Count")
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
                    
                    if let session = selectedSession, let value = Double(amount), value > 0 {
                        let profit = value - session.totalBuyIn
                        HStack(spacing: 4) {
                            Image(systemName: profit >= 0 ? "arrow.up.right" : "arrow.down.right")
                            Text("\(profit >= 0 ? "+" : "")\(currencySymbol)\(String(format: "%.0f", profit))")
                        }
                        .font(.subheadline.bold())
                        .foregroundStyle(profit >= 0 ? AppTheme.profit : AppTheme.loss)
                    }
                }
                .padding()
                
                // Confirm Button
                Button {
                    if let session = selectedSession, let value = Double(amount) {
                        viewModel.cashOutPlayer(session: session, amount: value)
                        dismiss()
                    }
                } label: {
                    HStack {
                        Image(systemName: "banknote")
                        Text("Confirm Cash Out")
                    }
                    .fontWeight(.bold)
                    .foregroundStyle(.black)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(canConfirm ? AppTheme.primaryGradient : LinearGradient(colors: [.gray.opacity(0.4)], startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(30)
                    .shadow(color: canConfirm ? AppTheme.accent.opacity(0.4) : .clear, radius: 10)
                }
                .disabled(!canConfirm)
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            }
        }
        .onAppear {
            isInputFocused = true
        }
    }
    
    private var canConfirm: Bool {
        selectedSession != nil && !amount.isEmpty && (Double(amount) ?? -1) >= 0
    }
}
