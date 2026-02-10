
import SwiftUI

struct GlowCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .background(AppTheme.cardBackground)
            .cornerRadius(16)
            .shadow(color: AppTheme.accent.opacity(0.15), radius: 15, x: 0, y: 5)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppTheme.accent.opacity(0.1), lineWidth: 1)
            )
    }
}

#Preview {
    ZStack {
        AppTheme.background.ignoresSafeArea()
        GlowCard {
            Text("Sample Card")
                .foregroundStyle(.white)
                .padding()
        }
        .padding()
    }
}
