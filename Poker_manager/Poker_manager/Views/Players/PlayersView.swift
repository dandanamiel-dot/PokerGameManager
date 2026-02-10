
import SwiftUI
import SwiftData

struct PlayersView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Player.name) private var players: [Player]
    @State private var showAddPlayer = false
    @State private var playerToEdit: Player?
    @State private var playerToDelete: Player?
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Players")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    Spacer()
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
                
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(players) { player in
                            PlayerRow(
                                name: player.name,
                                detail: "Joined \(player.createdAt.formatted(date: .abbreviated, time: .omitted))",
                                amount: nil, 
                                isPositive: true
                            )
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    playerToDelete = player
                                    showDeleteConfirmation = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                
                                Button {
                                    playerToEdit = player
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(AppTheme.accent)
                            }
                        }
                    }
                    .padding()
                    .padding(.bottom, 100)
                }
            }
        }
        .sheet(isPresented: $showAddPlayer) {
            AddPlayerView()
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
    
    private func deletePlayer(_ player: Player) {
        modelContext.delete(player)
        try? modelContext.save()
        playerToDelete = nil
    }
}
