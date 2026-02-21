
import SwiftUI
import SwiftData
import Charts

struct GameSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel: GameViewModel
    @State private var showAddBuyIn = false
    @State private var showCashOut = false
    @State private var showEndGame = false
    @State private var showShareRoom = false
    @State private var isCreatingRoom = false
    @State private var selectedDate: Date? // For interactive chart
    @ObservedObject private var firebaseService = FirebaseService.shared
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
                        if viewModel.activeSession.status == .active {
                            if firebaseService.roomCode != nil && firebaseService.isHost {
                                Button {
                                    showShareRoom = true
                                } label: {
                                    Label("Show Room Code", systemImage: "antenna.radiowaves.left.and.right")
                                }
                            } else {
                                Button {
                                    isCreatingRoom = true
                                    firebaseService.createRoom(from: viewModel.activeSession) { result in
                                        isCreatingRoom = false
                                        switch result {
                                        case .success:
                                            showShareRoom = true
                                        case .failure(let error):
                                            print("Failed to create room: \(error)")
                                        }
                                    }
                                } label: {
                                    Label(isCreatingRoom ? "Creating..." : "Share Game Live", systemImage: "square.and.arrow.up")
                                }
                                .disabled(isCreatingRoom)
                            }
                        }
                        
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
                    } label: {
                        HStack(spacing: 6) {
                            if firebaseService.roomCode != nil && firebaseService.isHost {
                                Image(systemName: "antenna.radiowaves.left.and.right")
                                    .foregroundStyle(AppTheme.accent)
                                    .font(.caption)
                            }
                            Image(systemName: "ellipsis")
                                .foregroundStyle(.white)
                        }
                        .padding()
                    }
                }
                .padding(.horizontal)
                .padding(.top, 44)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Pot Display
                        VStack(spacing: 8) {
                            Text(viewModel.activeSession.status == .active ? "Current Pot" : "Total Pot")
                                .foregroundStyle(AppTheme.textSecondary)
                                .font(.subheadline)
                            
                            Text("₪\(viewModel.activeSession.status == .active ? viewModel.activeSession.remainingPot : viewModel.activeSession.totalPot, specifier: "%.0f")")
                                .font(.system(size: 56, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.accent)
                                .shadow(color: AppTheme.accent.opacity(0.3), radius: 20)
                            
                            // Show total buy-ins vs remaining if there are cash-outs
                            if viewModel.activeSession.status == .active && viewModel.activeSession.remainingPot != viewModel.activeSession.totalPot {
                                Text("Total buy-ins: ₪\(viewModel.activeSession.totalPot, specifier: "%.0f")")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                        }
                        .padding(.vertical, 20)
                        
                        // Action Buttons - Only for active games
                        if viewModel.activeSession.status == .active {
                            HStack(spacing: 12) {
                                // Buy In — primary accent button
                                AccentButton(title: "Buy In", icon: "plus.circle.fill") {
                                    showAddBuyIn = true
                                }
                                
                                // Cash Out — outlined dark button
                                Button {
                                    showCashOut = true
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "banknote")
                                        Text("Cash Out")
                                    }
                                    .fontWeight(.bold)
                                    .foregroundStyle(AppTheme.accent)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 20)
                                    .background(AppTheme.cardBackground)
                                    .cornerRadius(30)
                                    .overlay(
                                        Capsule()
                                            .stroke(AppTheme.accent.opacity(0.4), lineWidth: 1.5)
                                    )
                                }
                                
                                // End Game — outlined dark button
                                Button {
                                    showEndGame = true
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "flag.checkered")
                                        Text("End")
                                    }
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white.opacity(0.7))
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 20)
                                    .background(AppTheme.cardBackground)
                                    .cornerRadius(30)
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                    )
                                }
                            }
                        } else {
                            // Completed Game Indicator + View Settlement
                            HStack(spacing: 12) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Game Completed")
                                }
                                .font(.headline)
                                .foregroundStyle(AppTheme.accent)
                                .padding()
                                .background(AppTheme.accent.opacity(0.1))
                                .clipShape(Capsule())
                                
                                Button {
                                    viewModel.showSettlementView = true
                                } label: {
                                    HStack {
                                        Image(systemName: "doc.text.magnifyingglass")
                                        Text("Settlement")
                                    }
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .padding()
                                    .background(AppTheme.cardBackground)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule().stroke(AppTheme.accent.opacity(0.3), lineWidth: 1)
                                    )
                                }
                            }
                        }
                        
                        // Buy-In Timeline Chart (stock chart style)
                        if viewModel.activeSession.status == .active {
                            let cumulativeData = buildCumulativeData(from: viewModel.activeSession)
                            
                            if cumulativeData.count > 1 {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Pot Timeline")
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                        .padding(.horizontal)
                                    
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
                                        
                                        if let selectedDate {
                                            if let nearestPoint = cumulativeData.min(by: { abs($0.time.timeIntervalSince(selectedDate)) < abs($1.time.timeIntervalSince(selectedDate)) }) {
                                                RuleMark(x: .value("Selected", nearestPoint.time))
                                                    .foregroundStyle(Color.gray.opacity(0.5))
                                                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                                                    .annotation(position: .top, spacing: 0) {
                                                        VStack(alignment: .leading, spacing: 4) {
                                                            Text(nearestPoint.playerName)
                                                                .font(.caption2.bold())
                                                                .foregroundStyle(.white)
                                                            
                                                            HStack(spacing: 4) {
                                                                Text(nearestPoint.isCashOut ? "Cashed out:" : "Bought in:")
                                                                    .foregroundStyle(AppTheme.textSecondary)
                                                                Text("\(nearestPoint.isCashOut ? "-" : "+")₪\(nearestPoint.eventAmount, specifier: "%.0f")")
                                                                    .bold()
                                                                    .foregroundStyle(nearestPoint.isCashOut ? .orange : AppTheme.accent)
                                                            }
                                                            .font(.caption)
                                                            
                                                            Text(nearestPoint.time.formatted(date: .omitted, time: .shortened))
                                                                .font(.system(size: 10))
                                                                .foregroundStyle(.gray)
                                                        }
                                                        .padding(10)
                                                        .background(AppTheme.cardBackground)
                                                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.accent.opacity(0.5), lineWidth: 1))
                                                        .cornerRadius(8)
                                                        .shadow(color: .black.opacity(0.5), radius: 6)
                                                        .padding(.bottom, 8)
                                                    }
                                            }
                                        }
                                    }
                                    .chartXSelection(value: $selectedDate)
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
                        
                        // Recent Activities Component
                        if !viewModel.activeSession.playerSessions.isEmpty {
                            RecentActivitiesFeed(session: viewModel.activeSession)
                        }
                        
                        // Game Statistics
                        GameStatisticsRow(session: viewModel.activeSession)
                        
                        // Players List
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Players (\(viewModel.activeSession.playerSessions.count))")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .padding(.horizontal)
                            
                            ForEach(viewModel.activeSession.playerSessions) { session in
                                if viewModel.activeSession.status == .active {
                                    HStack {
                                        PlayerRow(
                                            name: session.player?.name ?? "Unknown",
                                            detail: session.hasCashedOut ? "Cashed out" : "\(session.buyIns.count) buy-ins",
                                            amount: session.hasCashedOut ? "₪\(String(format: "%.0f", session.cashOut ?? 0))" : "₪\(String(format: "%.0f", session.totalBuyIn))",
                                            isPositive: !session.hasCashedOut
                                        )
                                        
                                        if session.hasCashedOut {
                                            Text("OUT")
                                                .font(.caption2.bold())
                                                .foregroundStyle(AppTheme.accent)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(AppTheme.accent.opacity(0.12))
                                                .clipShape(Capsule())
                                        }
                                    }
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
                    .padding(.bottom, 100)
                }
            }
        }
        .sheet(isPresented: $showAddBuyIn) {
            AddBuyInSheet(viewModel: viewModel)
                .onDisappear {
                    // Sync to Firebase after buy-in
                    if firebaseService.isHost && firebaseService.roomCode != nil {
                        firebaseService.syncRoom(from: viewModel.activeSession)
                    }
                }
        }
        .sheet(isPresented: $showCashOut) {
            CashOutSheet(viewModel: viewModel)
                .onDisappear {
                    if firebaseService.isHost && firebaseService.roomCode != nil {
                        firebaseService.syncRoom(from: viewModel.activeSession)
                    }
                }
        }
        .sheet(isPresented: $showEndGame) {
            EndGameSheet(viewModel: viewModel) {
                // Sync settlement to Firebase
                if firebaseService.isHost && firebaseService.roomCode != nil {
                    let transactions = viewModel.generateTransactions()
                    firebaseService.syncRoom(from: viewModel.activeSession)
                    firebaseService.syncSettlement(transactions: transactions.map { ($0.from, $0.to, $0.amount) })
                }
                viewModel.showSettlementView = true
            }
        }
        .sheet(isPresented: $viewModel.showSettlementView) {
            SettlementView(viewModel: viewModel)
        }
        .sheet(isPresented: $showShareRoom) {
            if let code = firebaseService.roomCode {
                ShareRoomSheet(roomCode: code)
            }
        }
        .onAppear {
            viewModel.fetchPlayers()
        }
    }
    
    // MARK: - Chart Helpers
    struct PotDataPoint: Identifiable {
        let id = UUID()
        let time: Date
        let total: Double
        let playerName: String
        let eventAmount: Double
        let isCashOut: Bool
    }
    
    private func buildCumulativeData(from session: GameSession) -> [PotDataPoint] {
        var events: [(time: Date, amount: Double, playerName: String, isCashOut: Bool)] = []
        
        for ps in session.playerSessions {
            for buyIn in ps.buyIns {
                events.append((time: buyIn.timestamp, amount: buyIn.amount, playerName: ps.player?.name ?? "Unknown", isCashOut: false))
            }
            if let cashOut = ps.cashOut, let cashOutTime = ps.cashOutTime {
                events.append((time: cashOutTime, amount: -cashOut, playerName: ps.player?.name ?? "Unknown", isCashOut: true))
            }
        }
        
        events.sort { $0.time < $1.time }
        
        var cumulative: Double = 0
        return events.map { event in
            cumulative += event.amount
            return PotDataPoint(
                time: event.time,
                total: cumulative,
                playerName: event.playerName,
                eventAmount: abs(event.amount),
                isCashOut: event.isCashOut
            )
        }
    }
}

