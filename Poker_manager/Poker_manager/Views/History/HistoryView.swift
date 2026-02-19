
import SwiftUI
import SwiftData
import Charts

struct HistoryView: View {
    let currencySymbol: String
    let groupId: String
    
    @Environment(\.modelContext) private var modelContext
    @Query private var allGames: [GameSession]
    @State private var selectedGame: GameSession?
    @State private var gameToEdit: GameSession?
    
    init(currencySymbol: String, groupId: String) {
        self.currencySymbol = currencySymbol
        self.groupId = groupId
        let gId = groupId
        _allGames = Query(
            filter: #Predicate<GameSession> { $0.groupId == gId },
            sort: \GameSession.date,
            order: .reverse
        )
    }
    
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


                        // Chart Section
                        if !completedGames.isEmpty {
                            VStack(alignment: .leading) {
                                Text("Pot Trend")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal)
                                
                                Chart {
                                    ForEach(completedGames.prefix(10)) { game in
                                        BarMark(
                                            x: .value("Date", game.date, unit: .day),
                                            y: .value("Pot", game.totalPot)
                                        )
                                        .foregroundStyle(AppTheme.primaryGradient)
                                        .cornerRadius(4)
                                    }
                                }
                                .frame(height: 200)
                                .chartYAxis {
                                    AxisMarks(position: .leading, values: .automatic) { value in
                                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [5, 5]))
                                            .foregroundStyle(Color.white.opacity(0.2))
                                        AxisValueLabel() {
                                            if let intValue = value.as(Int.self) {
                                                Text("\(currencySymbol)\(intValue)")
                                                    .foregroundStyle(AppTheme.textSecondary)
                                            }
                                        }
                                    }
                                }
                                .chartXAxis {
                                    AxisMarks(values: .stride(by: .day)) { value in
                                        if let date = value.as(Date.self) {
                                            AxisValueLabel(format: .dateTime.day().month())
                                                .foregroundStyle(AppTheme.textSecondary)
                                        }
                                    }
                                }
                                .padding()
                                .background(AppTheme.cardBackground.opacity(0.5))
                                .cornerRadius(16)
                                .padding(.horizontal)
                            }
                        }

                        // Stats Overview (Carousel)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                let totalPotAllTime = completedGames.reduce(0) { $0 + $1.totalPot }
                                let avgPot = completedGames.isEmpty ? 0 : totalPotAllTime / Double(completedGames.count)
                                
                                StatCard(title: "Total Pot", value: "\(currencySymbol)\(String(format: "%.0f", totalPotAllTime))", icon: "banknote", trend: nil)
                                    .frame(width: 150)
                                
                                StatCard(title: "Avg Pot", value: "\(currencySymbol)\(String(format: "%.0f", avgPot))", icon: "chart.bar", trend: nil)
                                    .frame(width: 150)

                                StatCard(title: "Games", value: "\(completedGames.count)", icon: "gamecontroller", trend: nil)
                                    .frame(width: 120)
                                
                                // Biggest Winner Calculation
                                let biggestWin = completedGames.flatMap { $0.playerSessions }.map { $0.profitLoss }.max() ?? 0
                                if biggestWin > 0 {
                                    StatCard(title: "Best Win", value: "\(currencySymbol)\(String(format: "%.0f", biggestWin))", icon: "trophy.fill", trend: nil)
                                        .frame(width: 150)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Leaderboard
                        if !completedGames.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Image(systemName: "crown.fill")
                                        .foregroundStyle(.yellow)
                                    Text("Leaderboard")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.white)
                                }
                                .padding(.horizontal)
                                
                                let leaderboard = buildLeaderboard()
                                
                                ForEach(Array(leaderboard.enumerated()), id: \.element.name) { index, entry in
                                    GlowCard {
                                        HStack(spacing: 12) {
                                            // Rank badge
                                            ZStack {
                                                Circle()
                                                    .fill(index == 0 ? Color.yellow.opacity(0.2) : index == 1 ? Color.gray.opacity(0.2) : index == 2 ? Color.orange.opacity(0.2) : AppTheme.cardBackground)
                                                    .frame(width: 36, height: 36)
                                                Text("\(index + 1)")
                                                    .font(.headline)
                                                    .fontWeight(.black)
                                                    .foregroundStyle(index == 0 ? .yellow : index == 1 ? .gray : index == 2 ? .orange : .white)
                                            }
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(entry.name)
                                                    .foregroundStyle(.white)
                                                    .fontWeight(.semibold)
                                                Text("\(entry.gamesPlayed) games")
                                                    .font(.caption)
                                                    .foregroundStyle(AppTheme.textSecondary)
                                            }
                                            
                                            Spacer()
                                            
                                            Text("\(currencySymbol)\(String(format: "%.0f", entry.totalProfit))")
                                                .font(.title3)
                                                .fontWeight(.bold)
                                                .foregroundStyle(entry.totalProfit >= 0 ? AppTheme.profit : AppTheme.loss)
                                        }
                                        .padding()
                                    }
                                }
                            }
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
                                        Text("\(currencySymbol)\(String(format: "%.0f", game.totalPot))")
                                            .foregroundStyle(AppTheme.accent)
                                            .fontWeight(.bold)
                                        
                                        Image(systemName: "chevron.right")
                                            .foregroundStyle(AppTheme.textSecondary)
                                            .font(.caption)
                                    }
                                    .padding()
                                }
                                .contextMenu {
                                    Button {
                                        gameToEdit = game
                                    } label: {
                                        Label("Edit Details", systemImage: "pencil")
                                    }
                                    
                                    Button {
                                        reopenGame(game)
                                    } label: {
                                        Label("Re-open Game", systemImage: "arrow.uturn.backward")
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
                    .padding(.bottom, 100)
                }
            }
        }
        .fullScreenCover(item: $selectedGame) { game in
            GameSessionView(session: game, modelContext: modelContext)
        }
        .sheet(item: $gameToEdit) { game in
            EditGameSheet(game: game)
        }
    }
    
    private func deleteGame(_ game: GameSession) {
        withAnimation {
            modelContext.delete(game)
        }
    }
    
    private func reopenGame(_ game: GameSession) {
        withAnimation {
            game.status = .active
            game.endedAt = nil
        }
    }
    
    // MARK: - Leaderboard
    struct LeaderboardEntry {
        let name: String
        let totalProfit: Double
        let gamesPlayed: Int
    }
    
    private func buildLeaderboard() -> [LeaderboardEntry] {
        var playerStats: [String: (profit: Double, games: Int)] = [:]
        
        for game in completedGames {
            for session in game.playerSessions {
                let name = session.player?.name ?? "Unknown"
                let existing = playerStats[name] ?? (profit: 0, games: 0)
                playerStats[name] = (profit: existing.profit + session.profitLoss, games: existing.games + 1)
            }
        }
        
        return playerStats
            .map { LeaderboardEntry(name: $0.key, totalProfit: $0.value.profit, gamesPlayed: $0.value.games) }
            .sorted { $0.totalProfit > $1.totalProfit }
    }
}

#Preview {
    HistoryView(currencySymbol: "₪", groupId: "local")
}
