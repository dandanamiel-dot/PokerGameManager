
import SwiftUI
import SwiftData

struct HomeView: View {
    let group: PokerGroup?
    let currencySymbol: String
    let groupId: String
    var onExit: (() -> Void)?
    var onSeeAllGames: (() -> Void)?
    /// Switches to the Game tab, where the active game already lives
    var onOpenTable: (() -> Void)?
    
    @Environment(\.modelContext) private var modelContext
    @Query private var recentGames: [GameSession]
    private let firebaseService = FirebaseService.shared
    @State private var userGroups: [PokerGroup] = []
    
    @State private var showNewGameSheet = false
    @State private var selectedGame: GameSession?
    @State private var gameToEdit: GameSession?
    @State private var gameToDelete: GameSession?       // #10 delete confirmation
    @State private var showDeleteGameAlert = false
    @State private var showCreateGroup = false
    @State private var showJoinGroup = false
    @State private var selectedGroup: PokerGroup?
    @State private var showSettings = false
    
    init(group: PokerGroup?, currencySymbol: String, groupId: String, onExit: (() -> Void)? = nil, onSeeAllGames: (() -> Void)? = nil, onOpenTable: (() -> Void)? = nil) {
        self.group = group
        self.currencySymbol = currencySymbol
        self.groupId = groupId
        self.onExit = onExit
        self.onSeeAllGames = onSeeAllGames
        self.onOpenTable = onOpenTable
        let gId = groupId
        _recentGames = Query(
            filter: #Predicate<GameSession> { $0.groupId == gId },
            sort: \GameSession.date,
            order: .reverse
        )
    }
    
    var activeGame: GameSession? {
        recentGames.first(where: { $0.status == .active })
    }
    