// MARK: - Game Statistics & Activity Feed

struct GameStatisticsRow: View {
    let session: GameSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Game Statistics")
                .font(.title3.bold())
                .foregroundStyle(.white)
                .padding(.horizontal)
            
            HStack(spacing: 12) {
                StatCard(title: "Total Chips", value: "₪\(String(format: "%.0f", session.remainingPot))")
                StatCard(title: "Players", value: "\(session.playerSessions.count)")
                
                let cashOutVal = session.playerSessions.reduce(0.0) { $0 + ($1.cashOut ?? 0) }
                StatCard(title: "Cash Outs", value: "₪\(String(format: "%.0f", cashOutVal))")
            }
            .padding(.horizontal)
        }
    }
    
    struct StatCard: View {
        let title: String
        let value: String
        
        var body: some View {
            VStack(spacing: 8) {
                Text(value)
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(AppTheme.cardBackground)
            .cornerRadius(12)
        }
    }
}

enum ActivityEventType {
    case joined
    case buyIn(amount: Double)
    case cashOut(amount: Double)
}

struct ActivityEvent: Identifiable {
    let id = UUID()
    let time: Date
    let playerName: String
    let type: ActivityEventType
}

struct RecentActivitiesFeed: View {
    let session: GameSession
    @State private var showPastEvents = false
    
