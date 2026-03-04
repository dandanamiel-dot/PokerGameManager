
import SwiftUI
import SwiftData

struct MainTabView: View {
    let group: PokerGroup?
    var onExit: (() -> Void)?
    
    @Environment(\.modelContext) private var modelContext
    private let firebaseService = FirebaseService.shared
    @State private var selectedTab = 0
    @State private var lastSyncedGroupId: String?
    
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
                
                PlayersView(groupId: groupId, currencySymbol: currencySymbol)
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea(edges: .bottom)
            
            // Custom Tab Bar
            FloatingTabBar(selectedTab: $selectedTab)
                .padding(.bottom, 20)
        }
        .onAppear {
            syncGroupMembersToPlayers()
        }
        .onReceive(firebaseService.$activeGroup) { newGroup in
            // Only sync when the group ID actually changes to avoid spurious SwiftData mutations
            let newGroupId = newGroup?.groupId
            guard newGroupId != lastSyncedGroupId else { return }
            lastSyncedGroupId = newGroupId
            syncGroupMembersToPlayers()
        }
    }
    
    /// Creates local SwiftData Player records for each group member
    /// that doesn't already have a corresponding Player entry.
    private func syncGroupMembersToPlayers() {
        // Use the live activeGroup (which updates via Firebase listener) or fall back to initial group
        guard let activeGroup = firebaseService.activeGroup ?? group else { return }
        let gId = activeGroup.groupId
        guard gId != "local" else { return }
        
        do {
            let descriptor = FetchDescriptor<Player>(
                predicate: #Predicate { $0.groupId == gId }
            )
            let existingPlayers = try modelContext.fetch(descriptor)
            let existingNames = Set(existingPlayers.map { $0.name.lowercased() })
            
            var addedAny = false
            for (_, memberName) in activeGroup.memberNames {
                if !existingNames.contains(memberName.lowercased()) {
                    let player = Player(name: memberName, groupId: gId)
                    modelContext.insert(player)
                    addedAny = true
                }
            }
            
            if addedAny {
                try modelContext.save()
            }
        } catch {
            print("Failed to sync group members to players: \(error)")
        }
    }
}

#Preview {
    MainTabView(group: nil)
}
