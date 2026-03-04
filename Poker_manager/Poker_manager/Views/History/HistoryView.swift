
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
    @State private var gameToDelete: GameSession?      // #10 delete confirmation
    @State private var showDeleteGameAlert = false
    @State private var selectedChartGame: GameSession?
    @State private var selectedBarScale: CGFloat = 1.0
    
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
                // Header — matches GameSession style
                HStack {
                    Color.clear.frame(width: 44, height: 44)
                    Spacer()
                    Text("History")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Spacer()
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal)
                .padding(.top, 16)
                                
                ScrollView {
                    VStack(spacing: 24) {


                        if !completedGames.isEmpty {
                            potTrendChart
                        }

                        // Stats Overview (Carousel) — only shown when there's data
                        if !completedGames.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    let totalPotAllTime = completedGames.reduce(0) { $0 + $1.totalPot }
                                    let avgPot = totalPotAllTime / Double(completedGames.count)
                                    
                                    StatCard(title: "Total Pot", value: "\(currencySymbol)\(String(format: "%.0f", totalPotAllTime))", icon: "banknote", trend: nil)
                                        .frame(width: 150)
                                    
                                    StatCard(title: "Avg Pot", value: "\(currencySymbol)\(String(format: "%.0f", avgPot))", icon: "chart.bar", trend: nil)
                                        .frame(width: 150)

                                    StatCard(title: "Games", value: "\(completedGames.count)", icon: "gamecontroller", trend: nil)
                                        .frame(width: 120)
                                    
                                    let biggestWin = completedGames.flatMap { $0.playerSessions }.map { $0.profitLoss }.max() ?? 0
                                    if biggestWin > 0 {
                                        StatCard(title: "Best Win", value: "\(currencySymbol)\(String(format: "%.0f", biggestWin))", icon: "trophy.fill", trend: nil)
                                            .frame(width: 150)
                                    }
                                }
                                .padding(.horizontal)
                            }
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
                            if !completedGames.isEmpty {
                                Text("Past Sessions")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal)
                            }
                            
                            // #9 Full empty state
                            if completedGames.isEmpty {
                                VStack(spacing: 16) {
                                    Image(systemName: "trophy")
                                        .font(.system(size: 50))
                                        .foregroundStyle(AppTheme.accent.opacity(0.35))
                                    Text("No History Yet")
                                        .font(.title3.bold())
                                        .foregroundStyle(.white)
                                    Text("Play your first game to see\nstats and leaderboards here.")
                                        .font(.subheadline)
                                        .foregroundStyle(AppTheme.textSecondary)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 48)
                                .background(AppTheme.cardBackground)
                                .cornerRadius(20)
                                .padding(.horizontal)
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
                                        gameToDelete = game
                                        showDeleteGameAlert = true
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
            GameSessionView(session: game, modelContext: modelContext, currencySymbol: currencySymbol)
        }
        .sheet(item: $gameToEdit) { game in
            EditGameSheet(game: game)
        }
        .alert("Delete Game?", isPresented: $showDeleteGameAlert) {
            Button("Cancel", role: .cancel) { gameToDelete = nil }
            Button("Delete", role: .destructive) {
                if let game = gameToDelete {
                    deleteGame(game)
                    gameToDelete = nil
                }
            }
        } message: {
            Text("This will permanently delete all session data. This cannot be undone.")
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
    
    // MARK: - Pot Trend Chart
    @ViewBuilder
    private var potTrendChart: some View {
        let chartGames = Array(completedGames.prefix(10).reversed())
        VStack(alignment: .leading, spacing: 8) {
            Text("Pot Trend")
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal)
            
            if let sel = selectedChartGame {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(sel.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption2)
                            .foregroundStyle(AppTheme.textSecondary)
                        Text("\(currencySymbol)\(sel.totalPot, specifier: "%.0f")")
                            .font(.headline.bold())
                            .foregroundStyle(AppTheme.accent)
                    }
                    Spacer()
                    Text("\(sel.playerCount) players")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(AppTheme.accent.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(AppTheme.accent.opacity(0.4), lineWidth: 1)
                )
                .cornerRadius(10)
                .padding(.horizontal)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            Chart {
                ForEach(chartGames) { game in
                    let isSelected = selectedChartGame?.id == game.id
                    BarMark(
                        x: .value("Date", game.date, unit: .day),
                        y: .value("Pot", game.totalPot)
                    )
                    .foregroundStyle(
                        isSelected
                            ? AnyShapeStyle(AppTheme.accent)
                            : AnyShapeStyle(AppTheme.primaryGradient)
                    )
                    .cornerRadius(6)
                    .opacity(selectedChartGame == nil || isSelected ? 1.0 : 0.4)
                }
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [5, 5]))
                        .foregroundStyle(Color.white.opacity(0.2))
                    AxisValueLabel() {
                        if let intValue = value.as(Int.self) {
                            Text("\(currencySymbol)\(intValue)")
                                .font(.caption2)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { value in
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle().fill(.clear).contentShape(Rectangle())
                        .onTapGesture { location in
                            handleChartTap(at: location, proxy: proxy, geo: geo, games: chartGames)
                        }
                }
            }
            .animation(.easeInOut(duration: 0.2), value: selectedChartGame?.id)
            .padding()
            .background(AppTheme.cardBackground.opacity(0.5))
            .cornerRadius(16)
            .padding(.horizontal)
        }
    }
    
    private func handleChartTap(at location: CGPoint, proxy: ChartProxy, geo: GeometryProxy, games: [GameSession]) {
        guard let plotFrame = proxy.plotFrame else { return }
        let xPos = location.x - geo[plotFrame].origin.x
        guard let date: Date = proxy.value(atX: xPos) else { return }
        let tapped = games.min(by: {
            abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
        })
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            selectedChartGame = (selectedChartGame?.id == tapped?.id) ? nil : tapped
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
