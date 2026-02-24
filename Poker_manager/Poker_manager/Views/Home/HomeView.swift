
import SwiftUI
import SwiftData

struct HomeView: View {
    let group: PokerGroup?
    let currencySymbol: String
    let groupId: String
    var onExit: (() -> Void)?
    
    @Environment(\.modelContext) private var modelContext
    @Query private var recentGames: [GameSession]
    @ObservedObject private var firebaseService = FirebaseService.shared
    
    @State private var showNewGameSheet = false
    @State private var selectedGame: GameSession?
    @State private var gameToEdit: GameSession?
    @State private var showCreateGroup = false
    @State private var showJoinGroup = false
    @State private var selectedGroup: PokerGroup?
    
    init(group: PokerGroup?, currencySymbol: String, groupId: String, onExit: (() -> Void)? = nil) {
        self.group = group
        self.currencySymbol = currencySymbol
        self.groupId = groupId
        self.onExit = onExit
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
            AppTheme.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        if let onExit = onExit {
                            Button {
                                onExit()
                            } label: {
                                Image(systemName: "arrow.left")
                                    .foregroundStyle(.white)
                                    .padding(12)
                                    .background(AppTheme.cardBackground)
                                    .clipShape(Circle())
                            }
                        }
                        
                        VStack(alignment: .leading) {
                            if let group = group {
                                Text(group.name)
                                    .font(.headline)
                                    .foregroundStyle(AppTheme.accent)
                            } else {
                                Text("Poker Manager")
                                    .font(.headline)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                            Text(greeting)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                        }
                        Spacer()
                        Image(systemName: "bell.badge")
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(AppTheme.cardBackground)
                            .clipShape(Circle())
                    }
                    .padding(.top, 60)
                    
                    // MARK: - Groups Section (only in local mode)
                    
                    if group == nil {
                        if firebaseService.userGroups.isEmpty {
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
                                
                                ForEach(firebaseService.userGroups) { group in
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
                                    selectedGame = game
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
                                selectedGame = game
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
                            Text("See all")
                                .foregroundStyle(AppTheme.textSecondary)
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
                                    deleteGame(game)
                                } label: {
                                    Label("Delete Game", systemImage: "trash")
                                }
                            }
                            .onTapGesture {
                                selectedGame = game
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 100)
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
                    GameSessionView(session: game, modelContext: modelContext)
                }
                .fullScreenCover(item: $selectedGroup) { group in
                    GroupDashboardView(group: group)
                }
            }
        }
        .onAppear {
            firebaseService.loadUserGroups()
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
}

#Preview {
    HomeView(group: nil, currencySymbol: "₪", groupId: "local")
}
