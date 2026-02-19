import SwiftUI

struct WelcomeView: View {
    @State private var isActive = false
    
    // Staggered animation states
    @State private var showLogo = false
    @State private var showHeadline = false
    @State private var showSubtitle = false
    @State private var showCard = false
    @State private var showGlow = false
    @State private var pulseGlow = false
    
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
            
            // Subtle radial glow behind the card area
            Circle()
                .fill(
                    RadialGradient(
                        colors: [AppTheme.accent.opacity(0.12), Color.clear],
                        center: .center,
                        startRadius: 20,
                        endRadius: 250
                    )
                )
                .frame(width: 500, height: 500)
                .offset(y: 40)
                .scaleEffect(pulseGlow ? 1.05 : 0.95)
                .opacity(showGlow ? 1 : 0)
                .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: pulseGlow)
            
            VStack(spacing: 0) {
                Spacer()
                
                // MARK: - Logo
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 72, height: 72)
                    .opacity(showLogo ? 1 : 0)
                    .scaleEffect(showLogo ? 1 : 0.6)
                    .padding(.bottom, 20)
                
                // MARK: - Bold Headline
                VStack(spacing: 6) {
                    Text("Poker Night,")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    
                    Text("Upgraded.")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(AppTheme.accent)
                }
                .opacity(showHeadline ? 1 : 0)
                .offset(y: showHeadline ? 0 : 20)
                .padding(.bottom, 14)
                
                // MARK: - Subtitle
                Text("Track buy-ins, settle up instantly,\nand manage your poker group like a pro.")
                    .font(.body)
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .opacity(showSubtitle ? 1 : 0)
                    .offset(y: showSubtitle ? 0 : 12)
                    .padding(.bottom, 32)
                
                // MARK: - Floating Preview Card
                floatingPreviewCard
                    .opacity(showCard ? 1 : 0)
                    .offset(y: showCard ? 0 : 40)
                    .scaleEffect(showCard ? 1 : 0.92)
                
                Spacer()
                Spacer()
                
                // MARK: - Get Started Button
                VStack(spacing: 14) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            isActive = true
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text("Get Started")
                            Image(systemName: "arrow.right")
                        }
                        .font(.headline)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppTheme.accent)
                        .clipShape(Capsule())
                    }
                    .padding(.horizontal, 20)
                    
                    Text("Nano Banana Pro")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary.opacity(0.5))
                }
                .opacity(showCard ? 1 : 0)
                .offset(y: showCard ? 0 : 15)
                .padding(.bottom, 36)
            }
            .padding(.horizontal, 28)
        }
    }
    
    // MARK: - Preview Card
    
    private var floatingPreviewCard: some View {
        VStack(spacing: 0) {
            // Card header
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(AppTheme.accent)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Text("D")
                                .font(.caption2.bold())
                                .foregroundStyle(.black)
                        )
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Friday Night Poker")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                        Text("4 players")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
                
                Spacer()
                
                // "Live" badge
                HStack(spacing: 4) {
                    Circle()
                        .fill(.green)
                        .frame(width: 6, height: 6)
                    Text("LIVE")
                        .font(.caption2.bold())
                        .foregroundStyle(.green)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.green.opacity(0.12))
                .clipShape(Capsule())
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            Divider()
                .background(Color.white.opacity(0.06))
            
            // Card body — pot display
            VStack(spacing: 6) {
                Text("Total Pot")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textSecondary)
                
                Text("$1,240")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .padding(.vertical, 16)
            
            Divider()
                .background(Color.white.opacity(0.06))
            
            // Card footer — mini player row
            HStack(spacing: -8) {
                ForEach(["A", "M", "R", "J"], id: \.self) { initial in
                    Circle()
                        .fill(AppTheme.accent.opacity(0.2))
                        .frame(width: 28, height: 28)
                        .overlay(
                            Text(initial)
                                .font(.caption2.bold())
                                .foregroundStyle(AppTheme.accent)
                        )
                        .overlay(
                            Circle()
                                .stroke(AppTheme.cardBackground, lineWidth: 2)
                        )
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.accent)
                        .font(.caption2)
                    Text("Balanced")
                        .font(.caption2.bold())
                        .foregroundStyle(AppTheme.accent)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(AppTheme.accent.opacity(0.12), lineWidth: 1)
                )
        )
        .shadow(color: AppTheme.accent.opacity(0.08), radius: 20, y: 10)
        .shadow(color: Color.black.opacity(0.4), radius: 15, y: 8)
    }
    
    // MARK: - Animation Sequence
    
    private func startAnimationSequence() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showLogo = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showHeadline = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeOut(duration: 0.5)) {
                showSubtitle = true
                showGlow = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.75)) {
                showCard = true
            }
            // Start the pulsing glow loop
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                pulseGlow = true
            }
        }
        

    }
}

#Preview {
    WelcomeView()
}
