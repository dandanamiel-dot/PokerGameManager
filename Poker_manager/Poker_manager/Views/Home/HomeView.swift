
import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \GameSession.date, order: .reverse) private var recentGames: [GameSession]
    @State private var showNewGameSheet = false
    @State private var selectedGame: GameSession?
    
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
                            
                            HStack(spacing: 16) {
                                AccentButton(title: "New Game", icon: "plus") {
                                    showNewGameSheet = true
                                }
                                
                                Button {
                                    // Resume action
                                } label: {
                                    HStack {
                                        Image(systemName: "play.fill")
                                        Text("Resume")
                                    }
                                    .fontWeight(.bold)
                                    .foregroundStyle(AppTheme.accent)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 24)
                                    .background(Color.black.opacity(0.3))
                                    .cornerRadius(30)
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
                .fullScreenCover(item: $selectedGame) { game in
                    GameSessionView(session: game, modelContext: modelContext)
                }
            }
        }
    }
}

#Preview {
    HomeView()
}
