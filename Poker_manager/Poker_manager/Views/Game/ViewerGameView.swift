
import SwiftUI
import Charts

struct ViewerGameView: View {
    @ObservedObject private var firebaseService = FirebaseService.shared
    @State private var showSettlement = false
    
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            if let room = firebaseService.activeRoom {
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
                                    .fill(room.status == "active" ? Color.green : Color.gray)
                                    .frame(width: 6, height: 6)
                                Text(room.status == "active" ? "LIVE" : "ENDED")
                                    .font(.caption2.bold())
                                    .foregroundStyle(room.status == "active" ? .green : .gray)
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
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            // Pot Display
                            VStack(spacing: 8) {
                                Text(room.status == "active" ? "Current Pot" : "Final Pot")
                                    .foregroundStyle(AppTheme.textSecondary)
                                    .font(.subheadline)
                                
                                Text("₪\(room.totalPot, specifier: "%.0f")")
                                    .font(.system(size: 56, weight: .bold, design: .rounded))
                                    .foregroundStyle(AppTheme.accent)
                                    .shadow(color: AppTheme.accent.opacity(0.3), radius: 20)
                            }
                            .padding(.vertical, 20)
                            
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
                                            .interpolationMethod(.catmullRom)
                                            
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
                                            .interpolationMethod(.catmullRom)
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
                                            amount: "₪\(String(format: "%.0f", player.totalBuyIn))",
                                            isPositive: true
                                        )
                                    } else {
                                        PlayerRow(
                                            name: player.name,
                                            detail: player.profitLoss >= 0 ? "Won" : "Lost",
                                            amount: "₪\(String(format: "%.0f", abs(player.profitLoss)))",
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
                                    
                                    ForEach(room.buyInTimeline.suffix(5).reversed()) { event in
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
                                                Text(event.timestamp, style: .time)
                                                    .font(.caption)
                                                    .foregroundStyle(.gray)
                                            }
                                            
                                            Spacer()
                                            
                                            Text("\(event.isCashOut == true ? "-" : "+")₪\(String(format: "%.0f", event.amount))")
                                                .foregroundStyle(event.isCashOut == true ? .orange : AppTheme.accent)
                                                .fontWeight(.bold)
                                        }
                                        .padding(.horizontal)
                                        .padding(.vertical, 8)
                                        .background(AppTheme.cardBackground.opacity(0.5))
                                        .cornerRadius(12)
                                        .padding(.horizontal)
                                    }
                                }
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
            if let room = firebaseService.activeRoom {
                ViewerSettlementSheet(settlement: room.settlement)
            }
        }
    }
}

// MARK: - Viewer Settlement Sheet

struct ViewerSettlementSheet: View {
    let settlement: [SettlementEntry]
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
                        
                        Text("₪\(String(format: "%.0f", entry.amount))")
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
