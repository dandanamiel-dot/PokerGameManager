
import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            AppTheme.background
                .ignoresSafeArea()
            
            // Main Content
            TabView(selection: $selectedTab) {
                HomeView()
                    .tag(0)
                
                // Placeholder for Game Tab - in reality this might be a modal or separate flow
                // But for the tab bar, we'll just show the active game view if there is one,
                // or a "Start New Game" view
                Text("Game View Placeholder") // Replaced later
                    .tag(1)
                
                HistoryView()
                    .tag(2)
                
                PlayersView()
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()
            
            // Custom Tab Bar
            FloatingTabBar(selectedTab: $selectedTab)
                .padding(.bottom, 20)
        }
    }
}

#Preview {
    MainTabView()
}
