import SwiftUI

struct WelcomeView: View {
    @State private var isActive = false
    @State private var opacity = 0.5
    @State private var scale = 0.8
    
    var body: some View {
        if isActive {
            MainTabView()
        } else {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                VStack {
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 250, height: 250)
                        .scaleEffect(scale)
                        .opacity(opacity)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 1.5)) {
                                opacity = 1.0
                                scale = 1.0
                            }
                        }
                    
                    Text("Nano Banana Pro")
                        .font(.headline)
                        .foregroundStyle(AppTheme.accent)
                        .opacity(opacity)
                        .padding(.top, 20)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation {
                        isActive = true
                    }
                }
            }
        }
    }
}

#Preview {
    WelcomeView()
}
