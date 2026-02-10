
import SwiftUI
import SwiftData
import Charts

struct GameSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel: GameViewModel
    @State private var showAddBuyIn = false
    @State private var showEndGame = false
    private var isEmbedded: Bool
    
    init(session: GameSession, modelContext: ModelContext, isEmbedded: Bool = false) {
        _viewModel = StateObject(wrappedValue: GameViewModel(modelContext: modelContext, session: session))
        self.isEmbedded = isEmbedded
    }
    
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header / Navbar
                HStack {
                    if !isEmbedded {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .foregroundStyle(.white)
                                .padding()
                                .background(Color.black.opacity(0.3))
                                .clipShape(Circle())
                        }
                    } else {
                        // Spacer to balance the header if back button is hidden
                        // Or just empty view if we want to left align title?
                        // Let's use invisible button to keep title centered if that was the intent,
                        // or just nothing. The original code had Spacer(), Title, Spacer().
                        // So removing the button creates an imbalance if we don't adjust Spacers.
                        // Actually original was: Button, Spacer, Text, Spacer, Button.
                        // If we remove first Button, we have: Spacer, Text, Spacer, Button.
                        // This shifts title to left.
                        // Let's add a dummy invisible view of same size or just Spacer.
                         Color.clear.frame(width: 44, height: 44)
                    }
                    
                    Spacer()
                    
                    Text("Game Session")
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Menu {
                        if viewModel.activeSession.status == .completed {
                            Button {
                                withAnimation {
                                    viewModel.activeSession.status = .active
                                    viewModel.activeSession.endedAt = nil
                                }
                            } label: {
                                Label("Re-open Game", systemImage: "arrow.uturn.backward")
                            }
                        }
                        // Add other menu items here if needed
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundStyle(.white)
                            .padding()
                    }
                }
                .padding()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Pot Display
                        VStack(spacing: 8) {
                            Text(viewModel.activeSession.status == .active ? "Current Pot" : "Total Pot")
                                .foregroundStyle(AppTheme.textSecondary)
                                .font(.subheadline)
                            
                            Text("₪\(viewModel.activeSession.totalPot, specifier: "%.0f")")
                                .font(.system(size: 56, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.accent)
                                .shadow(color: AppTheme.accent.opacity(0.3), radius: 20)
                        }
                        .padding(.vertical, 20)
                        
                        // Action Buttons - Only for active games
                        if viewModel.activeSession.status == .active {
                            HStack(spacing: 16) {
                                AccentButton(title: "Buy In", icon: "plus.circle.fill") {
                                    showAddBuyIn = true
                                }
                                
                                Button {
                                    showEndGame = true
                                } label: {
                                    HStack {
                                        Image(systemName: "flag.checkered")
                                        Text("End Game")
                                    }
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 24)
                                    .background(Color.red.opacity(0.8))
                                    .cornerRadius(30)
                                }
                            }
                        } else {
                            // Completed Game Indicator
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Game Completed")
                            }
                            .font(.headline)
                            .foregroundStyle(AppTheme.accent)
                            .padding()
                            .background(AppTheme.accent.opacity(0.1))
                            .clipShape(Capsule())
                        }
                        
                        // Buy-In Timeline Chart (stock chart style)
                        if viewModel.activeSession.status == .active {
                            let allBuyIns = viewModel.activeSession.playerSessions
                                .flatMap { $0.buyIns }
                                .sorted { $0.timestamp < $1.timestamp }
                            
                            if allBuyIns.count > 1 {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Pot Timeline")
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                        .padding(.horizontal)
                                    
                                    let cumulativeData = buildCumulativeData(from: allBuyIns)
                                    
                                    Chart {
                                        ForEach(Array(cumulativeData.enumerated()), id: \.offset) { _, point in
                                            LineMark(
                                                x: .value("Time", point.time),
                                                y: .value("Pot", point.total)
                                            )
                                            .foregroundStyle(AppTheme.accent)
                                            .lineStyle(StrokeStyle(lineWidth: 2.5))
                                            .interpolationMethod(.catmullRom)
                                            
                                            AreaMark(
                                                x: .value("Time", point.time),
                                                y: .value("Pot", point.total)
                                            )
                                            .foregroundStyle(
                                                .linearGradient(
                                                    colors: [AppTheme.accent.opacity(0.3), AppTheme.accent.opacity(0.0)],
                                                    startPoint: .top,
                                                    endPoint: .bottom
                                                )
                                            )
                                            .interpolationMethod(.catmullRom)
                                            
                                            PointMark(
                                                x: .value("Time", point.time),
                                                y: .value("Pot", point.total)
                                            )
                                            .foregroundStyle(AppTheme.accent)
                                            .symbolSize(30)
                                        }
                                    }
                                    .frame(height: 180)
                                    .chartYAxis {
                                        AxisMarks(position: .leading) { value in
                                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                                                .foregroundStyle(Color.white.opacity(0.15))
                                            AxisValueLabel() {
                                                if let val = value.as(Double.self) {
                                                    Text("₪\(String(format: "%.0f", val))")
                                                        .font(.caption2)
                                                        .foregroundStyle(AppTheme.textSecondary)
                                                }
                                            }
                                        }
                                    }
                                    .chartXAxis {
                                        AxisMarks { value in
                                            AxisValueLabel(format: .dateTime.hour().minute())
                                                .foregroundStyle(AppTheme.textSecondary)
                                        }
                                    }
                                    .padding()
                                    .background(AppTheme.cardBackground.opacity(0.5))
                                    .cornerRadius(16)
                                    .padding(.horizontal)
                                }
                            }
                        }
                        
                        // Players List
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Players (\(viewModel.activeSession.playerSessions.count))")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .padding(.horizontal)
                            
                            ForEach(viewModel.activeSession.playerSessions) { session in
                                if viewModel.activeSession.status == .active {
                                    PlayerRow(
                                        name: session.player?.name ?? "Unknown",
                                        detail: "\(session.buyIns.count) buy-ins",
                                        amount: "₪\(String(format: "%.0f", session.totalBuyIn))",
                                        isPositive: true
                                    )
                                } else {
                                    PlayerRow(
                                        name: session.player?.name ?? "Unknown",
                                        detail: session.profitLoss >= 0 ? "Won" : "Lost",
                                        amount: "₪\(String(format: "%.0f", abs(session.profitLoss)))",
                                        isPositive: session.profitLoss >= 0
                                    )
                                }
                            }
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .sheet(isPresented: $showAddBuyIn) {
            AddBuyInSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showEndGame) {
            EndGameSheet(viewModel: viewModel) {
                // This callback is triggered after EndGameSheet dismisses
                viewModel.showSettlementView = true
            }
        }
        .sheet(isPresented: $viewModel.showSettlementView) {
            SettlementView(viewModel: viewModel)
        }
        .onAppear {
            viewModel.fetchPlayers()
        }
    }
    
    // MARK: - Chart Helpers
    struct PotDataPoint {
        let time: Date
        let total: Double
    }
    
    private func buildCumulativeData(from buyIns: [BuyIn]) -> [PotDataPoint] {
        var cumulative: Double = 0
        return buyIns.map { buyIn in
            cumulative += buyIn.amount
            return PotDataPoint(time: buyIn.timestamp, total: cumulative)
        }
    }
}
