
import SwiftUI
import Charts

struct PlayerGameDetailSheet: View {
    let playerSession: PlayerSession
    let currencySymbol: String
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Computed props
    private var playerName: String {
        playerSession.player?.name ?? "Unknown"
    }
    
    private var sortedBuyIns: [BuyIn] {
        playerSession.buyIns.sorted { $0.timestamp < $1.timestamp }
    }
    
    /// Cumulative buy-in data points for the sparkline
    private var cumulativeData: [(index: Int, total: Double, buyIn: BuyIn)] {
        var running = 0.0
        return sortedBuyIns.enumerated().map { (i, b) in
            running += b.amount
            return (index: i + 1, total: running, buyIn: b)
        }
    }
    
    private var isActive: Bool { !playerSession.hasCashedOut }
    
    private var netResult: Double { playerSession.profitLoss }

    // MARK: - Body
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: Handle bar
                Capsule()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 40, height: 4)
                    .padding(.top, 12)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // MARK: - Header card
                        headerCard
                        
                        // MARK: - Stats row
                        statsRow
                        
                        // MARK: - Buy-in timeline chart (only if > 1 buy-in)
                        if sortedBuyIns.count > 1 {
                            buyInSparkline
                        }
                        
                        // MARK: - Buy-in activity list
                        activityList
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(24)
        .presentationBackground(AppTheme.background)
    }
    
    // MARK: - Header Card
    @ViewBuilder
    private var headerCard: some View {
        VStack(spacing: 12) {
            // Avatar circle
            ZStack {
                Circle()
                    .fill(AppTheme.accent.opacity(0.15))
                    .frame(width: 72, height: 72)
                Text(String(playerName.prefix(1)).uppercased())
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.accent)
            }
            
            Text(playerName)
                .font(.title2.bold())
                .foregroundStyle(.white)
            
            // Status badge
            HStack(spacing: 6) {
                Circle()
                    .fill(isActive ? AppTheme.accent : AppTheme.textSecondary)
                    .frame(width: 8, height: 8)
                Text(isActive ? "Still Playing" : "Cashed Out")
                    .font(.caption.bold())
                    .foregroundStyle(isActive ? AppTheme.accent : AppTheme.textSecondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background((isActive ? AppTheme.accent : AppTheme.textSecondary).opacity(0.12))
            .clipShape(Capsule())
            
            // Joined time
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.caption2)
                Text("Joined \(playerSession.joinedAt.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
            }
            .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(AppTheme.cardBackground)
        .cornerRadius(20)
        .padding(.top, 12)
    }
    
    // MARK: - Stats Row
    @ViewBuilder
    private var statsRow: some View {
        HStack(spacing: 12) {
            statCell(
                icon: "plus.circle.fill",
                iconColor: AppTheme.accent,
                label: "Total Buy-In",
                value: "\(currencySymbol)\(String(format: "%.0f", playerSession.totalBuyIn))"
            )
            
            if playerSession.hasCashedOut {
                statCell(
                    icon: "arrow.right.circle.fill",
                    iconColor: AppTheme.textSecondary,
                    label: "Cashed Out",
                    value: "\(currencySymbol)\(String(format: "%.0f", playerSession.cashOut ?? 0))"
                )
                
                statCell(
                    icon: netResult >= 0 ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill",
                    iconColor: netResult >= 0 ? AppTheme.profit : AppTheme.loss,
                    label: "Net Result",
                    value: "\(netResult >= 0 ? "+" : "")\(currencySymbol)\(String(format: "%.0f", netResult))",
                    valueColor: netResult >= 0 ? AppTheme.profit : AppTheme.loss
                )
            } else {
                statCell(
                    icon: "number.circle.fill",
                    iconColor: AppTheme.textSecondary,
                    label: "Buy-ins",
                    value: "\(playerSession.buyIns.count)"
                )
            }
        }
    }
    
    @ViewBuilder
    private func statCell(icon: String, iconColor: Color, label: String, value: String, valueColor: Color = .white) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(iconColor)
            Text(value)
                .font(.headline.bold())
                .foregroundStyle(valueColor)
            Text(label)
                .font(.caption2)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(AppTheme.cardBackground)
        .cornerRadius(16)
    }
    
    // MARK: - Buy-in sparkline chart
    @ViewBuilder
    private var buyInSparkline: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Buy-In Progression")
                .font(.subheadline.bold())
                .foregroundStyle(.white)
            
            Chart(cumulativeData, id: \.index) { point in
                AreaMark(
                    x: .value("Buy-in #", point.index),
                    y: .value("Total", point.total)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppTheme.accent.opacity(0.4), AppTheme.accent.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                LineMark(
                    x: .value("Buy-in #", point.index),
                    y: .value("Total", point.total)
                )
                .foregroundStyle(AppTheme.accent)
                .lineStyle(StrokeStyle(lineWidth: 2))
                
                PointMark(
                    x: .value("Buy-in #", point.index),
                    y: .value("Total", point.total)
                )
                .foregroundStyle(AppTheme.accent)
                .symbolSize(40)
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(Color.white.opacity(0.1))
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text("\(currencySymbol)\(Int(v))")
                                .font(.caption2)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    if let i = value.as(Int.self) {
                        AxisValueLabel {
                            Text("#\(i)")
                                .font(.caption2)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                }
            }
            .frame(height: 130)
        }
        .padding(16)
        .background(AppTheme.cardBackground)
        .cornerRadius(20)
    }
    
    // MARK: - Activity list
    @ViewBuilder
    private var activityList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity Timeline")
                .font(.subheadline.bold())
                .foregroundStyle(.white)
            
            VStack(spacing: 0) {
                // Joined event
                activityRow(
                    icon: "person.fill.badge.plus",
                    iconColor: AppTheme.textSecondary,
                    title: "Joined the game",
                    time: playerSession.joinedAt,
                    amount: nil,
                    isLast: sortedBuyIns.isEmpty && !playerSession.hasCashedOut
                )
                
                // Buy-in events
                ForEach(Array(sortedBuyIns.enumerated()), id: \.element.id) { index, buyIn in
                    activityRow(
                        icon: "plus.circle.fill",
                        iconColor: AppTheme.accent,
                        title: "Buy-in #\(index + 1)",
                        time: buyIn.timestamp,
                        amount: buyIn.amount,
                        isLast: index == sortedBuyIns.count - 1 && !playerSession.hasCashedOut
                    )
                }
                
                // Cash out event
                if playerSession.hasCashedOut, let cashOutTime = playerSession.cashOutTime {
                    activityRow(
                        icon: "arrow.right.circle.fill",
                        iconColor: AppTheme.textSecondary,
                        title: "Cashed out",
                        time: cashOutTime,
                        amount: playerSession.cashOut,
                        isLast: true
                    )
                }
            }
        }
        .padding(16)
        .background(AppTheme.cardBackground)
        .cornerRadius(20)
    }
    
    @ViewBuilder
    private func activityRow(icon: String, iconColor: Color, title: String, time: Date, amount: Double?, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Timeline line + dot
            VStack(spacing: 0) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(iconColor)
                    .frame(width: 28, height: 28)
                
                if !isLast {
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 1.5)
                        .frame(maxHeight: .infinity)
                        .padding(.vertical, 2)
                }
            }
            .frame(width: 28)
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(title)
                        .font(.subheadline)
                        .foregroundStyle(.white)
                    Spacer()
                    if let amt = amount {
                        Text("\(currencySymbol)\(String(format: "%.0f", amt))")
                            .font(.subheadline.bold())
                            .foregroundStyle(iconColor)
                    }
                }
                Text(time.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .padding(.bottom, isLast ? 4 : 16)
        }
    }
}
