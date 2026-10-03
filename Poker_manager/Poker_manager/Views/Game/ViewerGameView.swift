
import SwiftUI
import SwiftData
import Charts

struct ViewerGameView: View {
    @Environment(\.modelContext) private var modelContext
    private let firebaseService = FirebaseService.shared
    @State private var activeRoom: GameRoom?
    @State private var showSettlement = false
    @State private var isAdmin = false
    @State private var isLive = false
    @State private var viewers: [ViewerPresence] = []
    @State private var showBuyIn = false
    @State private var showCashOut = false
    @State private var showEndGame = false
    @State private var showMembers = false
    @State private var actionError: String?
    @State private var savedToHistory = false
    
    private var currencySymbol: String {
        activeRoom?.currencySymbol ?? firebaseService.activeGroup?.currencySymbol ?? "₪"
    }
    
    /// Co-admins (not the host, who has the full game screen) can run the game from here.
    private func canManage(_ room: GameRoom) -> Bool {
        isAdmin && room.isActive && room.supportsSharedControl
    }
    
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            if let room = activeRoom {
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Button {
                            firebaseService.leaveRoom()
                        } label: {
                            Image(systemName: "chevron.left")
                                .foregroundStyle(.white)
                                .padding()
                                .background(Color.black.opacity(0.3))
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        VStack(spacing: 2) {
                            Text("Live Game")
                                .font(.headline)
                                .foregroundStyle(.white)
                            
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(liveColor(room))
                                    .frame(width: 6, height: 6)
                                Text(liveLabel(room))
                                    .font(.caption2.bold())
                                    .foregroundStyle(liveColor(room))
                                if room.isActive {
                                    Text("·")
                                        .font(.caption2)
                                        .foregroundStyle(.gray)
                                    Image(systemName: "eye.fill")
                                        .font(.caption2)
                                        .foregroundStyle(.gray)
                                    Text("\(activeViewerCount)")
                                        .font(.caption2.bold())
                                        .foregroundStyle(.gray)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        // Room code badge
                        Text(room.roomCode)
                            .font(.caption.bold().monospaced())
                            .foregroundStyle(AppTheme.accent)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(AppTheme.accent.opacity(0.15))
                            .clipShape(Capsule())
                    }
                    .padding()
                    
                    if canManage(room) {
                        adminBar
                    }
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            // Pot Display
                            VStack(spacing: 8) {
                                Text(room.status == "active" ? "Current Pot" : "Final Pot")
                                    .foregroundStyle(AppTheme.textSecondary)
                                    .font(.subheadline)
                                
                                Text("\(currencySymbol)\(room.totalPot, specifier: "%.0f")")
                                    .font(.system(size: 56, weight: .bold, design: .rounded))
                                    .foregroundStyle(AppTheme.accent)
                                    .shadow(color: AppTheme.accent.opacity(0.3), radius: 20)
                            }
                            .padding(.vertical, 20)
                            
                            // Last activity, ticking so it always reads "just now", "2 min ago"...
                            if room.isActive, let last = room.buyInTimeline.last {
                                TimelineView(.periodic(from: .now, by: 30)) { context in
                                    Text("\(feedDescription(last)) · \(relativeTime(last.timestamp, now: context.date))")
                                        .font(.footnote)
                                        .foregroundStyle(AppTheme.textSecondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                }
                            }
                            
                            // Status indicator
                            if room.status == "completed" {
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
                                    
                                    if !room.settlement.isEmpty {
                                        Button {
                                            showSettlement = true
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
                            }
                            
                            // Pot Timeline Chart
                            if room.buyInTimeline.count > 1 {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Pot Timeline")
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                        .padding(.horizontal)
                                    
                                    Chart {
                                        ForEach(Array(room.buyInTimeline.enumerated()), id: \.offset) { _, point in
                                            LineMark(
                                                x: .value("Time", point.timestamp),
                                                y: .value("Pot", point.cumulativeTotal)
                                            )
                                            .foregroundStyle(AppTheme.accent)
                                            .lineStyle(StrokeStyle(lineWidth: 2.5))
                                            .interpolationMethod(.stepEnd)
                                            
                                            AreaMark(
                                                x: .value("Time", point.timestamp),
                                                y: .value("Pot", point.cumulativeTotal)
                                            )
                                            .foregroundStyle(
                                                .linearGradient(
                                                    colors: [AppTheme.accent.opacity(0.3), AppTheme.accent.opacity(0.0)],
                                                    startPoint: .top,
                                                    endPoint: .bottom
                                                )
                                            )
                                            .interpolationMethod(.stepEnd)
                                        }
                                    }
                                    .frame(height: 180)
                                    .chartYAxis {
                                        AxisMarks(position: .leading) { value in
                                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                                                .foregroundStyle(Color.white.opacity(0.15))
                                            AxisValueLabel() {
                                                if let val = value.as(Double.self) {
                                                    Text("\(currencySymbol)\(String(format: "%.0f", val))")
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
                            
                            // Players List
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Players (\(room.players.count))")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal)
                                
                                ForEach(room.players) { player in
                                    if room.status == "active" {
                                        PlayerRow(
                                            name: player.name,
                                            detail: "\(player.buyInCount) buy-ins",
                                            amount: "\(currencySymbol)\(String(format: "%.0f", player.totalBuyIn))",
                                            isPositive: true
                                        )
                                    } else {
                                        PlayerRow(
                                            name: player.name,
                                            detail: player.profitLoss >= 0 ? "Won" : "Lost",
                                            amount: "\(currencySymbol)\(String(format: "%.0f", abs(player.profitLoss)))",
                                            isPositive: player.profitLoss >= 0
                                        )
                                    }
                                }
                            }
                            
                            // Recent Timeline Feed
                            if !room.buyInTimeline.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Live Feed")
                                        .font(.title3.bold())
                                        .foregroundStyle(.white)
                                        .padding(.horizontal)
                                    
                                    ForEach(room.buyInTimeline.suffix(10).reversed()) { event in
                                        HStack {
                                            Image(systemName: event.isCashOut == true ? "arrow.down.right.circle.fill" : "dollarsign.circle.fill")
                                                .foregroundStyle(event.isCashOut == true ? .orange : AppTheme.accent)
                                            
                                            VStack(alignment: .leading) {
                                                HStack {
                                                    Text(event.playerName)
                                                        .foregroundStyle(.white)
                                                        .fontWeight(.medium)
                                                    
                                                    if event.isCashOut == true {
                                                        Text("Cashed Out")
                                                            .font(.caption2)
                                                            .foregroundStyle(.orange)
                                                            .padding(.horizontal, 6)
                                                            .padding(.vertical, 2)
                                                            .background(Color.orange.opacity(0.15))
                                                            .clipShape(Capsule())
                                                    }
                                                }
                                                Text(eventSubtitle(event))
                                                    .font(.caption)
                                                    .foregroundStyle(.gray)
                                            }
                                            
                                            Spacer()
                                            
                                            Text("\(event.isCashOut == true ? "-" : "+")\(currencySymbol)\(String(format: "%.0f", event.amount))")
                                                .foregroundStyle(event.isCashOut == true ? .orange : AppTheme.accent)
                                                .fontWeight(.bold)
                                        }
                                        .padding(.horizontal)
                                        .padding(.vertical, 8)
                                        .background(AppTheme.cardBackground.opacity(0.5))
                                        .cornerRadius(12)
                                        .padding(.horizontal)
                                        .transition(.move(edge: .top).combined(with: .opacity))
                                    }
                                }
                                .animation(.spring(response: 0.4), value: room.buyInTimeline.count)
                            }
                            
                            // Keep a copy of a finished game on this phone
                            if !room.isActive && room.hostId != firebaseService.currentUserId {
                                Button {
                                    saveToHistory(room)
                                } label: {
                                    Label(savedToHistory ? "Saved to History" : "Save to My History",
                                          systemImage: savedToHistory ? "checkmark.circle.fill" : "tray.and.arrow.down")
                                        .font(.headline)
                                        .foregroundStyle(savedToHistory ? .green : AppTheme.accent)
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 24)
                                        .background(Capsule().stroke(AppTheme.accent.opacity(0.4), lineWidth: 1.5))
                                }
                                .disabled(savedToHistory)
                            }
                        }
                        .padding(.bottom, 40)
                    }
                }
            } else {
                // Loading / error state
                VStack(spacing: 16) {
                    ProgressView()
                        .tint(AppTheme.accent)
                    Text("Connecting...")
                        .foregroundStyle(.gray)
                }
            }
        }
        .sheet(isPresented: $showSettlement) {
            if let room = activeRoom {
                ViewerSettlementSheet(settlement: room.settlement, currencySymbol: currencySymbol)
            }
        }
        .sheet(isPresented: $showBuyIn) {
            if let room = activeRoom {
                RoomBuyInSheet(room: room, currencySymbol: currencySymbol)
            }
        }
        .sheet(isPresented: $showCashOut) {
            if let room = activeRoom {
                RoomCashOutSheet(room: room, currencySymbol: currencySymbol)
            }
        }
        .sheet(isPresented: $showEndGame) {
            if let room = activeRoom {
                RoomEndGameSheet(room: room, currencySymbol: currencySymbol)
            }
        }
        .sheet(isPresented: $showMembers) {
            RoomMembersSheet()
        }
        .alert("Live Game", isPresented: .init(
            get: { actionError != nil },
            set: { if !$0 { firebaseService.actionError = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(actionError ?? "")
        }
        .onAppear {
            activeRoom = firebaseService.activeRoom
            isAdmin = firebaseService.isAdmin
            isLive = firebaseService.isLive
            viewers = firebaseService.viewers
            refreshSavedState()
        }
        .onReceive(firebaseService.$activeRoom) { room in
            activeRoom = room
            refreshSavedState()
        }
        .onReceive(firebaseService.$isAdmin) { admin in
            isAdmin = admin
        }
        .onReceive(firebaseService.$isLive) { live in
            isLive = live
        }
        .onReceive(firebaseService.$viewers) { list in
            viewers = list
        }
        .onReceive(firebaseService.$actionError) { message in
            actionError = message
        }
    }
    
    // MARK: - Admin controls
    
    private var adminBar: some View {
        VStack(spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "crown.fill")
                Text("You're an admin of this game")
            }
            .font(.caption.bold())
            .foregroundStyle(AppTheme.accent)
            
            HStack(spacing: 10) {
                adminButton("Buy-in", icon: "plus.circle.fill") { showBuyIn = true }
                adminButton("Cash Out", icon: "arrow.down.right.circle.fill") { showCashOut = true }
                adminButton("End", icon: "flag.checkered") { showEndGame = true }
                adminButton("Admins", icon: "person.2.fill") { showMembers = true }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    private func adminButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(.caption2.bold())
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12).stroke(AppTheme.accent.opacity(0.3), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Live helpers
    
    private var activeViewerCount: Int {
        let now = Date()
        return viewers.filter { $0.isActive(at: now) }.count
    }
    
    private func liveLabel(_ room: GameRoom) -> String {
        if !room.isActive { return "ENDED" }
        return isLive ? "LIVE" : "RECONNECTING"
    }
    
    private func liveColor(_ room: GameRoom) -> Color {
        if !room.isActive { return .gray }
        return isLive ? .green : .orange
    }
    
    private func feedDescription(_ event: BuyInEvent) -> String {
        let amount = "\(currencySymbol)\(String(format: "%.0f", event.amount))"
        return event.isCashOut == true
            ? "\(event.playerName) cashed out \(amount)"
            : "\(event.playerName) bought in \(amount)"
    }
    
    private func eventSubtitle(_ event: BuyInEvent) -> String {
        let time = event.timestamp.formatted(date: .omitted, time: .shortened)
        guard let recorder = event.recordedBy, !recorder.isEmpty else { return time }
        return "\(time) · by \(recorder)"
    }
    
    private func relativeTime(_ date: Date, now: Date) -> String {
        if now.timeIntervalSince(date) < 60 { return "just now" }
        return RelativeDateTimeFormatter().localizedString(for: date, relativeTo: now)
    }
    
    // MARK: - History
    
    private func refreshSavedState() {
        guard let room = activeRoom else { return }
        savedToHistory = RoomHistoryImporter.hasSaved(roomCode: room.roomCode, in: modelContext)
    }
    
    private func saveToHistory(_ room: GameRoom) {
        let groupId = room.groupId ?? firebaseService.activeGroup?.groupId ?? "local"
        do {
            try RoomHistoryImporter.save(room, groupId: groupId, in: modelContext)
            savedToHistory = true
        } catch {
            firebaseService.actionError = "Couldn't save this game: \(error.localizedDescription)"
        }
    }
}

// MARK: - Viewer Settlement Sheet

struct ViewerSettlementSheet: View {
    let settlement: [SettlementEntry]
    let currencySymbol: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("Settlement")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                
                ForEach(settlement) { entry in
                    HStack {
                        Text(entry.from)
                            .foregroundStyle(.red)
                            .fontWeight(.semibold)
                        
                        Image(systemName: "arrow.right")
                            .foregroundStyle(.gray)
                        
                        Text(entry.to)
                            .foregroundStyle(.green)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Text("\(currencySymbol)\(String(format: "%.0f", entry.amount))")
                            .foregroundStyle(.white)
                            .fontWeight(.bold)
                    }
                    .padding()
                    .background(AppTheme.cardBackground)
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(AppTheme.accent)
                        )
                }
                .padding(.horizontal, 24)
            }
            .padding(.top, 24)
        }
    }
}
