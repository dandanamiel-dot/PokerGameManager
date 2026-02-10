import SwiftUI

struct WelcomeAnimationDemoView: View {
    @State private var selectedAnimation = 0
    
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Header
                Text("Logo Animations")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.top, 40)
                
                Picker("Animation", selection: $selectedAnimation) {
                    Text("Spinning Chip").tag(0)
                    Text("Creative Pulse").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .onAppear {
                    UISegmentedControl.appearance().selectedSegmentTintColor = UIColor(AppTheme.accent)
                    UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.black], for: .selected)
                    UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
                }
                
                Spacer()
                
                // Animation Area
                ZStack {
                    if selectedAnimation == 0 {
                        SpinningLogoView()
                    } else {
                        CreativeLogoView()
                    }
                }
                .frame(width: 300, height: 300)
                
                Spacer()
                
                // Description
                Text(selectedAnimation == 0 ? "Classic 3D Rotation" : "Neon Pulse & Scale")
                    .foregroundStyle(AppTheme.textSecondary)
                    .font(.headline)
                    .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Option 1: Spinning Chip
struct SpinningLogoView: View {
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            // Static Center Spade
            Image("AppLogoSpade")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
            
            // Spinning Outer Chip
            Image("AppLogoChip")
                .resizable()
                .scaledToFit()
                .frame(width: 240, height: 240) // Slightly larger to frame the spade
                .rotationEffect(.degrees(rotation))
                .onAppear {
                    withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                }
        }
        .frame(width: 240, height: 240)
    }
}

// MARK: - Option 2: Creative Pulse
struct CreativeLogoView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Glow layers
            Circle()
                .fill(AppTheme.accent)
                .frame(width: 200, height: 200)
                .blur(radius: isAnimating ? 60 : 20)
                .opacity(isAnimating ? 0.3 : 0.1)
                .scaleEffect(isAnimating ? 1.2 : 0.8)
            
            Circle()
                .stroke(AppTheme.accent.opacity(0.5), lineWidth: 2)
                .frame(width: 220, height: 220)
                .scaleEffect(isAnimating ? 1.1 : 0.9)
                .opacity(isAnimating ? 0.0 : 0.5)
            
            // Logo
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
                .scaleEffect(isAnimating ? 1.05 : 0.95)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    WelcomeAnimationDemoView()
}
