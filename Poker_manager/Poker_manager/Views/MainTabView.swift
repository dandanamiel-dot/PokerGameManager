
import SwiftUI

struct MainTabView: View {
    let group: PokerGroup?
    var onExit: (() -> Void)?
    
    @State private var selectedTab = 0
    
    /// Currency symbol: from group if available, otherwise default ₪
    var currencySymbol: String {
        group?.currencySymbol ?? "₪"
    }
    
    /// Group ID for data scoping: group code or "local" for quick start
    var groupId: String {
        group?.groupId ?? "local"
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            AppTheme.background
                .ignoresSafeArea()
            
            // Main Content
            TabView(selection: $selectedTab) {
                HomeView(group: group, currencySymbol: currencySymbol, groupId: groupId, onExit: onExit)
                    .tag(0)
                
                LiveGameTabView(groupId: groupId)
                    .tag(1)
                
                HistoryView(currencySymbol: currencySymbol, groupId: groupId)
                    .tag(2)
                
                PlayersView(groupId: groupId)
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
