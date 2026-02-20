
import SwiftUI
import SwiftData

struct NewGameSheet: View {
    let groupId: String
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query private var players: [Player]
    @State private var selectedPlayers: Set<Player> = []
    @State private var buyInAmount: String = "500" // Default buy-in
    @State private var showAddPlayer = false
    
    init(groupId: String = "local") {
        self.groupId = groupId
        let gId = groupId
        _players = Query(
            filter: #Predicate<Player> { $0.groupId == gId },
            sort: \Player.name
        )
    }
    
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
                            Button {
                                showAddPlayer = true
                            } label: {
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
        .sheet(isPresented: $showAddPlayer) {
            AddPlayerView(groupId: groupId)
        }
    }
    
    private func startGame() {
        let game = GameSession(groupId: groupId)
        let initialAmount = Double(buyInAmount) ?? 0
        
        for player in selectedPlayers {
            let session = PlayerSession(player: player)
            if initialAmount > 0 {
                session.addBuyIn(amount: initialAmount)
            }
            game.playerSessions.append(session)
        }
        
        modelContext.insert(game)
        try? modelContext.save()
        dismiss()
    }
}

// View for adding a player on the fly
struct AddPlayerView: View {
    let groupId: String
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @FocusState private var nameFieldFocused: Bool
    
    init(groupId: String = "local") {
        self.groupId = groupId
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 50))
                        .foregroundStyle(AppTheme.accent)
                        .padding(.top, 20)
                    
                    Text("Add New Player")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Player Name")
                            .font(.caption)
                            .foregroundStyle(.gray)
                        
                        TextField("e.g. Alex", text: $name)
                            .foregroundStyle(.white)
                            .padding()
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppTheme.accent.opacity(0.3), lineWidth: 1)
                            )
                            .focused($nameFieldFocused)
                    }
                    .padding(.horizontal, 24)
                    
                    AccentButton(title: "Save Player", icon: "checkmark") {
                        let player = Player(name: name.trimmingCharacters(in: .whitespaces), groupId: groupId)
                        modelContext.insert(player)
                        try? modelContext.save()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .opacity(name.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
                    
                    Spacer()
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
        .onAppear {
            nameFieldFocused = true
        }
    }
}
