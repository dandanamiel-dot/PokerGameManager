
import SwiftUI
import SwiftData

struct GroupDashboardView: View {
    let group: PokerGroup
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var firebaseService = FirebaseService.shared
    @Query(sort: \GameSession.date, order: .reverse) private var allGames: [GameSession]
    
    @State private var showNewGameSheet = false
    @State private var showSettings = false
    @State private var selectedGame: GameSession?
    @State private var codeCopied = false
    
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Group ID Card
                        groupIdCard
                        
                        // Members Section
                        membersSection
                        
                        // Game Actions
                        if firebaseService.activeGroup?.groupId == group.groupId {
                            AccentButton(title: "Start New Game", icon: "plus") {
                                showNewGameSheet = true
                            }
                        }
                        
                        // Recent Games
                        recentGamesSection
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
            }
        }
        .sheet(isPresented: $showNewGameSheet) {
            NewGameSheet()
        }
        .sheet(isPresented: $showSettings) {
            GroupSettingsSheet(group: group)
        }
        .fullScreenCover(item: $selectedGame) { game in
            GameSessionView(session: game, modelContext: modelContext)
        }
        .onAppear {
            firebaseService.listenToGroup(groupId: group.groupId)
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundStyle(.white)
                    .padding()
                    .background(Color.black.opacity(0.3))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                Text(currentGroup.name)
                    .font(.headline)
                    .foregroundStyle(.white)
                
                Text("\(currentGroup.memberCount) members")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            
            Spacer()
            
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .foregroundStyle(.white)
                    .padding()
                    .background(Color.black.opacity(0.3))
                    .clipShape(Circle())
            }
        }
        .padding()
    }
    
    // MARK: - Group ID Card
    
    private var groupIdCard: some View {
        GlowCard {
            VStack(spacing: 12) {
                Text("Group Code")
                    .font(.caption)
                    .foregroundStyle(.gray)
                
                Text(currentGroup.groupId)
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundStyle(AppTheme.accent)
                    .kerning(3)
                
                HStack(spacing: 12) {
                    Button {
                        UIPasteboard.general.string = currentGroup.groupId
                        withAnimation { codeCopied = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation { codeCopied = false }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: codeCopied ? "checkmark" : "doc.on.doc")
                            Text(codeCopied ? "Copied!" : "Copy")
                        }
                        .font(.caption.bold())
                        .foregroundStyle(AppTheme.accent)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(AppTheme.accent.opacity(0.15))
                        .clipShape(Capsule())
                    }
                    
                    ShareLink(
                        item: "Join my poker group \"\(currentGroup.name)\" using code: \(currentGroup.groupId)",
                        subject: Text("Poker Group Invite"),
                        message: Text("Join my poker group!")
                    ) {
                        HStack(spacing: 4) {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share")
                        }
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Members
    
    private var membersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Members")
                .font(.title3.bold())
                .foregroundStyle(.white)
            
            let memberNames = Array(currentGroup.memberNames.values).sorted()
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                ForEach(memberNames, id: \.self) { name in
                    HStack(spacing: 8) {
                        Image(systemName: "person.crop.circle.fill")
                            .foregroundStyle(AppTheme.accent.opacity(0.7))
                        Text(name)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(AppTheme.cardBackground)
                    .cornerRadius(12)
                }
            }
        }
    }
    
    // MARK: - Recent Games
    
    private var recentGamesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Games")
                .font(.title3.bold())
                .foregroundStyle(.white)
            
            if allGames.isEmpty {
                VStack(spacing: 8) {
                    Text("No games yet")
                        .foregroundStyle(.gray)
                    Text("Start a new game to get going!")
                        .font(.caption)
                        .foregroundStyle(.gray.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                ForEach(allGames.prefix(5)) { game in
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
                                Text("\(currentGroup.currencySymbol)\(game.totalPot, specifier: "%.0f")")
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
                                }
                            }
                        }
                        .padding()
                    }
                    .onTapGesture {
                        selectedGame = game
                    }
                }
            }
        }
    }
    
    // MARK: - Helper
    
    private var currentGroup: PokerGroup {
        firebaseService.activeGroup ?? group
    }
}
