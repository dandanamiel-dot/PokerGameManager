import SwiftUI

struct WelcomeView: View {
    @State private var isActive = false
    @State private var size = 0.8
    @State private var opacity = 0.0
    
    var body: some View {
        if isActive {
            LandingView()
        } else {
            splashContent
                .onAppear {
                    startAnimationSequence()
                }
        }
    }
    
    // MARK: - Splash Content
    
    private var splashContent: some View {
        ZStack {
            // Background
            AppTheme.background.ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Spade Only (No Background Box)
                Image(systemName: "suit.spade.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundStyle(AppTheme.accent)
                    .shadow(color: AppTheme.accent.opacity(0.3), radius: 20, x: 0, y: 10)
                
                // Minimal Text
                VStack(spacing: 8) {
                    Text("All-In Poker Manager")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .tracking(1.2) // slight letter spacing
                    
                    Text("Your Home Games Just Got Better!")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            .scaleEffect(size)
            .opacity(opacity)
        }
    }
    
    // MARK: - Animation Sequence
    
    private func startAnimationSequence() {
        withAnimation(.easeOut(duration: 0.8)) {
            self.size = 1.0
            self.opacity = 1.0
        }
        
        // Hold the splash screen and then transition automatically
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeInOut(duration: 0.4)) {
                self.isActive = true
            }
        }
    }
}

#Preview {
    WelcomeView()
}
