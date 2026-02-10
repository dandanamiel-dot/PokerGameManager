
import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \GameSession.date, order: .reverse) private var recentGames: [GameSession]
    @State private var showNewGameSheet = false
    @State private var selectedGame: GameSession?
    @State private var gameToEdit: GameSession?
    
    var activeGame: GameSession? {
        recentGames.first(where: { $0.status == .active })
    }
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Poker Manager")
                                .font(.headline)
                                .foregroundStyle(AppTheme.textSecondary)
                            Text("Good Evening")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                        }
                        Spacer()
                        Image(systemName: "bell.badge")
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(AppTheme.cardBackground)
                            .clipShape(Circle())
                    }
                    .padding(.top, 60)
                    
                    // Portfolio/Game Snapshot
                    GlowCard {
                        VStack(spacing: 20) {
                            Text(activeGame != nil ? "Active Pot" : "Total Tracked Pot")
                                .foregroundStyle(AppTheme.textSecondary)
                                .font(.subheadline)
                            
                            Text("₪\(activeGame?.totalPot ?? 0, specifier: "%.2f")")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            
                            if let game = activeGame {
                                AccentButton(title: "Take Me to the Table", icon: "suit.spade.fill") {
                                    selectedGame = game
                                }
                            } else {
                                AccentButton(title: "Start New Game", icon: "plus") {
                                    showNewGameSheet = true
                                }
                            }
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if let game = activeGame {
                                selectedGame = game
                            }
                        }
                    }
                    
                    // Recent Transactions / Players styling
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Recent Games")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                            Spacer()
                            Text("See all")
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        
                        ForEach(recentGames.prefix(3)) { game in
                            GlowCard {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(game.date.formatted(date: .abbreviated, time: .shortened))
                                            .foregroundStyle(.white)
                                            .fontWeight(.medium)
                                        Text("\(game.playerCount) Players")
                                            .foregroundStyle(AppTheme.textSecondary)
                                            .font(.caption)
                                    }
                                    Spacer()
                                    Text("₪\(game.totalPot, specifier: "%.0f")")
                                        .foregroundStyle(AppTheme.accent)
                                        .fontWeight(.bold)
                                }
                                .padding()
                            }
                            .contextMenu {
                                Button {
                                    gameToEdit = game
                                } label: {
                                    Label("Edit Details", systemImage: "pencil")
                                }
                                
                                if game.status == .completed {
                                    Button {
                                        reopenGame(game)
                                    } label: {
                                        Label("Re-open Game", systemImage: "arrow.uturn.backward")
                                    }
                                }
                                
                                Button(role: .destructive) {
                                    deleteGame(game)
                                } label: {
                                    Label("Delete Game", systemImage: "trash")
                                }
                            }
                            .onTapGesture {
                                selectedGame = game
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 100) // Space for tab bar
                .sheet(isPresented: $showNewGameSheet) {
                    NewGameSheet()
                }
                .sheet(item: $gameToEdit) { game in
                    EditGameSheet(game: game)
                }
                .fullScreenCover(item: $selectedGame) { game in
                    GameSessionView(session: game, modelContext: modelContext)
                }
            }
        }
    }
    
    // MARK: - Actions
    private func deleteGame(_ game: GameSession) {
        withAnimation {
            modelContext.delete(game)
            // Save handled automatically or by context
        }
    }
    
    private func reopenGame(_ game: GameSession) {
        withAnimation {
            game.status = .active
            game.endedAt = nil
        }
    }
}

#Preview {
    HomeView()
}
