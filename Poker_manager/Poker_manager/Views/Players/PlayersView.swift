
import SwiftUI
import SwiftData

struct PlayersView: View {
    let groupId: String
    
    @Environment(\.modelContext) private var modelContext
    @Query private var players: [Player]
    @State private var showAddPlayer = false
    @State private var playerToEdit: Player?
    @State private var playerToDelete: Player?
    @State private var showDeleteConfirmation = false
    
    init(groupId: String) {
        self.groupId = groupId
        let gId = groupId
        _players = Query(
            filter: #Predicate<Player> { $0.groupId == gId },
            sort: \Player.name
        )
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // MARK: - Header
                    HStack {
                        Text("Players")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                        
                        Spacer()
                        
                        // 3-dots header menu
                        Menu {
                            Button {
                                showAddPlayer = true
                            } label: {
                                Label("Add Player", systemImage: "person.badge.plus")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.title3)
                                .foregroundStyle(.white)
                                .padding(12)
                                .background(AppTheme.cardBackground)
                                .clipShape(Circle())
                        }
                        
                        // Quick add button
                        Button {
                            showAddPlayer = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.title2)
                                .foregroundStyle(AppTheme.accent)
                                .padding(12)
                                .background(AppTheme.cardBackground)
                                .clipShape(Circle())
                        }
                    }
                    .padding()
                    .padding(.top, 40)
                    
                    // MARK: - Player List
                    if players.isEmpty {
                        VStack(spacing: 16) {
                            Spacer()
                            Image(systemName: "person.3.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(AppTheme.textSecondary.opacity(0.3))
                            Text("No Players Yet")
                                .font(.title3.bold())
                                .foregroundStyle(.white)
                            Text("Add players to start tracking\ngames and stats.")
                                .font(.subheadline)
                                .foregroundStyle(.gray)
                                .multilineTextAlignment(.center)
                            
                            AccentButton(title: "Add First Player", icon: "plus") {
                                showAddPlayer = true
                            }
                            .padding(.top, 8)
                            Spacer()
                            Spacer()
                        }
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(players) { player in
                                    NavigationLink(destination: PlayerDetailView(player: player)) {
                                        playerRow(player)
                                    }
                                    .contextMenu {
                                        Button {
                                            playerToEdit = player
                                        } label: {
                                            Label("Edit Name", systemImage: "pencil")
                                        }
                                        
                                        Button(role: .destructive) {
                                            playerToDelete = player
                                            showDeleteConfirmation = true
                                        } label: {
                                            Label("Delete Player", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 100)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showAddPlayer) {
            AddPlayerView(groupId: groupId)
        }
        .sheet(item: $playerToEdit) { player in
            EditPlayerSheet(player: player)
        }
        .alert("Delete Player", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let player = playerToDelete {
                    deletePlayer(player)
                }
            }
        } message: {
            if let player = playerToDelete {
                Text("Are you sure you want to delete \(player.name)? This action cannot be undone.")
            }
        }
    }
    
    // MARK: - Player Row
    
    private func playerRow(_ player: Player) -> some View {
        HStack(spacing: 14) {
            // Avatar
            Image(systemName: player.avatar)
                .font(.title2)
                .foregroundStyle(AppTheme.accent)
                .frame(width: 44, height: 44)
                .background(AppTheme.accent.opacity(0.12))
                .clipShape(Circle())
            
            // Name & detail
            VStack(alignment: .leading, spacing: 3) {
                Text(player.name)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                Text("Joined \(player.createdAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            
            Spacer()
            
            // Per-row 3-dots menu
            Menu {
                Button {
                    playerToEdit = player
                } label: {
                    Label("Edit Name", systemImage: "pencil")
                }
                
                Button(role: .destructive) {
                    playerToDelete = player
                    showDeleteConfirmation = true
                } label: {
                    Label("Delete Player", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.body)
                    .foregroundStyle(.gray)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
        }
        .padding(14)
        .background(AppTheme.cardBackground)
        .cornerRadius(14)
    }
    
    // MARK: - Actions
    
    private func deletePlayer(_ player: Player) {
        withAnimation {
            modelContext.delete(player)
            try? modelContext.save()
            playerToDelete = nil
        }
    }
}
