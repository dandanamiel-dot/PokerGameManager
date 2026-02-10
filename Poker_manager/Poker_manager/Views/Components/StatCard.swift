
import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let icon: String // SF Symbol
    let trend: String? // e.g. "+5%"
    
    var body: some View {
        GlowCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(AppTheme.accent.opacity(0.1))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: icon)
                            .foregroundStyle(AppTheme.accent)
                    }
                    Spacer()
                }
                
                Text(title)
                    .foregroundStyle(AppTheme.textSecondary)
                    .font(.caption)
                
                Text(value)
                    .foregroundStyle(AppTheme.textPrimary)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    
                if let trend = trend {
                    Text(trend)
                        .foregroundStyle(AppTheme.profit)
                        .font(.caption2)
                }
            }
            .padding()
        }
    }
}

#Preview {
    ZStack {
        AppTheme.background.ignoresSafeArea()
        StatCard(title: "Biggest Pot", value: "₪5,350", icon: "banknote", trend: "+12%")
            .frame(width: 160)
    }
}
