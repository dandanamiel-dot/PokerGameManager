
import SwiftUI
import SwiftData

struct NewGameSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \Player.name) private var players: [Player]
    @State private var selectedPlayers: Set<Player> = []
    @State private var buyInAmount: String = "500" // Default buy-in
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Text("New Game Session")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.top)
                    
                    // Default Buy-In
                    VStack(alignment: .leading) {
                        Text("Initial Buy-In")
                            .foregroundStyle(AppTheme.textSecondary)
                        
                        TextField("Amount", text: $buyInAmount)
                            .keyboardType(.numberPad)
                            .padding()
                            .background(AppTheme.cardBackground)
                            .cornerRadius(12)
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal)
                    
                    // Player Selection
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Select Players")
                                .foregroundStyle(AppTheme.textSecondary)
                            Spacer()
                            NavigationLink(destination: AddPlayerView()) {
                                Image(systemName: "person.badge.plus")
                                    .foregroundStyle(AppTheme.accent)
                            }
                        }
                        .padding(.horizontal)
                        
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                ForEach(players) { player in
                                    Button {
                                        if selectedPlayers.contains(player) {
                                            selectedPlayers.remove(player)
                                        } else {
                                            selectedPlayers.insert(player)
                                        }
                                    } label: {
                                        VStack {
                                            Image(systemName: player.avatar)
                                                .font(.largeTitle)
                                                .foregroundStyle(selectedPlayers.contains(player) ? AppTheme.accent : .gray)
                                            Text(player.name)
                                                .font(.caption)
                                                .foregroundStyle(.white)
                                        }
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(selectedPlayers.contains(player) ? AppTheme.accent.opacity(0.1) : AppTheme.cardBackground)
                                                .stroke(selectedPlayers.contains(player) ? AppTheme.accent : Color.clear, lineWidth: 2)
                                        )
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                    
                    Spacer()
                    
                    AccentButton(title: "Start Game") {
                        startGame()
                    }
                    .disabled(selectedPlayers.isEmpty)
                    .opacity(selectedPlayers.isEmpty ? 0.5 : 1)
                    .padding(.bottom)
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
    }
    
    private func startGame() {
        let game = GameSession()
        let initialAmount = Double(buyInAmount) ?? 0
        
        for player in selectedPlayers {
            let session = PlayerSession(player: player)
            if initialAmount > 0 {
                session.addBuyIn(amount: initialAmount)
            }
            game.playerSessions.append(session)
            // session is automatically inserted when added to game.playerSessions relationship?
            // Safer to insert explicitly if issues arise, but SwiftData usually handles it.
        }
        
        modelContext.insert(game)
        try? modelContext.save()
        dismiss()
    }
}

// Simple internal view for adding a player on the fly
struct AddPlayerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            VStack(spacing: 20) {
                Text("Add New Player")
                    .font(.title)
                    .foregroundStyle(.white)
                
                TextField("Player Name", text: $name)
                    .padding()
                    .background(AppTheme.cardBackground)
                    .cornerRadius(12)
                    .foregroundStyle(.white)
                    .padding()
                
                AccentButton(title: "Save Player") {
                    let player = Player(name: name)
                    modelContext.insert(player)
                    dismiss()
                }
                .disabled(name.isEmpty)
            }
        }
    }
}
