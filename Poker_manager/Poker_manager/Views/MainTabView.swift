
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
                
                LiveGameTabView()
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
