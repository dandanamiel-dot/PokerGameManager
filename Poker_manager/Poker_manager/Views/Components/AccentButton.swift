
import SwiftUI

struct AccentButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    
    init(title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
                    .fontWeight(.bold)
            }
            .foregroundStyle(Color.black)
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background(AppTheme.primaryGradient)
            .cornerRadius(30)
            .shadow(color: AppTheme.accent.opacity(0.4), radius: 10, x: 0, y: 0)
        }
    }
}

#Preview {
    ZStack {
        AppTheme.background.ignoresSafeArea()
        AccentButton(title: "Add Player", icon: "plus") {}
    }
}