    /// Greeting based on time of day
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good Morning" }
        if hour < 18 { return "Good Afternoon" }
        return "Good Evening"
    }
    
    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header — matches GameSession style
                    HStack {
                        // Left: back button or spacer for balance
                        if let onExit = onExit {
                            Button {
                                onExit()
                            } label: {
                                Image(systemName: "chevron.left")
                                    .foregroundStyle(.white)
                                    .padding()
                                    .background(Color.black.opacity(0.3))
                                    .clipShape(Circle())
                            }
                        } else {
                            Color.clear.frame(width: 44, height: 44)
                        }
                        
                        Spacer()
                        
                        // Center: page title
                        VStack(spacing: 2) {
                            if let group = group {
                                Text(group.name)
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.accent)
                            }
                            Text(greeting)
                                .font(.headline)
                                .foregroundStyle(.white)
                        }
                        
                        Spacer()
                        
                        // Right: action buttons
                        HStack(spacing: 4) {
                            if group != nil {
                                Button {
                                    showSettings = true
                                } label: {
                                    Image(systemName: "gearshape")
                                        .foregroundStyle(.white)
                                        .padding()
                                }
                            }
                            Image(systemName: "bell")
                                .foregroundStyle(.white)
                                .padding()
                        }
                        .frame(width: 44)
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                    
                    if let group = group {
                        GroupCodeHeader(groupId: group.groupId)
                            .padding(.top, -8)
                    }
                    
                    // MARK: - Groups Section (only in local mode)
                    
                    if group == nil {
                        if userGroups.isEmpty {
                            GlowCard {
                                VStack(spacing: 16) {
                                    Image(systemName: "person.3.fill")
                                        .font(.system(size: 40))
                                        .foregroundStyle(AppTheme.accent)
                                    
                                    Text("Poker Groups")
                                        .font(.title3.bold())
                                        .foregroundStyle(.white)
                                    
                                    Text("Create or join a group to play\nwith friends and track stats together")
                                        .font(.subheadline)
                                        .foregroundStyle(.gray)
                                        .multilineTextAlignment(.center)
                                    
                                    HStack(spacing: 12) {
                                        Button {
                                            showCreateGroup = true
                                        } label: {
                                            HStack {
                                                Image(systemName: "plus.circle.fill")
                                                Text("Create")
                                            }
                                            .font(.headline)
                                            .foregroundStyle(.black)
                                            .padding(.vertical, 12)
                                            .padding(.horizontal, 20)
                                            .background(AppTheme.accent)
                                            .clipShape(Capsule())
                                        }
                                        
                                        Button {
                                            showJoinGroup = true
                                        } label: {
                                            HStack {
                                                Image(systemName: "person.badge.plus")
                                                Text("Join")
                                            }
                                            .font(.headline)
                                            .foregroundStyle(AppTheme.accent)
                                            .padding(.vertical, 12)
                                            .padding(.horizontal, 20)
                                            .background(
                                                Capsule()
                                                    .stroke(AppTheme.accent, lineWidth: 1.5)
                                            )
                                        }
                                    }
                                }
                                .padding(24)
                                .frame(maxWidth: .infinity)
                            }
                        } else {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("My Groups")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.white)
                                    Spacer()
                                    
                                    Menu {
                                        Button {
                                            showCreateGroup = true
                                        } label: {
                                            Label("Create Group", systemImage: "plus.circle")
                                        }
                                        Button {
                                            showJoinGroup = true
                                        } label: {
                                            Label("Join Group", systemImage: "person.badge.plus")
                                        }
                                    } label: {
                                        Image(systemName: "plus.circle")
                                            .foregroundStyle(AppTheme.accent)
                                            .font(.title3)
                                    }
                                }
                                
                                ForEach(userGroups) { group in
                                    GlowCard {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(group.name)
                                                    .foregroundStyle(.white)
                                                    .fontWeight(.bold)
                                                
                                                HStack(spacing: 8) {
                                                    HStack(spacing: 4) {
                                                        Image(systemName: "person.2.fill")
                                                            .font(.caption2)
                                                        Text("\(group.memberCount)")
                                                            .font(.caption)
                                                    }
                                                    .foregroundStyle(.gray)
                                                    
                                                    Text("\(group.currencySymbol)")
                                                        .font(.caption.bold())
                                                        .foregroundStyle(AppTheme.accent.opacity(0.7))
                                                    
                                                    Text(group.groupId)
                                                        .font(.caption.bold().monospaced())
                                                        .foregroundStyle(AppTheme.accent.opacity(0.5))
                                                }
                                            }
                                            
                                            Spacer()
                                            
                                            Image(systemName: "chevron.right")
                                                .foregroundStyle(AppTheme.accent.opacity(0.5))
                                        }
                                        .padding()
                                    }
                                    .onTapGesture {
                                        selectedGroup = group
                                    }
                                }
                            }
                        }
                    }
                    
                    // MARK: - Active Game / Start Game
                    
                    GlowCard {
                        VStack(spacing: 20) {
                            Text(activeGame != nil ? "Active Pot" : "Total Tracked Pot")
                                .foregroundStyle(AppTheme.textSecondary)
                                .font(.subheadline)
                            
                            Text("\(currencySymbol)\(activeGame?.totalPot ?? 0, specifier: "%.2f")")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            
                            if let game = activeGame {
                                AccentButton(title: "Take Me to the Table", icon: "suit.spade.fill") {
                                    openTable(game)
                                }
                            } else {
                                AccentButton(title: "Start New Game", icon: "plus") {
                                    showNewGameSheet = true
                                }
                            }
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if let game = activeGame {
                                openTable(game)
                            }
                        }
                    }
                    
                    // MARK: - Recent Games
                    
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Recent Games")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                            Spacer()
                            Button("See all") {
                                onSeeAllGames?()
                            }
                            .foregroundStyle(AppTheme.accent)
                        }
                        
                        // #9 Empty state
                        if recentGames.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "suit.spade.fill")
                                    .font(.system(size: 44))
                                    .foregroundStyle(AppTheme.accent.opacity(0.4))
                                Text("No Games Yet")
                                    .font(.title3.bold())
                                    .foregroundStyle(.white)
                                Text("Start your first session to\nsee results here.")
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.textSecondary)
                                    .multilineTextAlignment(.center)
                                AccentButton(title: "Start New Game", icon: "plus") {
                                    showNewGameSheet = true
                                }
                                .padding(.top, 4)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 32)
                            .background(AppTheme.cardBackground)
                            .cornerRadius(20)
                        }
                        
                        ForEach(recentGames.prefix(3)) { game in
                            GlowCard {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(game.date.formatted(date: .abbreviated, time: .shortened))
                                            .foregroundStyle(.white)
                                            .fontWeight(.medium)
                                        Text("\(game.playerCount) Players")
                                            .foregroundStyle(AppTheme.textSecondary)
                                            .font(.caption)
                                    }
                                    Spacer()
                                    HStack(spacing: 8) {
                                        Text("\(currencySymbol)\(game.totalPot, specifier: "%.0f")")
                                            .foregroundStyle(AppTheme.accent)
                                            .fontWeight(.bold)
                                            
                                        if game.status == .active {
                                            Text("LIVE")
                                                .font(.caption2.bold())
                                                .foregroundStyle(.green)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.green.opacity(0.2))
                                                .clipShape(Capsule())
                                        } else if game.status == .completed {
                                            Text("ENDED")
                                                .font(.caption2.bold())
                                                .foregroundStyle(.red)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.red.opacity(0.2))
                                                .clipShape(Capsule())
                                        }
                                    }
                                }
                                .padding()
                            }
                            .contextMenu {
                                Button {
                                    gameToEdit = game
                                } label: {
                                    Label("Edit Details", systemImage: "pencil")
                                }
                                
                                if game.status == .completed {
                                    Button {
                                        reopenGame(game)
                                    } label: {
                                        Label("Re-open Game", systemImage: "arrow.uturn.backward")
                                    }
                                }
                                
                                Button(role: .destructive) {
                                    gameToDelete = game
                                    showDeleteGameAlert = true
                                } label: {
                                    Label("Delete Game", systemImage: "trash")
                                }
                            }
                            .onTapGesture {
                                if game.status == .active {
                                    openTable(game)
                                } else {
                                    selectedGame = game
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 100)
            }
        }
        .sheet(isPresented: $showNewGameSheet) {
            NewGameSheet(groupId: groupId)
        }
        .sheet(item: $gameToEdit) { game in
            EditGameSheet(game: game)
        }
        .sheet(isPresented: $showCreateGroup) {
            CreateGroupView()
        }
        .sheet(isPresented: $showJoinGroup) {
            JoinGroupView()
        }
        .fullScreenCover(item: $selectedGame) { game in
            GameSessionView(session: game, modelContext: modelContext, currencySymbol: currencySymbol)
        }
        .fullScreenCover(item: $selectedGroup) { group in
            MainTabView(group: group) {
                selectedGroup = nil
            }
        }
        .sheet(isPresented: $showSettings) {
            if let group = group {
                GroupSettingsSheet(group: group)
            }
        }
        .alert("Delete Game?", isPresented: $showDeleteGameAlert) {
            Button("Cancel", role: .cancel) { gameToDelete = nil }
            Button("Delete", role: .destructive) {
                if let game = gameToDelete {
                    deleteGame(game)
                    gameToDelete = nil
                }
            }
        } message: {
            Text("This will permanently delete all session data. This cannot be undone.")
        }
        .onAppear {
            firebaseService.loadUserGroups()
            userGroups = firebaseService.userGroups
            
            // Auto-resume logic removed: user prefers to land on the group home page first.
        }
        .onReceive(firebaseService.$userGroups) { groups in
            userGroups = groups
        }
    }
    
    // MARK: - Actions
    private func deleteGame(_ game: GameSession) {
        withAnimation {
            modelContext.delete(game)
        }
    }
    
    private func reopenGame(_ game: GameSession) {
        withAnimation {
            game.status = .active
            game.endedAt = nil
        }
    }
    
    /// Opening a second copy of the game screen on top of the Game tab's
    /// copy broke sheet presentation, so jump to the Game tab instead.
    private func openTable(_ game: GameSession) {
        if let onOpenTable {
            onOpenTable()
        } else {
            selectedGame = game
        }
    }
}

#Preview {
    HomeView(group: nil, currencySymbol: "₪", groupId: "local")
}
