
import SwiftUI

struct MainTabView: View {
    let group: PokerGroup?
    var onExit: (() -> Void)?
    
    @State private var selectedTab = 0
    
    /// Currency symbol: from group if available, otherwise default ₪
    var currencySymbol: String {
        group?.currencySymbol ?? "₪"
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            AppTheme.background
                .ignoresSafeArea()
            
            // Main Content
            TabView(selection: $selectedTab) {
                HomeView(group: group, currencySymbol: currencySymbol, onExit: onExit)
                    .tag(0)
                
                LiveGameTabView()
                    .tag(1)
                
                HistoryView(currencySymbol: currencySymbol)
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
    MainTabView(group: nil)
}