    private var events: [ActivityEvent] {
        var allEvents: [ActivityEvent] = []
        for ps in session.playerSessions {
            let name = ps.player?.name ?? "Unknown"
            
            // Join event
            allEvents.append(ActivityEvent(time: ps.joinedAt, playerName: name, type: .joined))
            
            // Buy-ins
            for buyIn in ps.buyIns {
                allEvents.append(ActivityEvent(time: buyIn.timestamp, playerName: name, type: .buyIn(amount: buyIn.amount)))
            }
            
            // Cash-outs
            if let cashOut = ps.cashOut, let cashOutTime = ps.cashOutTime {
                allEvents.append(ActivityEvent(time: cashOutTime, playerName: name, type: .cashOut(amount: cashOut)))
            }
        }
        return allEvents.sorted { $0.time > $1.time }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Recent Activities")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                Spacer()
                Button("See Past Events") {
                    showPastEvents = true
                }
                .font(.subheadline.bold())
                .foregroundStyle(Color.blue)
            }
            .padding()
            
            let recentEvents = Array(events.prefix(3))
            
            if recentEvents.isEmpty {
                Text("No activities yet.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding()
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(recentEvents.enumerated()), id: \.offset) { index, event in
                        HStack(alignment: .top, spacing: 16) {
                            Text(event.time.formatted(date: .omitted, time: .shortened))
                                .font(.caption2)
                                .foregroundStyle(AppTheme.textSecondary)
                                .frame(width: 55, alignment: .trailing)
                                .padding(.top, 2) // Match dot alignment
                            
                            // Timeline dot & line
                            VStack(spacing: 0) {
                                Circle()
                                    .fill(AppTheme.accent)
                                    .frame(width: 10, height: 10)
                                    .shadow(color: AppTheme.accent.opacity(0.8), radius: 4)
                                
                                if index < recentEvents.count - 1 {
                                    Rectangle()
                                        .fill(AppTheme.accent.opacity(0.6))
                                        .frame(width: 2)
                                        .padding(.vertical, 2)
                                }
                            }
                            
                            // Event content
                            Text(eventDescription(for: event))
                                .font(.subheadline)
                                .foregroundStyle(.white)
                                .padding(.bottom, index == recentEvents.count - 1 ? 0 : 24)
                            
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .background(AppTheme.cardBackground)
        .cornerRadius(16)
        .padding(.horizontal)
        .sheet(isPresented: $showPastEvents) {
            PastActivitiesSheet(events: events)
        }
    }
    
    private func eventDescription(for event: ActivityEvent) -> AttributedString {
        var str = AttributedString("\(event.playerName) ")
        str.font = .subheadline.bold()
        
        var actionStr: AttributedString
        switch event.type {
        case .joined:
            actionStr = AttributedString("joined the game")
        case .buyIn(let amount):
            actionStr = AttributedString("bought in for ₪\(String(format: "%.0f", amount))")
        case .cashOut(let amount):
            actionStr = AttributedString("cashed out ₪\(String(format: "%.0f", amount))")
        }
        
        return str + actionStr
    }
}
