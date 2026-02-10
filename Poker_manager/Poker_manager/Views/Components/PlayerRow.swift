
import SwiftUI

struct PlayerRow: View {
    let name: String
    let detail: String
    let amount: String?
    let isPositive: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppTheme.cardBackground)
                    .stroke(AppTheme.accent.opacity(0.3), lineWidth: 1)
                    .frame(width: 44, height: 44)
                
                Text(name.prefix(1))
                    .foregroundStyle(AppTheme.textPrimary)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .foregroundStyle(AppTheme.textPrimary)
                    .font(.headline)
                
                Text(detail)
                    .foregroundStyle(AppTheme.textSecondary)
                    .font(.caption)
            }
            
            Spacer()
            
            if let amount = amount {
                Text(amount)
                    .foregroundStyle(isPositive ? AppTheme.profit : AppTheme.loss)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
            }
        }
        .padding()
        .background(AppTheme.cardBackground.opacity(0.5))
        .cornerRadius(12)
    }
}

#Preview {
    ZStack {
        AppTheme.background.ignoresSafeArea()
        VStack {
            PlayerRow(name: "Dan Rus", detail: "Buy-in: ₪500", amount: "+₪200", isPositive: true)
            PlayerRow(name: "Michal", detail: "Buy-in: ₪300", amount: "-₪50", isPositive: false)
        }
        .padding()
    }
}
