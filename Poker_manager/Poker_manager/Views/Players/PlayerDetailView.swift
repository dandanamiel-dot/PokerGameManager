import SwiftUI
import SwiftData
import Charts

struct PlayerDetailView: View {
    let player: Player
    let currencySymbol: String
    
    // Computed stats
    var gamesPlayed: Int {
        player.sessions.count
    }
    
    var totalInvested: Double {
        player.sessions.reduce(0) { $0 + $1.totalBuyIn }
    }
    
    var netProfit: Double {
        player.sessions.reduce(0) { $0 + $1.profitLoss }
    }
    
    var bestWin: Double {
        player.sessions.map { $0.profitLoss }.max() ?? 0
    }
    
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: player.avatar)
                            .font(.system(size: 80))
                            .foregroundStyle(AppTheme.accent)
                            .padding()
                            .background(AppTheme.accent.opacity(0.1))
                            .clipShape(Circle())
                            .overlay(Circle().stroke(AppTheme.accent, lineWidth: 2))
                        
                        Text(player.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }
                    .padding(.top, 16)
                    
                    // Stats Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        StatCard(title: "Games Played", value: "\(gamesPlayed)", icon: "gamecontroller", trend: nil)
                        StatCard(title: "Total Invested", value: "\(currencySymbol)\(String(format: "%.0f", totalInvested))", icon: "arrow.down.circle", trend: nil)
                        StatCard(title: "Net Profit", value: "\(currencySymbol)\(String(format: "%.0f", netProfit))", icon: "banknote", trend: nil)
                        StatCard(title: "Best Win", value: "\(currencySymbol)\(String(format: "%.0f", bestWin))", icon: "trophy", trend: nil)
                    }
                    .padding(.horizontal)
                    
                    // Profit Trend Chart
                    if !player.sessions.isEmpty {
                        VStack(alignment: .leading) {
                            Text("Performance Trend")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .padding(.horizontal)
                            
                            let sortedSessions = Array(player.sessions.suffix(10))
                            
                            Chart {
                                ForEach(Array(sortedSessions.enumerated()), id: \.element.id) { index, session in
                                    BarMark(
                                        x: .value("Game", "G\(index + 1)"),
                                        y: .value("Profit", session.profitLoss)
                                    )
                                    .foregroundStyle(session.profitLoss >= 0 ? AppTheme.profit : AppTheme.loss)
                                }
                            }
                            .frame(height: 150)
                            .padding()
                            .background(AppTheme.cardBackground)
                            .cornerRadius(16)
                            .padding(.horizontal)
                        }
                    }

                    // Recent Games
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Recent History")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal)
                        
                        ForEach(player.sessions.prefix(10).sorted(by: { $0.joinedAt > $1.joinedAt })) { session in
                            GlowCard {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack(spacing: 6) {
                                            Image(systemName: session.profitLoss >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                                .font(.caption)
                                                .foregroundStyle(session.profitLoss >= 0 ? AppTheme.profit : AppTheme.loss)
                                            Text(session.profitLoss >= 0 ? "Won" : "Lost")
                                                .foregroundStyle(session.profitLoss >= 0 ? AppTheme.profit : AppTheme.loss)
                                                .fontWeight(.bold)
                                        }
                                        Text(session.joinedAt.formatted(date: .abbreviated, time: .omitted))
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.textSecondary)
                                        Text("Buy-in: \(currencySymbol)\(String(format: "%.0f", session.totalBuyIn))")
                                            .font(.caption2)
                                            .foregroundStyle(AppTheme.textSecondary.opacity(0.7))
                                    }
                                    Spacer()
                                    Text("\(session.profitLoss >= 0 ? "+" : "")\(currencySymbol)\(String(format: "%.0f", session.profitLoss))")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundStyle(session.profitLoss >= 0 ? AppTheme.profit : AppTheme.loss)
                                }
                                .padding()
                            }
                        }
                    }
                }
                .padding(.bottom, 100)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
