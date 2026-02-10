
import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \GameSession.date, order: .reverse) private var allGames: [GameSession]
    @State private var selectedGame: GameSession?
    
    var completedGames: [GameSession] {
        allGames.filter { $0.status == .completed }
    }
    
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("History")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    Spacer()
                }
                .padding()
                .padding(.top, 40)
                                
                ScrollView {
                    VStack(spacing: 24) {
                        // Stats Overview (Carousel)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                let totalPotAllTime = completedGames.reduce(0) { $0 + $1.totalPot }
                                StatCard(title: "Total Pot All-Time", value: "₪\(String(format: "%.0f", totalPotAllTime))", icon: "banknote", trend: nil)
                                    .frame(width: 160)
                                
                                StatCard(title: "Games Played", value: "\(completedGames.count)", icon: "gamecontroller", trend: nil)
                                    .frame(width: 160)
                            }
                            .padding(.horizontal)
                        }
                        
                        // Games List
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Past Sessions")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .padding(.horizontal)
                            
                            if completedGames.isEmpty {
                                Text("No completed games yet.")
                                    .foregroundStyle(AppTheme.textSecondary)
                                    .padding()
                            }
                            
                            ForEach(completedGames) { game in
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
                                        Text("₪\(String(format: "%.0f", game.totalPot))")
                                            .foregroundStyle(AppTheme.accent)
                                            .fontWeight(.bold)
                                        
                                        Image(systemName: "chevron.right")
                                            .foregroundStyle(AppTheme.textSecondary)
                                            .font(.caption)
                                    }
                                    .padding()
                                }
                                .onTapGesture {
                                    selectedGame = game
                                }
                            }
                        }
                    }
                    .padding(.bottom, 100)
                }
            }
        }
        .fullScreenCover(item: $selectedGame) { game in
            GameSessionView(session: game, modelContext: modelContext)
        }
    }
}

#Preview {
    HistoryView()
}
